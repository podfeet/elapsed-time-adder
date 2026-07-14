//
//  ContentView.swift
//  ElapsedTimeAdder
//
//  Created by Allison on 4/27/26.
//

import SwiftUI
#if os(macOS)
import AppKit
#endif

// Pure decision logic for ContentView.isWide, pulled out to a standalone function
// so it's unit-testable directly with UserInterfaceSizeClass values — no simulator
// device rotation required. Automating real rotation via XCUIDevice.shared.orientation
// in a UI test proved unreliable (it produced a false failure even when the app was
// visually confirmed correct — see LayoutTests.swift and AccessibilityTests.swift's
// git history), and it's testing the same boolean decision either way. Requiring BOTH
// size classes to be .regular is what matters: a Plus/Max iPhone in landscape reports
// horizontal .regular (like an iPad) but vertical .compact, so checking horizontal
// alone would wrongly pick the wide/sidebar layout there.
func isWideLayout(horizontalSizeClass: UserInterfaceSizeClass?, verticalSizeClass: UserInterfaceSizeClass?) -> Bool {
    horizontalSizeClass == .regular && verticalSizeClass == .regular
}

struct ContentView: View {
    @State private var rows: [TimeRow] = [TimeRow(), TimeRow()]
    @State private var showSpreadsheetNote = false
    @State private var showAboutSheet = false
    @State private var isEditing = false
    // Wide-layout (macOS/iPad) row reorder — driven by a plain DragGesture on each
    // row's drag handle rather than SwiftUI's onDrag/onDrop, after repeated
    // regressions tuning the latter (system drag-preview ghost, invisible rows when
    // performDrop didn't fire, timing races clearing that state). A DragGesture is
    // fully self-contained: we track the offset and decide swaps ourselves, with no
    // system drag session and no ambiguity about when a "drop" occurred.
    @State private var draggedRow: TimeRow?
    @State private var dragOffset: CGFloat = 0
    // The dragged row's array index at the moment the drag began — see
    // handleRowDragChanged for why the target slot is derived from this plus the
    // raw translation, rather than adjusting dragOffset itself after each swap.
    @State private var draggingStartIndex: Int?
    // Measured once from an actual row (inline GeometryReader in the ForEach below)
    // rather than guessed — hardcoded row-height constants have been wrong every
    // time they were tried elsewhere in this file. Rows are uniform height, so any
    // one row's measurement is valid for all of them.
    @State private var rowHeight: CGFloat = 0
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
#if os(macOS)
    // Tracks whether the sidebar is currently hidden because OUR narrow-width logic
    // closed it (vs. the user manually clicking the sidebar toggle button). Only an
    // auto-collapse gets auto-reopened later — a manual hide is respected even if the
    // window is widened back out.
    @State private var isSidebarAutoCollapsed = false
    // Disarmed by any manual toggle (in either direction) so we stop fighting the
    // user; re-armed once the title field is comfortably wide again, ready for the
    // next narrow→wide cycle.
    @State private var autoCollapseArmed = true
    // Set right before WE change columnVisibility, so the onChange below can tell our
    // own writes apart from the user clicking the native sidebar toggle button.
    @State private var isProgrammaticVisibilityChange = false
    // Continuously-updated window width (measured via a GeometryReader on the whole
    // NavigationSplitView) and a snapshot of it taken at the moment we auto-collapse.
    // Reopening MUST key off window width, not title-field width: collapsing the
    // sidebar immediately widens the detail column, which immediately widens the
    // title field — if reopening also watched title width, that swing would reopen
    // the sidebar right away, which narrows the title field again, which collapses
    // it again... an infinite loop (this is what caused the SIGTERM hang). Window
    // width is unaffected by whether the sidebar is shown, so it can't self-trigger.
    @State private var lastKnownWindowWidth: CGFloat = 0
    @State private var windowWidthAtCollapse: CGFloat?
#endif
#if os(iOS)
    // Drives the iPhone List's native reorder/delete controls. Custom onDrag/onDrop
    // (used on the wide/macOS ScrollView layout) doesn't work for same-List reordering
    // on iOS: it competes with List's own vertical scroll-pan gesture, so the drag
    // preview lifts but the drop never registers. .onMove is the only reliable
    // mechanism for reordering rows inside a List.
    @State private var editMode: EditMode = .inactive
#endif
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.colorScheme) private var colorScheme

    // Wide (sidebar) layout = real iPad full-screen or Mac only. macOS always uses
    // the wide layout; iOS defers to isWideLayout (see its own doc comment for why
    // that's a standalone function rather than inlined here).
    private var isWide: Bool {
#if os(macOS)
        true
#else
        isWideLayout(horizontalSizeClass: horizontalSizeClass, verticalSizeClass: verticalSizeClass)
#endif
    }
    private var buttonOpacity: Double { colorScheme == .dark ? 0.25 : 0.12 }

    private var total: TimeResult {
        calcTotal(rows: rows)
    }

    private var hasAnyError: Bool {
        rows.contains {
            !isValidTimeInput($0.hours) ||
            !isValidTimeInput($0.minutes) ||
            !isValidTimeInput($0.seconds)
        }
    }

    private func deleteRows(at offsets: IndexSet) {
        rows.remove(atOffsets: offsets)
        if rows.count < 2 { rows.append(contentsOf: (rows.count..<2).map { _ in TimeRow() }) }
    }

    private func moveRows(from source: IndexSet, to destination: Int) {
        rows.move(fromOffsets: source, toOffset: destination)
    }

    // Wide-layout drag-to-reorder: called continuously as the drag handle moves.
    // Swap decisions are made relative to the row's CURRENT slot (not recomputed
    // from scratch against the drag's start position each time), using a 60% —
    // not 50% — threshold in either direction. That's deliberate hysteresis: a
    // plain symmetric midpoint has no gap between the forward- and
    // backward-triggering points, so ordinary cursor jitter sitting right at that
    // exact midpoint would flip the rounded target back and forth, firing
    // rows.move repeatedly (the "twitchy" flutter). Requiring 60% past center to
    // swap means that immediately after a swap, the row sits ~40% into its new
    // slot — comfortably inside the dead zone — so small jitter can't immediately
    // re-trigger a reverse swap.
    private func handleRowDragChanged(row: TimeRow, translationHeight: CGFloat) {
        if draggedRow?.id != row.id {
            draggedRow = row
            draggingStartIndex = rows.firstIndex(where: { $0.id == row.id })
        }
        dragOffset = translationHeight

        guard rowHeight > 0,
              let startIndex = draggingStartIndex,
              let currentIndex = rows.firstIndex(where: { $0.id == row.id })
        else { return }

        let offsetFromCurrentSlot = dragOffset - CGFloat(currentIndex - startIndex) * rowHeight
        let threshold = rowHeight * 0.6

        // Deliberately NOT wrapped in withAnimation: visualDragOffset's math assumes
        // the array reflow (siblings moving into their new slots) happens instantly,
        // so it can compensate synchronously and keep the dragged row's total
        // apparent position exactly equal to dragOffset (raw cursor tracking) at
        // every moment. Animating this reflow spreads it over ~0.3s while the offset
        // compensation snaps immediately — a mismatch that made dragging feel
        // jerky. Only the final settle in handleRowDragEnded is animated, since
        // there's no continuous tracking to stay in sync with by then.
        if offsetFromCurrentSlot > threshold, currentIndex < rows.count - 1 {
            rows.move(fromOffsets: IndexSet([currentIndex]), toOffset: currentIndex + 2)
        } else if offsetFromCurrentSlot < -threshold, currentIndex > 0 {
            rows.move(fromOffsets: IndexSet([currentIndex]), toOffset: currentIndex - 1)
        }
    }

    private func handleRowDragEnded() {
        draggedRow = nil
        draggingStartIndex = nil
        withAnimation {
            dragOffset = 0
        }
    }

    // The visual .offset(y:) applied to the row being dragged. This is NOT just
    // dragOffset directly: once a swap happens, the row's actual array position
    // already moves (ForEach's reflow, since rows.move changed its index) —
    // applying the full raw dragOffset on TOP of that double-counts the movement,
    // since the reflow already accounts for whole-row-height steps. This subtracts
    // out however much the index has already shifted since drag start, leaving only
    // the sub-row-height remainder needed for smooth 1:1 cursor tracking within the
    // current slot. Same offsetFromCurrentSlot quantity as in handleRowDragChanged.
    private func visualDragOffset(for row: TimeRow) -> CGFloat {
        guard draggedRow?.id == row.id, rowHeight > 0,
              let startIndex = draggingStartIndex,
              let currentIndex = rows.firstIndex(where: { $0.id == row.id })
        else { return 0 }
        return dragOffset - CGFloat(currentIndex - startIndex) * rowHeight
    }

#if os(macOS)
    private func setColumnVisibility(_ newValue: NavigationSplitViewVisibility) {
        isProgrammaticVisibilityChange = true
        columnVisibility = newValue
    }

    // Any columnVisibility change we didn't just make ourselves came from the user
    // clicking the native sidebar toggle button. Treat that as an explicit override:
    // stop auto-managing until the title field is comfortably wide again.
    private func handleManualVisibilityChange() {
        if isProgrammaticVisibilityChange {
            isProgrammaticVisibilityChange = false
        } else {
            isSidebarAutoCollapsed = false
            autoCollapseArmed = false
            windowWidthAtCollapse = nil
        }
    }

    // Collapse decision only — direct signal from TimeRowView: the title field's
    // actual rendered width. It's floored at TimeRowView.titleFieldMinWidth via
    // .frame(minWidth:), so once it's reporting a value at (or pinned to) that
    // floor, it's under real compression pressure. This never oscillates on its
    // own: collapsing is a one-way transition guarded by `columnVisibility !=
    // .detailOnly`, and re-arming only happens once the field is comfortably wide
    // WITH the sidebar still visible (i.e. before any collapse), not as a result
    // of collapsing.
    private func handleTitleWidthChange(_ titleWidth: CGFloat) {
        // +2pt tolerance for sub-pixel rounding during live resize.
        let isNarrow = titleWidth <= TimeRowView.titleFieldMinWidth + 2
        if isNarrow {
            guard autoCollapseArmed, columnVisibility != .detailOnly else { return }
            setColumnVisibility(.detailOnly)
            isSidebarAutoCollapsed = true
            windowWidthAtCollapse = lastKnownWindowWidth
        } else if columnVisibility == .all {
            autoCollapseArmed = true
        }
    }

    // Reopen decision only — keyed off total window width, which collapsing the
    // sidebar does NOT change (only how that width is split between columns
    // changes). Reopens once the window is a bit wider than it was at the moment
    // of collapse — self-calibrating, no guessed pixel threshold needed — and only
    // for a collapse WE caused (isSidebarAutoCollapsed).
    private func handleWindowWidthChange(_ windowWidth: CGFloat) {
        lastKnownWindowWidth = windowWidth
        guard isSidebarAutoCollapsed, columnVisibility == .detailOnly,
              let widthAtCollapse = windowWidthAtCollapse else { return }
        if windowWidth > widthAtCollapse + 20 {
            setColumnVisibility(.all)
            isSidebarAutoCollapsed = false
            windowWidthAtCollapse = nil
        }
    }
#endif

    // nil on iPad — this auto-collapse behavior is scoped to macOS only, per what
    // was asked. TimeRowView's TitleWidthReporter modifier is a no-op when nil, so
    // no GeometryReader/measurement overhead is added on iPad or iPhone.
    private var titleWidthHandler: ((CGFloat) -> Void)? {
#if os(macOS)
        handleTitleWidthChange
#else
        nil
#endif
    }

    // VoiceOver-only path: dragging isn't accessible to VoiceOver, so each row also
    // exposes "Move up"/"Move down" custom accessibility actions as an equivalent way
    // to reorder rows via the rotor, matching how Apple's own apps (Mail, Reminders)
    // pair a drag handle with rotor-based reordering actions.
    private func moveRow(_ row: TimeRow, by offset: Int) {
        guard let index = rows.firstIndex(where: { $0.id == row.id }) else { return }
        let destination = index + offset
        guard rows.indices.contains(destination) else { return }
        rows.move(fromOffsets: IndexSet([index]), toOffset: offset > 0 ? destination + 1 : destination)
    }

    var body: some View {
        if isWide {
            // MARK: Wide layout — NavigationSplitView controls the columns so
            // WindowGroup doesn't insert its own blank primary column on iPad.
            // columnVisibility binding gives macOS its native sidebar toggle button.
            NavigationSplitView(columnVisibility: $columnVisibility) {
#if os(iOS)
                // iPad: About & Feedback used to be pinned to the bottom via a fixed
                // (non-scrolling) VStack sibling below the ScrollView. That broke as soon
                // as the keyboard appeared for a field in the detail column: the sidebar
                // still gets keyboard-avoidance applied to it even though nothing in it is
                // focused, which squeezes the fixed content and the ScrollView into
                // whatever room is left. Ignoring keyboard safe area on the sidebar only
                // fixed the layout math, not the split-view column's actual clipped frame,
                // so behavior still diverged by orientation (overlap in landscape, fully
                // clipped off-screen in portrait). Putting sidebarAboutContent INSIDE the
                // ScrollView (with a GeometryReader-driven minHeight + Spacer so it still
                // sits at the bottom when there's spare room) sidesteps all of that: the
                // whole sidebar is just scrollable content, so a shrinking keyboard makes
                // it scroll rather than overlap or vanish.
                GeometryReader { geo in
                    ScrollView {
                        VStack(spacing: 16) {
                            appTitle
                            usageHint
                            sidebarExportButtons
                            spreadsheetButton
                            Spacer(minLength: 20)
                            sidebarAboutContent
                        }
                        .padding()
                        .frame(minHeight: geo.size.height)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .toolbar(.hidden, for: .navigationBar)
                .navigationSplitViewColumnWidth(min: 320, ideal: 640, max: 640)
                .background(colorScheme == .dark ? Color.clear : Color.secondary.opacity(0.12))
                .ignoresSafeArea(edges: .leading)
#else
                // macOS: simple ScrollView, About & Feedback at the bottom of the scroll
                // content. Pinning it to the window bottom does NOT work inside macOS
                // NavigationSplitView — both the iPad VStack wrapper (spinning beachball)
                // and safeAreaInset (content overflows top & bottom of the window) fail.
                // Leave it scrolling; macOS sidebars don't bottom-pin like iPad.
                ScrollView {
                    VStack(spacing: 16) {
                        appTitle
                        usageHint
                        sidebarExportButtons
                        spreadsheetButton
                        sidebarAboutContent
                            .padding(.top, 48)
                    }
                    .padding()
                }
                .navigationSplitViewColumnWidth(min: 220, ideal: 300, max: 380)
                .background(Color.secondary.opacity(0.12))
                .ignoresSafeArea(edges: .leading)
#endif
            } detail: {
                ScrollView {
                    // Named so the row-reorder DragGesture below can measure translation
                    // against a frame that doesn't move — see the gesture's comment for why.
                    VStack(spacing: 16) {
                        columnHeaders
                            .padding(.horizontal, 10)
                        ForEach(rows) { row in
                            HStack(spacing: 8) {
                                if isEditing {
                                    Button {
                                        if let index = rows.firstIndex(where: { $0.id == row.id }) {
                                            deleteRows(at: IndexSet([index]))
                                        }
                                    } label: {
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundStyle(.red)
                                            .font(.title2)
                                    }
                                    .buttonStyle(.plain)
                                    .transition(.move(edge: .leading).combined(with: .opacity))
                                }
                                TimeRowView(row: row,
                                            isLast: row.id == rows.last?.id,
                                            onAddRow: { rows.append(TimeRow()) },
                                            onTitleWidthChange: titleWidthHandler)
                                    .frame(maxWidth: .infinity)
                                if isEditing {
                                    // Drag handle only — the gesture is scoped to this icon so
                                    // dragging can't interfere with the row's text fields/picker.
                                    Image(systemName: "line.3.horizontal")
                                        .foregroundStyle(.secondary)
                                        .font(.title3)
                                        .padding(.trailing, 4)
                                        .contentShape(Rectangle())
                                        .gesture(
                                            // Named space (see the VStack above), NOT .local: .local
                                            // measures translation relative to this icon's OWN frame,
                                            // which relocates the instant a swap fires (its row moves
                                            // to a new position) — so mid-gesture, the reference frame
                                            // itself would jump, corrupting the reported translation
                                            // with a spurious jolt on every swap. That's what caused
                                            // the frantic up/down jumping. A named space anchored to
                                            // the outer VStack (which doesn't move) keeps translation a
                                            // pure function of actual cursor movement throughout.
                                            DragGesture(minimumDistance: 2, coordinateSpace: .named("rowReorderSpace"))
                                                .onChanged { value in
                                                    handleRowDragChanged(row: row,
                                                                         translationHeight: value.translation.height)
                                                }
                                                .onEnded { _ in handleRowDragEnded() }
                                        )
                                        .transition(.move(edge: .trailing).combined(with: .opacity))
                                }
                            }
                            // Rows are uniform height, so measuring any single one is enough —
                            // reported once on appear since it never changes afterward.
                            .background(
                                GeometryReader { geo in
                                    Color.clear.onAppear { rowHeight = geo.size.height }
                                }
                            )
                            // Only the row actually being dragged follows the gesture directly
                            // (no animation — 1:1 tracking with the finger/cursor); its siblings
                            // reflow instantly too, via the (deliberately unanimated) rows.move in
                            // handleRowDragChanged. zIndex keeps the dragged row drawn above its
                            // neighbors while it's between slots. See visualDragOffset for why
                            // this isn't just the raw dragOffset.
                            .offset(y: visualDragOffset(for: row))
                            .zIndex(draggedRow?.id == row.id ? 1 : 0)
                        }
                        totalSummarySection
                        HStack(spacing: 8) {
                            addRowButton
                            editRowsButton
                        }
                        .frame(maxWidth: 360)
                        .frame(maxWidth: .infinity, alignment: .center)
                        resetButton
                            .padding(.top, 8)
                    }
                    .padding()
                    .frame(maxWidth: 560)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .coordinateSpace(.named("rowReorderSpace"))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
#if os(iOS)
                .toolbar(.hidden, for: .navigationBar)
#else
                // Empty title suppresses the "Elapsed Time Adder" window title that macOS
                // would otherwise show in the toolbar. The sidebar toggle button is kept
                // by NOT hiding the windowToolbar (hiding it removes the toggle button).
                .navigationTitle("")
#endif
            }
            .navigationSplitViewStyle(.balanced)
            .onAppear {
                if rows.count < 5 {
                    rows.append(contentsOf: (rows.count..<5).map { _ in TimeRow() })
                }
            }
#if os(macOS)
            .onChange(of: columnVisibility) { _, _ in
                handleManualVisibilityChange()
            }
            // Whole-window width, for the reopen decision only (see
            // handleWindowWidthChange). .background(GeometryReader) doesn't affect
            // layout — it's given the same size as the view it's attached to.
            .background(
                GeometryReader { geo in
                    Color.clear
                        .onAppear { handleWindowWidthChange(geo.size.width) }
                        .onChange(of: geo.size.width) { _, newWidth in
                            handleWindowWidthChange(newWidth)
                        }
                }
            )
#endif

        } else {
            // MARK: Narrow layout — single column (iPhone)
            // List (UITableView) avoids the multi-tap-required-to-focus bug in ScrollView.
            NavigationStack {
                List {
                    appTitle
                        .plainRow()
                    usageHint
                        .plainRow()
                    columnHeaders
                        .padding(.horizontal, 10)
                        .plainRow(top: 4, bottom: 0)
                    ForEach(rows) { row in
                        TimeRowView(row: row,
                                    isLast: row.id == rows.last?.id,
                                    onAddRow: { rows.append(TimeRow()) },
                                    isEditMode: isEditing)
                            .plainRow(top: 4, bottom: 4)
                            .accessibilityAction(named: "Move up") { moveRow(row, by: -1) }
                            .accessibilityAction(named: "Move down") { moveRow(row, by: 1) }
                    }
                    .onDelete(perform: deleteRows)
                    .onMove(perform: moveRows)
                    totalSummarySection
                        .plainRow()
                    HStack(spacing: 8) {
                        addRowButton
                        editRowsButton
                    }
                    .plainRow()
                    exportButtons
                        .plainRow(top: 0)
                    resetButton
                        .plainRow(top: 12)
                    spreadsheetButton
                        .plainRow()
                    podfeetBranding
                        .plainRow(bottom: 8)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .navigationTitle("Elapsed Time Adder")
#if os(iOS)
                .environment(\.editMode, $editMode)
                .toolbar(.hidden, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .keyboard) {
                        Button {
                            UIApplication.shared.sendAction(
                                #selector(UIResponder.resignFirstResponder),
                                to: nil, from: nil, for: nil
                            )
                        } label: {
                            Image(systemName: "keyboard.chevron.compact.down")
                        }
                    }
                }
#endif
            }
        }
    }

    // "Add Row" with a + icon (tester asked for a clearer add affordance). Half-width
    // pill designed to sit in an HStack beside editRowsButton.
    private var addRowButton: some View {
        Button {
            rows.append(TimeRow())
        } label: {
            Label("Add Row", systemImage: "plus")
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(buttonOpacity), in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("addRowButton")
    }

    // Edit Rows toggles row delete/reorder. Pencil icon (→ checkmark "Done") groups it
    // with Add Row as a "row action"; the export buttons use the share-arrow icon instead.
    private var editRowsButton: some View {
        Button {
            withAnimation {
                isEditing.toggle()
#if os(iOS)
                editMode = isEditing ? .active : .inactive
#endif
            }
        } label: {
            Label(isEditing ? "Done" : "Edit Rows",
                  systemImage: isEditing ? "checkmark.circle.fill" : "pencil")
                .foregroundStyle(isEditing ? .white : .primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    isEditing ? Color.blue : Color.blue.opacity(buttonOpacity),
                    in: RoundedRectangle(cornerRadius: 8)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isEditing ? "Done editing rows" : "Edit rows")
        .accessibilityIdentifier("editRowsButton")
    }

    // MARK: - Subviews

    // App title with the app icon to its left. The icon is decorative (the title text
    // conveys the name), and the title may shrink slightly so icon+title fit on narrow
    // iPhones. Used at the top of every layout (iPhone List, iPad/macOS sidebar).
    private var appTitle: some View {
        HStack(spacing: 10) {
            Image("AppIconImage")
                .resizable()
                .scaledToFit()
                .frame(width: 36, height: 36)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .accessibilityHidden(true)
            Text("Elapsed Time Adder")
                .font(.largeTitle.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private var usageHint: some View {
        Text("Enter a time in each row and choose Add (+) or\nSubtract (−). The total updates as you type.")
            .font(.callout)
            .foregroundStyle(.primary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: 480)                      // cap the text width
            .frame(maxWidth: .infinity, alignment: .center)  // center that block full-width
            .accessibilityIdentifier("usageHint")
    }

    private var spreadsheetButton: some View {
        VStack(spacing: 8) {
            Button {
                withAnimation { showSpreadsheetNote.toggle() }
            } label: {
                Label(showSpreadsheetNote ? "Hide" : "Why not use a spreadsheet?",
                      systemImage: "tablecells")
                    .foregroundStyle(.primary)
                    .font(.body)
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .center)
            .accessibilityLabel(showSpreadsheetNote ? "Hide spreadsheet note" : "Why not use a spreadsheet?")
            .accessibilityIdentifier("spreadsheetButton")

            if showSpreadsheetNote {
                Text("Why not just use Excel, Numbers, or Google Sheets? Because spreadsheets assume time is time-of-day. Because of that, they can't calculate elapsed time. Try adding 22:00 + 5:00 in a spreadsheet, and you'll get 3:00 AM, not 27:00.")
                    .font(.callout)
                    .foregroundStyle(.primary)
                    .padding()
                    .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                    .transition(.opacity)
                    .accessibilityIdentifier("spreadsheetNote")
            }
        }
    }

    private var exportButtons: some View {
        HStack(spacing: 8) {
            CopyButton(getText: { csvString(rows: rows, total: total) }, label: "Copy CSV")
                .frame(maxWidth: .infinity)
            CopyButton(getText: { hhmmssString(rows: rows, total: total) }, label: "Copy HH:MM:SS")
                .frame(maxWidth: .infinity)
        }
    }

    // Sidebar variant: stacked vertically, both buttons sized to the widest one, centered
    private var sidebarExportButtons: some View {
        VStack(spacing: 16) {
            CopyButton(getText: { csvString(rows: rows, total: total) }, label: "Copy CSV")
                .frame(maxWidth: .infinity)
            CopyButton(getText: { hhmmssString(rows: rows, total: total) }, label: "Copy HH:MM:SS")
                .frame(maxWidth: .infinity)
        }
        .frame(width: 320)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private var totalSummarySection: some View {
        Text(totalSummary)
            .font(.title2.bold())
            .foregroundStyle(hasAnyError ? .red : .primary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 8)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Total: \(totalSummary)")
    }


    private var columnHeaders: some View {
        HStack(spacing: 8) {
            Color.clear
                .frame(maxWidth: .infinity, maxHeight: 1)
                .accessibilityHidden(true)
            Text("Hrs")
                .frame(width: 55, alignment: .center)
                .accessibilityLabel("Hours")
            Text("Min")
                .frame(width: 55, alignment: .center)
                .accessibilityLabel("Minutes")
            Text("Sec")
                .frame(width: 55, alignment: .center)
                .accessibilityLabel("Seconds")
            Color.clear
                .frame(width: 64, height: 1)
                .accessibilityHidden(true)
        }
        .font(.callout.bold())
        .foregroundStyle(.primary)
        .accessibilityHidden(true)
    }

    private var resetButton: some View {
        Button {
            rows = (0..<(isWide ? 5 : 2)).map { _ in TimeRow() }
            isEditing = false
#if os(iOS)
            editMode = .inactive
#endif
        } label: {
            Text("Reset")
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.red.opacity(buttonOpacity), in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .frame(maxWidth: isWide ? 320 : .infinity)
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.bottom, 8)
        .accessibilityLabel("Reset all entries")
        .accessibilityHint("Clears all rows and returns to two empty rows")
        .accessibilityIdentifier("resetButton")
    }

    private var podfeetBranding: some View {
        Button { showAboutSheet = true } label: {
            HStack(spacing: 8) {
                Image("PodfeetLogo")
                    .resizable()
                    .scaledToFit()
#if os(macOS)
                    .frame(height: 44)
#else
                    .frame(height: 28)
#endif
                Text("A Podfeet App · About & Feedback")
                    .font(.body)
                    .foregroundStyle(.primary)
                Image(systemName: "chevron.forward")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)   // decorative; button hint conveys the action
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 4)
            .padding(.bottom, 8)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("A Podfeet App · About & Feedback")
        .accessibilityHint("Opens information, website, and feedback links")
        .sheet(isPresented: $showAboutSheet) {
            AboutSheet()
        }
    }

    private var sidebarAboutContent: some View {
        VStack(spacing: 12) {
            Image("PodfeetLogo")
                .resizable()
                .scaledToFit()
                .frame(height: 36)
                .accessibilityHidden(true)   // decorative; text below conveys the same info

            Text("Elapsed Time Adder")
                .font(.headline)

            Text("A Podfeet App")
                .font(.subheadline)
                .foregroundStyle(.primary)   // .secondary fails WCAG AA contrast

            VStack(spacing: 8) {
                Link(destination: URL(string: "https://timeadder.podfeet.com")!) {
                    Label("Visit timeadder.podfeet.com", systemImage: "safari")
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.blue.opacity(buttonOpacity), in: RoundedRectangle(cornerRadius: 10))
                }
                Link(destination: URL(string: "mailto:allison@podfeet.com?subject=Elapsed%20Time%20Adder%20Feedback")!) {
                    Label("Send feedback or ask a question", systemImage: "envelope")
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.blue.opacity(buttonOpacity), in: RoundedRectangle(cornerRadius: 10))
                }
                Link(destination: URL(string: "https://github.com/podfeet/elapsed-time-adder/issues/new")!) {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "ladybug")
                            .padding(.top, 2)
                            .accessibilityHidden(true)   // decorative; link text describes it
                        Text("Of the nerd persuasion? Submit an issue on GitHub")
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.blue.opacity(buttonOpacity), in: RoundedRectangle(cornerRadius: 10))
                }
            }
            // 48pt suits the wide iPad sidebar (640pt); the macOS sidebar is only
            // 220–380pt, where 48pt can compute a negative content width during
            // transient layout ("Invalid frame dimension" warning) — use 16pt there.
#if os(macOS)
            .padding(.horizontal, 16)
#else
            .padding(.horizontal, 48)
#endif
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Helpers

    private var totalSummary: String {
        if hasAnyError { return "—" }
        let isNeg = total.hours < 0 || total.minutes < 0 || total.seconds < 0
        let h = abs(total.hours), m = abs(total.minutes), s = abs(total.seconds)
        var parts: [String] = []
        if h != 0 { parts.append("\(formatTotalValue(h)) \(h == 1 ? "hr" : "hrs")") }
        if m != 0 { parts.append("\(formatTotalValue(m)) min") }
        if s != 0 || parts.isEmpty { parts.append("\(formatTotalValue(s)) sec") }
        let result = parts.joined(separator: " ")
        return isNeg ? "− \(result)" : result
    }

    private func formatTotalValue(_ value: Double) -> String {
        if value == floor(value) { return String(Int(value)) }
        return String(format: "%.2f", value)
    }
}

// MARK: - CopyButton

/// Copies text to the clipboard and briefly shows "Copied!" feedback.
private struct CopyButton: View {
    let getText: () -> String
    let label: String
    @State private var copied = false
    @Environment(\.colorScheme) private var colorScheme
    private var buttonOpacity: Double { colorScheme == .dark ? 0.25 : 0.12 }

    var body: some View {
        Button {
            let text = getText()
#if os(macOS)
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(text, forType: .string)
#else
            UIPasteboard.general.string = text
#endif
            copied = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { copied = false }
        } label: {
            Label(copied ? "Copied!" : label, systemImage: copied ? "checkmark" : "doc.on.doc")
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(buttonOpacity), in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: copied)
    }
}

// MARK: - About sheet

private struct AboutSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    private var buttonOpacity: Double { colorScheme == .dark ? 0.25 : 0.12 }

    // Short screens = iPhone landscape. Compact the header and use the full sheet height
    // so all three links fit at once (no scrolling).
    private var isShort: Bool { verticalSizeClass == .compact }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header (compact on short/landscape screens to leave room for the links)
                VStack(spacing: isShort ? 4 : 10) {
                    Image("PodfeetLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: isShort ? 32 : 64)
                        .accessibilityHidden(true)   // decorative; text below conveys the same info
                    Text("Elapsed Time Adder")
                        .font(isShort ? .headline : .title2.bold())
                    Text("A Podfeet App")
                        .font(.subheadline)
                        .foregroundStyle(.primary)   // .secondary fails WCAG AA contrast
                }
                .padding(.top, isShort ? 10 : 24)
                .padding(.bottom, isShort ? 10 : 24)

                Divider()

                // Links
                VStack(spacing: isShort ? 8 : 12) {
                    Link(destination: URL(string: "https://timeadder.podfeet.com")!) {
                        Label("Visit timeadder.podfeet.com", systemImage: "safari")
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color.blue.opacity(buttonOpacity), in: RoundedRectangle(cornerRadius: 10))
                    }
                    Link(destination: URL(string: "mailto:allison@podfeet.com?subject=Elapsed%20Time%20Adder%20Feedback")!) {
                        Label("Send feedback or ask a question", systemImage: "envelope")
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color.blue.opacity(buttonOpacity), in: RoundedRectangle(cornerRadius: 10))
                    }
                    Link(destination: URL(string: "https://github.com/podfeet/elapsed-time-adder/issues/new")!) {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "ladybug")
                                .padding(.top, 2)
                                .accessibilityHidden(true)   // decorative; link text describes it
                            Text("Of the nerd persuasion? Submit an issue on GitHub")
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.blue.opacity(buttonOpacity), in: RoundedRectangle(cornerRadius: 10))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, isShort ? 10 : 20)

                Spacer(minLength: 0)
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        // Short screens (iPhone landscape) open at full height so all three links fit at
        // once without scrolling; taller screens use a comfortable half-sheet.
        .presentationDetents(isShort ? [.large] : [.medium, .large])
    }
}

// MARK: - List row helper

private extension View {
    func plainRow(top: CGFloat = 6, bottom: CGFloat = 6) -> some View {
        self
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: top, leading: 16, bottom: bottom, trailing: 16))
    }
}

#Preview {
    ContentView()
}
