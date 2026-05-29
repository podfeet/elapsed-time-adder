//
//  ExportTests.swift
//  ElapsedTimeAdderTests
//
//  Unit tests for CSV and HH:MM:SS export formatting.

import XCTest
@testable import ElapsedTimeAdder

final class ExportTests: XCTestCase {

    // MARK: - Helper

    private func makeRow(title: String = "", h: String, m: String, s: String,
                         subtract: Bool = false) -> TimeRow {
        let r = TimeRow()
        r.title = title; r.hours = h; r.minutes = m; r.seconds = s
        r.isSubtracting = subtract
        return r
    }

    // MARK: - CSV

    func testCSVHeader() {
        let rows = [makeRow(h: "0", m: "0", s: "0")]
        let total = calcTotal(rows: rows)
        let csv = csvString(rows: rows, total: total)
        XCTAssertTrue(csv.hasPrefix("Title,Hours,Minutes,Seconds"))
    }

    func testCSVRowValues() {
        let rows = [makeRow(title: "Intro", h: "1", m: "30", s: "0")]
        let total = calcTotal(rows: rows)
        let lines = csvString(rows: rows, total: total).components(separatedBy: "\n")
        XCTAssertEqual(lines[1], "\"Intro\",1,30,0")
    }

    func testCSVEmptyTitle() {
        let rows = [makeRow(h: "0", m: "5", s: "0")]
        let total = calcTotal(rows: rows)
        let lines = csvString(rows: rows, total: total).components(separatedBy: "\n")
        XCTAssertTrue(lines[1].hasPrefix("\"Row 1\","))   // blank title → "Row 1"
    }

    func testCSVTotalRow() {
        let rows = [makeRow(h: "1", m: "0", s: "0"), makeRow(h: "0", m: "30", s: "0")]
        let total = calcTotal(rows: rows)
        let lines = csvString(rows: rows, total: total).components(separatedBy: "\n")
        XCTAssertEqual(lines.last, "Total,1,30,0")
    }

    func testCSVTitleWithCommaIsQuoted() {
        let rows = [makeRow(title: "My Video, Part 1", h: "1", m: "0", s: "0")]
        let total = calcTotal(rows: rows)
        let lines = csvString(rows: rows, total: total).components(separatedBy: "\n")
        XCTAssertEqual(lines[1], "\"My Video, Part 1\",1,0,0")
    }

    func testCSVTitleWithQuoteIsEscaped() {
        let rows = [makeRow(title: "Allison's \"Best\" Clip", h: "0", m: "5", s: "0")]
        let total = calcTotal(rows: rows)
        let lines = csvString(rows: rows, total: total).components(separatedBy: "\n")
        XCTAssertEqual(lines[1], "\"Allison's \"\"Best\"\" Clip\",0,5,0")
    }

    func testCSVNoUnnecessaryDecimals() {
        // Whole-number values should not appear as "1.0"
        let rows = [makeRow(h: "1", m: "0", s: "0")]
        let total = calcTotal(rows: rows)
        let csv = csvString(rows: rows, total: total)
        XCTAssertFalse(csv.contains("1.0"), "Whole numbers should not have .0 suffix")
    }

    func testCSVLineCount() {
        // Header + 3 data rows + total = 5 lines
        let rows = [makeRow(h: "1", m: "0", s: "0"),
                    makeRow(h: "0", m: "30", s: "0"),
                    makeRow(h: "0", m: "0", s: "45")]
        let total = calcTotal(rows: rows)
        let lines = csvString(rows: rows, total: total).components(separatedBy: "\n")
        XCTAssertEqual(lines.count, 5)
    }

    // MARK: - HH:MM:SS

    func testHHMMSSPaddedZeros() {
        // Single-digit values must be zero-padded to 2 digits
        let rows = [makeRow(title: "Clip", h: "1", m: "5", s: "9")]
        let total = calcTotal(rows: rows)
        let output = hhmmssString(rows: rows, total: total)
        XCTAssertTrue(output.contains("01:05:09"))
    }

    func testHHMMSSTotalLine() {
        let rows = [makeRow(h: "1", m: "30", s: "0")]
        let total = calcTotal(rows: rows)
        let lines = hhmmssString(rows: rows, total: total).components(separatedBy: "\n")
        XCTAssertEqual(lines.last, "Total: 01:30:00")
    }

    func testHHMMSSNegativeTotal() {
        // Negative result → minus sign before hours
        let rows = [makeRow(h: "0", m: "30", s: "0", subtract: true)]
        let total = calcTotal(rows: rows)
        let lines = hhmmssString(rows: rows, total: total).components(separatedBy: "\n")
        XCTAssertEqual(lines.last, "Total: -00:30:00")
    }

    func testHHMMSSEmptyTitleFallsBackToRow() {
        let rows = [makeRow(h: "0", m: "5", s: "0")]   // no title
        let total = calcTotal(rows: rows)
        let lines = hhmmssString(rows: rows, total: total).components(separatedBy: "\n")
        XCTAssertTrue(lines[1].hasPrefix("Row 1:"))   // header at [0]; blank title → "Row 1"
    }

    func testHHMMSSNamedRow() {
        let rows = [makeRow(title: "Segment A", h: "0", m: "5", s: "0")]
        let total = calcTotal(rows: rows)
        let lines = hhmmssString(rows: rows, total: total).components(separatedBy: "\n")
        XCTAssertTrue(lines[1].hasPrefix("Segment A:"))   // header at [0]; data at [1]
    }
}
