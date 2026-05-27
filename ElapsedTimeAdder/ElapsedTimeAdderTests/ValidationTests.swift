//
//  ValidationTests.swift
//  ElapsedTimeAdderTests
//
//  Unit tests for isValidTimeInput() — the H/M/S field validation function.

import XCTest
@testable import ElapsedTimeAdder

final class ValidationTests: XCTestCase {

    // MARK: - Valid inputs (should return true)

    func testEmptyStringIsValid() {
        XCTAssertTrue(isValidTimeInput(""), "Empty string should be valid (treated as 0)")
    }

    func testWhitespaceIsValid() {
        XCTAssertTrue(isValidTimeInput("   "), "Whitespace should be valid (treated as 0)")
    }

    func testDashIsInvalid() {
        XCTAssertFalse(isValidTimeInput("-"), "Lone dash should be invalid (negative values are not allowed)")
    }

    func testDotIsValid() {
        XCTAssertTrue(isValidTimeInput("."), "Lone dot should be valid (treated as 0)")
    }

    func testZeroIsValid() {
        XCTAssertTrue(isValidTimeInput("0"), "Zero should be valid")
    }

    func testPositiveIntegerIsValid() {
        XCTAssertTrue(isValidTimeInput("42"), "Positive integer should be valid")
    }

    func testPositiveDecimalIsValid() {
        XCTAssertTrue(isValidTimeInput("1.5"), "Positive decimal should be valid")
    }

    func testLargeNumberIsValid() {
        XCTAssertTrue(isValidTimeInput("999"), "Large number should be valid")
    }

    // MARK: - Invalid inputs (should return false)

    func testLettersAreInvalid() {
        XCTAssertFalse(isValidTimeInput("abc"), "Letters should be invalid")
    }

    func testMixedAlphanumericIsInvalid() {
        XCTAssertFalse(isValidTimeInput("1a"), "Mixed alphanumeric should be invalid")
    }

    func testSpecialCharactersAreInvalid() {
        XCTAssertFalse(isValidTimeInput("@"), "Special characters should be invalid")
    }

    func testNegativeNumberIsInvalid() {
        XCTAssertFalse(isValidTimeInput("-5"), "Negative numbers should be invalid (use the +/− toggle instead)")
    }

    func testExclamationMarkIsInvalid() {
        XCTAssertFalse(isValidTimeInput("!"), "Exclamation mark should be invalid")
    }

    func testCommaIsInvalid() {
        XCTAssertFalse(isValidTimeInput("1,5"), "Comma-separated number should be invalid")
    }
}
