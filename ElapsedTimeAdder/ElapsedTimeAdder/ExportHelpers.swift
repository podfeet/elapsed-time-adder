//
//  ExportHelpers.swift
//  ElapsedTimeAdder
//
//  Formats rows + total for CSV and HH:MM:SS export via share sheet.

import Foundation
#if os(iOS)
import UIKit
import LinkPresentation
#endif

// MARK: - iOS share routing

#if os(iOS)
/// Provides different data to each share destination:
/// - AirDrop, Save to Files, iCloud Drive → the named file URL (proper filename + extension)
/// - Mail, Notes, Messages, etc. → plain text (inserted inline, not as an attachment)
///
/// `UIActivityItemSource` is the only iOS API that allows per-destination routing;
/// SwiftUI's `Transferable`/`ShareLink` picks a single representation for all destinations.
final class ExportActivityItem: NSObject, UIActivityItemSource {
    let text: String
    let fileURL: URL

    init(text: String, fileURL: URL) {
        self.text = text
        self.fileURL = fileURL
    }

    func activityViewControllerPlaceholderItem(
        _ activityViewController: UIActivityViewController
    ) -> Any { text }

    func activityViewController(
        _ activityViewController: UIActivityViewController,
        itemForActivityType activityType: UIActivity.ActivityType?
    ) -> Any? {
        guard let type = activityType else { return text }
        let id = type.rawValue.lowercased()
        let wantsFile = type == .airDrop
            || id.contains("file")
            || id.contains("document")
            || id.contains("icloud")
        return wantsFile ? fileURL : text
    }

    func activityViewControllerLinkMetadata(
        _ activityViewController: UIActivityViewController
    ) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()
        metadata.title = fileURL.lastPathComponent
        if let appIcon = UIImage(named: "AppIcon") {
            metadata.iconProvider = NSItemProvider(object: appIcon)
        }
        return metadata
    }
}
#endif

// MARK: - Export URLs

/// Writes the CSV content to a temporary file named "Elapsed Time Adder Export.csv"
/// and returns its file URL.  `ShareLink(item: url)` transfers a file URL as an
/// actual file via AirDrop, preserving the filename exactly.
func csvExportURL(rows: [TimeRow], total: TimeResult) -> URL {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("Elapsed Time Adder Export.csv")
    try? csvString(rows: rows, total: total)
        .write(to: url, atomically: true, encoding: .utf8)
    return url
}

/// Writes the HH:MM:SS content to a temporary file named
/// "Elapsed Time Adder Export.txt" and returns its file URL.
func hhmmssExportURL(rows: [TimeRow], total: TimeResult) -> URL {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("Elapsed Time Adder Export.txt")
    try? hhmmssString(rows: rows, total: total)
        .write(to: url, atomically: true, encoding: .utf8)
    return url
}

// MARK: - CSV

/// Produces a CSV-formatted string containing every row and the computed total.
///
/// The first line is a header row (`Title,Hours,Minutes,Seconds`).  Each
/// subsequent line represents one input row, with blank fields exported as `0`.
/// The final line is the computed total.  Decimal values are written without
/// trailing zeros (e.g. `30.5` rather than `30.500000`).
///
/// Example output:
/// ```
/// Title,Hours,Minutes,Seconds
/// Morning commute,1,30,0
/// Coffee stop,0,15,30
/// Total,1,45,30
/// ```
///
/// - Parameters:
///   - rows: The input rows to export.
///   - total: The pre-computed ``TimeResult`` total.
/// - Returns: A newline-separated CSV string ready to pass to a `ShareLink`.
func csvString(rows: [TimeRow], total: TimeResult) -> String {
    var lines = ["Title,Hours,Minutes,Seconds"]
    for (index, row) in rows.filter({ !isEmptyRow($0) }).enumerated() {
        let label = row.title.isEmpty ? "Row \(index + 1)" : row.title
        let h = zeroIfBlank(row.hours)
        let m = zeroIfBlank(row.minutes)
        let s = zeroIfBlank(row.seconds)
        lines.append("\(label),\(rawNum(h)),\(rawNum(m)),\(rawNum(s))")
    }
    lines.append("Total,\(rawNum(total.hours)),\(rawNum(total.minutes)),\(rawNum(total.seconds))")
    return lines.joined(separator: "\n")
}

// MARK: - HH:MM:SS

/// Produces a plain-text HH:MM:SS summary of every row and the computed total.
///
/// Each line is labelled with the row's title (or `"Row"` when the title is
/// blank) followed by a colon and the time in `HH:MM:SS` format.  The final
/// line shows the signed total; a negative total is prefixed with `"-"`.
/// Seconds with decimal values are formatted as `MM:SS.ss` (e.g. `01:30.50`).
///
/// Example output:
/// ```
/// Morning commute: 01:30:00
/// Coffee stop: 00:15:30
/// Total: 01:45:30
/// ```
///
/// - Parameters:
///   - rows: The input rows to export.
///   - total: The pre-computed ``TimeResult`` total.
/// - Returns: A newline-separated string ready to pass to a `ShareLink`.
func hhmmssString(rows: [TimeRow], total: TimeResult) -> String {
    var lines = ["Title HH:MM:SS"]
    for (index, row) in rows.filter({ !isEmptyRow($0) }).enumerated() {
        let h = zeroIfBlank(row.hours)
        let m = zeroIfBlank(row.minutes)
        let s = zeroIfBlank(row.seconds)
        let label = row.title.isEmpty ? "Row \(index + 1)" : row.title
        lines.append("\(label): \(formatHMS(h: h, m: m, s: s, negative: false))")
    }
    let negative = total.hours < 0 || total.minutes < 0 || total.seconds < 0
    lines.append("Total: \(formatHMS(h: abs(total.hours), m: abs(total.minutes), s: abs(total.seconds), negative: negative))")
    return lines.joined(separator: "\n")
}

// MARK: - Private helpers

/// Returns `true` when a row has no title and all time fields are zero —
/// meaning it contributes nothing and should be omitted from exports.
private func isEmptyRow(_ row: TimeRow) -> Bool {
    row.title.isEmpty
        && zeroIfBlank(row.hours)   == 0
        && zeroIfBlank(row.minutes) == 0
        && zeroIfBlank(row.seconds) == 0
}

/// Formats a `Double` as a compact number string, dropping the decimal when
/// the value is a whole number (e.g. `30.0` → `"30"`, `30.5` → `"30.5"`).
private func rawNum(_ d: Double) -> String {
    if d == floor(d) { return String(Int(d)) }
    return String(d)
}

/// Formats hours, minutes, and seconds as a zero-padded `HH:MM:SS` string.
///
/// When `s` has a fractional component the seconds field is widened to
/// `SS.ss` (five characters including the decimal point) so the output
/// remains consistently parseable.
///
/// - Parameters:
///   - h: Hours (non-negative).
///   - m: Minutes (non-negative).
///   - s: Seconds (non-negative, may be fractional).
///   - negative: When `true` a `"-"` prefix is prepended to the result.
private func formatHMS(h: Double, m: Double, s: Double, negative: Bool) -> String {
    let sign = negative ? "-" : ""
    let hh = String(format: "%02d", Int(h))
    let mm = String(format: "%02d", Int(m))
    let ss: String
    if s == floor(s) {
        ss = String(format: "%02d", Int(s))
    } else {
        ss = String(format: "%05.2f", s)
    }
    return "\(sign)\(hh):\(mm):\(ss)"
}
