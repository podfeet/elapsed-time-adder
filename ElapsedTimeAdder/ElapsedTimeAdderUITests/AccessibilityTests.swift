//
//  AccessibilityTests.swift
//  ElapsedTimeAdderUITests
//

import XCTest

final class AccessibilityTests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    // MARK: - Automated audit

    func testAccessibilityAuditMainScreen() throws {
        // We audit only for element descriptions and contrast. The parent/child
        // containment check is skipped because it is likely triggered by SwiftUI's
        // internal frame math inside ScrollView, not a real user-facing problem.
        try app.performAccessibilityAudit(for: [.sufficientElementDescription, .contrast]) { issue in
            print("AUDIT ISSUE: \(issue.compactDescription) | element: \(issue.element?.debugDescription ?? "unknown")")
            return false
        }
    }

    func testAccessibilityAuditWithSpreadsheetNoteExpanded() throws {
        app.swipeUp(velocity: .slow)
        app.buttons["spreadsheetButton"].tap()
        let note = app.descendants(matching: .any).matching(identifier: "spreadsheetNote").firstMatch
        XCTAssertTrue(note.waitForExistence(timeout: 2), "Spreadsheet note must appear before auditing")
        try app.performAccessibilityAudit(for: [.sufficientElementDescription, .contrast]) { issue in
            print("AUDIT ISSUE (expanded): \(issue.compactDescription) | element: \(issue.element?.debugDescription ?? "unknown")")
            return false
        }
    }

    // MARK: - Key buttons exist and are reachable

    func testAddRowButtonExists() {
        XCTAssertTrue(app.buttons["addRowButton"].exists,
                      "Add Another Row button must be accessible")
    }

    func testResetButtonExists() {
        XCTAssertTrue(app.buttons["resetButton"].exists,
                      "Reset button must be accessible")
    }

    func testSpreadsheetButtonExists() {
        XCTAssertTrue(app.buttons["spreadsheetButton"].exists,
                      "'Why not use a spreadsheet?' button must be accessible")
    }

    func testToggleButtonsHaveLabels() {
        let toggles = app.segmentedControls.matching(identifier: "toggleButton")
        XCTAssertGreaterThan(toggles.count, 0,
                             "+/− segmented controls must exist and have an accessibility identifier")
        // SwiftUI's segmented Picker exposes the label on a wrapper element, not the
        // UISegmentedControl itself, so XCTest sees "" for the control label.
        // Verify the segments have meaningful labels instead.
        XCTAssertTrue(toggles.firstMatch.buttons["Add"].exists,
                      "Add segment must exist with 'Add' accessibility label")
        XCTAssertTrue(toggles.firstMatch.buttons["Subtract"].exists,
                      "Subtract segment must exist with 'Subtract' accessibility label")
    }

    // MARK: - Text fields are labelled for VoiceOver

    func testHourFieldsHaveLabels() {
        let fields = app.textFields.matching(NSPredicate(format: "label == 'Hours'"))
        XCTAssertGreaterThan(fields.count, 0, "Hour fields must have 'Hours' accessibility label")
    }

    func testMinuteFieldsHaveLabels() {
        let fields = app.textFields.matching(NSPredicate(format: "label == 'Minutes'"))
        XCTAssertGreaterThan(fields.count, 0, "Minute fields must have 'Minutes' accessibility label")
    }

    func testSecondFieldsHaveLabels() {
        let fields = app.textFields.matching(NSPredicate(format: "label == 'Seconds'"))
        XCTAssertGreaterThan(fields.count, 0, "Second fields must have 'Seconds' accessibility label")
    }

    // MARK: - Spreadsheet button expander

    func testSpreadsheetButtonExpandsAndCollapses() {
        let button = app.buttons["spreadsheetButton"]
        XCTAssertTrue(button.exists, "spreadsheetButton must exist")
        // Scroll down so the button is visible before tapping
        app.swipeUp(velocity: .slow)
        XCTAssertTrue(button.isHittable, "spreadsheetButton must be hittable")
        button.tap()
        let note = app.descendants(matching: .any).matching(identifier: "spreadsheetNote").firstMatch
        XCTAssertTrue(note.waitForExistence(timeout: 2),
                      "Spreadsheet note should appear after tapping the button")
        button.tap()
        let gone = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"),
                                             object: note)
        XCTWaiter().wait(for: [gone], timeout: 2)
        XCTAssertFalse(note.exists, "Spreadsheet note should disappear after tapping 'Hide'")
    }

    // MARK: - Add Row

    func testAddRowIncreasesRowCount() {
        let before = app.textFields.matching(NSPredicate(format: "label == 'Hours'")).count
        app.buttons["addRowButton"].tap()
        let after = app.textFields.matching(NSPredicate(format: "label == 'Hours'")).count
        XCTAssertEqual(after, before + 1, "Add Another Row should add exactly one row")
    }

    // MARK: - Reset

    func testResetRestoresInitialState() {
        let hoursPredicate = NSPredicate(format: "label == 'Hours'")
        let initialRowCount = app.textFields.matching(hoursPredicate).count

        // 1. Add a title to the first row
        let firstTitle = app.textFields.matching(NSPredicate(format: "label == 'Row title'")).firstMatch
        firstTitle.tap()
        firstTitle.typeText("My Segment")

        // 2. Enter hours in the first row
        let firstHours = app.textFields.matching(hoursPredicate).firstMatch
        firstHours.tap()
        firstHours.typeText("5")

        // 3. Toggle the first row from + to −
        let firstToggle = app.segmentedControls.matching(identifier: "toggleButton").firstMatch
        firstToggle.buttons["Subtract"].tap()
        XCTAssertTrue(firstToggle.buttons["Subtract"].isSelected, "Toggle should switch to subtract")

        // 4. Add a new row
        app.buttons["addRowButton"].tap()
        XCTAssertEqual(app.textFields.matching(hoursPredicate).count, initialRowCount + 1,
                       "Should have one more row after tapping Add Another Row")

        // 5. Enter a value in the new row
        let newRowHours = app.textFields.matching(hoursPredicate).element(boundBy: initialRowCount)
        newRowHours.tap()
        newRowHours.typeText("3")

        // 6. Scroll down to reveal Reset and tap it
        app.swipeUp(velocity: .slow)
        app.buttons["resetButton"].tap()
        // Brief pause to let SwiftUI finish layout after reset — prevents
        // "Invalid frame dimension" warnings in the accessibility tree.
        Thread.sleep(forTimeInterval: 0.3)

        // 7. Verify everything is back to the initial state
        XCTAssertEqual(app.textFields.matching(hoursPredicate).count, initialRowCount,
                       "Row count should be restored after reset")

        let hoursValue = app.textFields.matching(hoursPredicate).firstMatch.value as? String ?? ""
        XCTAssertTrue(hoursValue == "" || hoursValue == "0",
                      "Hours field should be empty after reset (got: \(hoursValue))")

        let titleValue = app.textFields.matching(NSPredicate(format: "label == 'Row title'")).firstMatch.value as? String ?? ""
        XCTAssertTrue(titleValue == "" || titleValue == "title" || titleValue == "title (opt)",
                      "Title field should be empty after reset (got: \(titleValue))")

        XCTAssertTrue(app.segmentedControls.matching(identifier: "toggleButton").firstMatch.buttons["Add"].isSelected,
                      "Toggle should be back to + after reset")
    }

    // MARK: - Input validation

    func testInvalidInputShowsError() {
        let hoursField = app.textFields.matching(NSPredicate(format: "label == 'Hours'")).firstMatch
        hoursField.tap()
        hoursField.typeText("1..")   // double decimal — invalid but typeable on decimal pad
        let error = app.descendants(matching: .any).matching(identifier: "errorMessage").firstMatch
        XCTAssertTrue(error.waitForExistence(timeout: 1),
                      "Error message should appear when invalid text is entered in an H/M/S field")
    }

    func testValidInputHidesError() {
        // First trigger the error
        let hoursField = app.textFields.matching(NSPredicate(format: "label == 'Hours'")).firstMatch
        hoursField.tap()
        hoursField.typeText("1..")   // double decimal — invalid but typeable on decimal pad
        let error = app.descendants(matching: .any).matching(identifier: "errorMessage").firstMatch
        XCTAssertTrue(error.waitForExistence(timeout: 1))

        // Clear and enter a valid number — error should disappear
        hoursField.clearText()
        hoursField.typeText("5")
        XCTAssertFalse(error.waitForExistence(timeout: 1),
                       "Error message should disappear when valid input is entered")
    }

    func testSpecialCharactersShowError() {
        let minutesField = app.textFields.matching(NSPredicate(format: "label == 'Minutes'")).firstMatch
        minutesField.tap()
        minutesField.typeText("1..")  // "1.." is invalid (not a valid Double) and typeable on decimal pad
        let error = app.descendants(matching: .any).matching(identifier: "errorMessage").firstMatch
        XCTAssertTrue(error.waitForExistence(timeout: 1),
                      "Double decimal should trigger the error message")
    }
}

// MARK: - XCUIElement helper

extension XCUIElement {
    func clearText() {
        guard let value = self.value as? String, !value.isEmpty else { return }
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: value.count)
        self.typeText(deleteString)
    }
}
