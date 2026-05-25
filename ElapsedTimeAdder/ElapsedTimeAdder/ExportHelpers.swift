//
//  ExportHelpers.swift
//  ElapsedTimeAdder
//
//  Formats rows + total for CSV and HH:MM:SS export via share sheet.

import Foundation
import UniformTypeIdentifiers
import CoreTransferable

// MARK: - Transferable wrappers

/// A CSV document that conforms to `Transferable` so that `ShareLink` produces
/// a single file with a `.csv` extension instead of a plain-text blob.
struct CSVFile: Transferable {
    let content: String

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .commaSeparatedText) { file in
            Data(file.content.utf8)
        }
    }
}

/// A plain-text document that conforms to `Transferable` so that `ShareLink`
/// treats the content as a `.txt` file rather than sniffing it for URLs.
/// (Without this, macOS sees "Row:" as a URL scheme and shows an error.)
struct TextFile: Transferable {
    let content: String

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .plainText) { file in
            Data(file.content.utf8)
        }
    }
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
    for row in rows {
        let h = zeroIfBlank(row.hours)
        let m = zeroIfBlank(row.minutes)
        let s = zeroIfBlank(row.seconds)
        lines.append("\(row.title),\(rawNum(h)),\(rawNum(m)),\(rawNum(s))")
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
    var lines: [String] = []
    for row in rows {
        let h = zeroIfBlank(row.hours)
        let m = zeroIfBlank(row.minutes)
        let s = zeroIfBlank(row.seconds)
        let label = row.title.isEmpty ? "Row" : row.title
        lines.append("\(label): \(formatHMS(h: h, m: m, s: s, negative: false))")
    }
    let negative = total.hours < 0 || total.minutes < 0 || total.seconds < 0
    lines.append("Total: \(formatHMS(h: abs(total.hours), m: abs(total.minutes), s: abs(total.seconds), negative: negative))")
    return lines.joined(separator: "\n")
}

// MARK: - Private helpers

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
