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
    @State private var showAboutSheet = false
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
            ExportButton(
                getText: { csvString(rows: rows, total: total) },
                getFileURL: { csvExportURL(rows: rows, total: total) }
            ) {
                Text("Export CSV")
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)

            ExportButton(
                getText: { hhmmssString(rows: rows, total: total) },
                getFileURL: { hhmmssExportURL(rows: rows, total: total) }
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
            ExportButton(
                getText: { csvString(rows: rows, total: total) },
                getFileURL: { csvExportURL(rows: rows, total: total) }
            ) {
                Text("Export CSV")
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 24)
                    .background(Color.blue.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)

            ExportButton(
                getText: { hhmmssString(rows: rows, total: total) },
                getFileURL: { hhmmssExportURL(rows: rows, total: total) }
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
        Button { showAboutSheet = true } label: {
            HStack(spacing: 8) {
                Image("PodfeetLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 28)
                Text("A Podfeet App · About & Feedback")
                    .font(.subheadline)
                    .foregroundStyle(.primary)
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

// MARK: - ExportButton

/// On iOS: presents `UIActivityViewController` so AirDrop / Save to Files receive
/// a properly named file while Mail, Notes, Messages, etc. receive plain text inline.
/// On macOS: falls back to `ShareLink` with the file URL (macOS share sheet handles
/// both destinations appropriately via standard file sharing).
private struct ExportButton<Label: View>: View {
    let getText: () -> String
    let getFileURL: () -> URL
    @ViewBuilder let label: () -> Label

#if os(iOS)
    @State private var isPresented = false

    var body: some View {
        Button(action: { isPresented = true }) { label() }
            .sheet(isPresented: $isPresented) {
                ExportShareSheet(
                    activityItem: ExportActivityItem(
                        text: getText(),
                        fileURL: getFileURL()
                    )
                )
                .presentationDetents([.medium, .large])
            }
    }
#else
    var body: some View {
        let url = getFileURL()
        ShareLink(item: url, preview: SharePreview(url.lastPathComponent)) {
            label()
        }
    }
#endif
}

#if os(iOS)
private struct ExportShareSheet: UIViewControllerRepresentable {
    let activityItem: ExportActivityItem

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [activityItem], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif

// MARK: - About sheet

private struct AboutSheet: View {
    @Environment(\.dismiss) private var dismiss

    private var versionString: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "Version \(v) (build \(b))"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 10) {
                    Image("PodfeetLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 64)
                    Text("Elapsed Time Adder")
                        .font(.title2.bold())
                    Text("A Podfeet App")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(versionString)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 24)
                .padding(.bottom, 24)

                Divider()

                // Links
                VStack(spacing: 12) {
                    Link(destination: URL(string: "https://timeadder.podfeet.com")!) {
                        Label("Visit timeadder.podfeet.com", systemImage: "safari")
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color.blue.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                    }
                    Link(destination: URL(string: "mailto:allison@podfeet.com?subject=Elapsed%20Time%20Adder%20Feedback")!) {
                        Label("Send feedback or ask a question", systemImage: "envelope")
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color.blue.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                    }
                    Link(destination: URL(string: "https://github.com/podfeet/elapsed-time-adder/issues/new")!) {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "ladybug")
                                .padding(.top, 2)
                            Text("Of the nerd persuasion? Submit an issue on GitHub")
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.blue.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)

                Spacer()
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
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
