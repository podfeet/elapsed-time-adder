//
//  ContentView.swift
//  ElapsedTimeAdder
//
//  Created by Allison on 4/27/26.
//

import SwiftUI

struct ContentView: View {
    @State private var rows: [TimeRow] = [TimeRow(), TimeRow()]
    @State private var showSpreadsheetNote = false
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var isWide: Bool { horizontalSizeClass == .regular }

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

    var body: some View {
        if isWide {
            // MARK: Wide layout — NavigationSplitView controls the columns so
            // WindowGroup doesn't insert its own blank primary column on iPad.
            NavigationSplitView {
                ScrollView {
                    VStack(spacing: 16) {
                        Text("Elapsed Time Adder")
                            .font(.largeTitle.bold())
                            .frame(maxWidth: .infinity, alignment: .center)
                            .multilineTextAlignment(.center)
                        usageHint
                        sidebarExportButtons
                        Spacer(minLength: 32)
                        spreadsheetButton
                        podfeetBranding
                    }
                    .padding()
                }
#if os(iOS)
                .toolbar(.hidden, for: .navigationBar)
#endif
#if os(iOS)
                .navigationSplitViewColumnWidth(min: 320, ideal: 640, max: 640)
#else
                .navigationSplitViewColumnWidth(min: 220, ideal: 300, max: 380)
#endif
                .background(Color.secondary.opacity(0.12))
                .ignoresSafeArea(edges: .leading)
            } detail: {
                ScrollView {
                    rowsSection
                        .padding()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
#if os(iOS)
                .toolbar(.hidden, for: .navigationBar)
#endif
            }
            .navigationSplitViewStyle(.balanced)
            .onAppear {
                if rows.count < 5 {
                    rows.append(contentsOf: (rows.count..<5).map { _ in TimeRow() })
                }
            }

        } else {
            // MARK: Narrow layout — single column (iPhone)
            // List (UITableView) avoids the multi-tap-required-to-focus bug in ScrollView.
            NavigationStack {
                List {
                    Text("Elapsed Time Adder")
                        .font(.largeTitle.bold())
                        .frame(maxWidth: .infinity, alignment: .center)
                        .multilineTextAlignment(.center)
                        .plainRow()
                    usageHint
                        .plainRow()
                    columnHeaders
                        .padding(.horizontal, 10)
                        .plainRow(top: 4, bottom: 0)
                    ForEach(rows) { row in
                        TimeRowView(row: row,
                                    isLast: row.id == rows.last?.id,
                                    onAddRow: { rows.append(TimeRow()) })
                            .plainRow(top: 4, bottom: 4)
                    }
                    totalSummarySection
                        .plainRow()
                    Button {
                        rows.append(TimeRow())
                    } label: {
                        Text("Add Another Row")
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.blue.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("addRowButton")
                    .plainRow()
                    exportButtons
                        .plainRow(top: 0)
                    Divider()
                        .plainRow(top: 4, bottom: 4)
                        .accessibilityHidden(true)
                    resetButton
                        .plainRow()
                    spreadsheetButton
                        .plainRow()
                    podfeetBranding
                        .plainRow(bottom: 8)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .navigationTitle("Elapsed Time Adder")
#if os(iOS)
                .toolbar(.hidden, for: .navigationBar)
#elseif os(macOS)
                .toolbar(.hidden, for: .windowToolbar)
                .ignoresSafeArea(edges: .top)
#endif
            }
        }
    }

    // Used by the wide sidebar layout for the right-hand column
    private var rowsSection: some View {
        VStack(spacing: 16) {
            columnHeaders
                .padding(.horizontal, 10)
            ForEach(rows) { row in
                TimeRowView(row: row,
                            isLast: row.id == rows.last?.id,
                            onAddRow: { rows.append(TimeRow()) })
            }
            totalSummarySection
            Button {
                rows.append(TimeRow())
            } label: {
                Text("Add Another Row")
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .frame(maxWidth: 320)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 4)
            .accessibilityIdentifier("addRowButton")
            Divider().padding(.vertical, 8).accessibilityHidden(true)
            resetButton
        }
        .frame(maxWidth: 560)
        .frame(maxWidth: .infinity, alignment: .center)
    }

    // MARK: - Subviews

    private var usageHint: some View {
        Text("Enter a time in each row and choose Add (+) or\nSubtract (−). The total updates as you type.")
            .font(.callout)
            .foregroundStyle(.primary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: 480, alignment: .center)
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
                    .font(.footnote)
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .center)
            .accessibilityLabel(showSpreadsheetNote ? "Hide spreadsheet note" : "Why not use a spreadsheet?")
            .accessibilityIdentifier("spreadsheetButton")

            if showSpreadsheetNote {
                Text("Why not just use Excel, Numbers, or Google Sheets? Because they don't do *elapsed* time — they do absolute time. Add 22:00 + 5:00 in a spreadsheet and you'll get 3:00 AM, not 27:00.")
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
            ShareLink(
                item: csvExportURL(rows: rows, total: total),
                preview: SharePreview("Elapsed Time Adder Export.csv")
            ) {
                Text("Export CSV")
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)

            ShareLink(
                item: hhmmssExportURL(rows: rows, total: total),
                preview: SharePreview("Elapsed Time Adder Export.txt")
            ) {
                Text("Export HH:MM:SS")
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
        }
    }

    // Sidebar variant: stacked vertically, both buttons sized to the widest one, centered
    private var sidebarExportButtons: some View {
        VStack(spacing: 16) {
            ShareLink(
                item: csvExportURL(rows: rows, total: total),
                preview: SharePreview("Elapsed Time Adder Export.csv")
            ) {
                Text("Export CSV")
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 24)
                    .background(Color.blue.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)

            ShareLink(
                item: hhmmssExportURL(rows: rows, total: total),
                preview: SharePreview("Elapsed Time Adder Export.txt")
            ) {
                Text("Export HH:MM:SS")
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 24)
                    .background(Color.blue.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
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
            rows = [TimeRow(), TimeRow()]
        } label: {
            Text("Reset")
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.red.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
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
        HStack(spacing: 8) {
            Image("PodfeetLogo")
                .resizable()
                .scaledToFit()
                .frame(height: 28)
            Text("A Podfeet App")
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, 4)
        .padding(.bottom, 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("A Podfeet App")
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
