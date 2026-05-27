//
//  TimeMath.swift
//  ElapsedTimeAdder
//
//  Port of web/src/timeMath.js — algorithm preserved exactly.

import Foundation

/// The computed total across all rows, broken out into hours, minutes, and seconds.
///
/// Each component carries the sign of the overall result — if the total is negative,
/// all three values will be negative (or zero).  Use `abs()` on each component and
/// check the sign separately when formatting for display.
struct TimeResult {
    /// Total whole hours (may be negative).
    let hours: Double
    /// Remaining whole minutes after hours are extracted (may be negative).
    let minutes: Double
    /// Remaining seconds after hours and minutes are extracted (may be negative).
    /// Rounded to two decimal places — input values with more precision (e.g. `30.5672`)
    /// are accepted but the result is rounded to `30.57` for display and export.
    let seconds: Double
}

/// Calculates the elapsed-time total across an array of rows.
///
/// Each row is converted to a signed number of seconds (negative when
/// `row.isSubtracting` is `true`), summed, then decomposed back into
/// hours / minutes / seconds.  The algorithm is a direct port of
/// `calcTotal()` in `web/src/timeMath.js`.
///
/// - Parameter rows: The rows to sum.  Blank fields are treated as zero.
/// - Returns: A ``TimeResult`` whose components share the sign of the overall
///   total.  All components are zero when the inputs cancel out exactly.
func calcTotal(rows: [TimeRow]) -> TimeResult {
    var totSec: Double = 0

    for row in rows {
        let h = zeroIfBlank(row.hours)
        let m = zeroIfBlank(row.minutes)
        let s = zeroIfBlank(row.seconds)
        let rowSec = h * 3600 + m * 60 + s
        totSec += row.isSubtracting ? -rowSec : rowSec
    }

    // Work with the absolute value to avoid floor() sign issues on negative
    // numbers, then reapply the sign — mirrors the JS original.
    let sign: Double = totSec < 0 ? -1 : (totSec > 0 ? 1 : 0)
    let pos = abs(totSec)

    let hoursPos = floor(pos / 3600)
    var hours = sign * hoursPos
    if hours == 0 { hours = 0 }          // collapse -0

    let minsPos = floor((pos - hoursPos * 3600) / 60)
    var minutes = sign * minsPos
    if minutes == 0 { minutes = 0 }

    let secsPos = (pos - hoursPos * 3600 - minsPos * 60).rounded(toPlaces: 2)
    var seconds = sign * secsPos
    if seconds == 0 { seconds = 0 }

    return TimeResult(hours: hours, minutes: minutes, seconds: seconds)
}

/// Converts a raw field string to a `Double`, treating blank-ish values as zero.
///
/// Mirrors `changeToZero()` from `timeMath.js`.  The special case `"."` represents
/// a valid mid-edit state (the user is about to type a decimal) and contributes
/// nothing to the total rather than being flagged as an error.
///
/// - Parameter s: The raw string from an H/M/S text field.
/// - Returns: The numeric value, or `0` if the string is blank, `"."`,
///   or otherwise non-numeric.
func zeroIfBlank(_ s: String) -> Double {
    let t = s.trimmingCharacters(in: .whitespaces)
    if t.isEmpty || t == "." { return 0 }
    return Double(t) ?? 0
}

/// Returns `true` when a string is acceptable input for an H/M/S field.
///
/// Valid values are blank (treated as zero), the in-progress string `"."`,
/// or any non-negative number.  Letters, special characters, negative numbers,
/// and a bare `"-"` are invalid and will cause the error message to appear.
///
/// - Parameter s: The raw string from an H/M/S text field.
/// - Returns: `true` if the string is empty, a recognised partial value, or a
///   non-negative `Double`; `false` otherwise.
func isValidTimeInput(_ s: String) -> Bool {
    let t = s.trimmingCharacters(in: .whitespaces)
    if t.isEmpty || t == "." { return true }
    guard let value = Double(t) else { return false }
    return value >= 0
}

// MARK: - Double helpers

extension Double {
    /// Rounds the value to `places` decimal places using standard rounding.
    func rounded(toPlaces places: Int) -> Double {
        let factor = pow(10.0, Double(places))
        return (self * factor).rounded() / factor
    }
}
