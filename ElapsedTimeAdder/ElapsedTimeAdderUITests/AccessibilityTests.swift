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
        try runDescriptionAndContrastAudit(label: "Main screen")
    }

    func testAccessibilityAuditWithSpreadsheetNoteExpanded() throws {
        // iOS: spreadsheet button is at the bottom of a scrolling List — scroll it into
        // view first. macOS: it lives in the always-visible sidebar (no scroll needed,
        // and macOS doesn't honor swipeUp like iOS → "no hit point for Application").
#if os(iOS)
        app.swipeUp(velocity: .slow)
#endif
        app.buttons["spreadsheetButton"].tap()
        let note = app.descendants(matching: .any).matching(identifier: "spreadsheetNote").firstMatch
        XCTAssertTrue(note.waitForExistence(timeout: 2), "Spreadsheet note must appear before auditing")
        try runDescriptionAndContrastAudit(label: "Spreadsheet note expanded")
    }

    /// Runs the description + contrast accessibility audit, ignoring structural
    /// container Groups. On macOS, `NavigationSplitView` exposes a window-sized
    /// `SplitGroup`/`SidebarNavigationSplitView` container with no description — that's
    /// a layout container, not user-facing content (VoiceOver navigates the content
    /// inside it), so flagging it as "no description" is a framework false-positive.
    /// We collect remaining issues and assert with full detail, so any *real* failing
    /// element's identity shows up directly in the test failure message.
    private func runDescriptionAndContrastAudit(label: String) throws {
        var issues: [String] = []
        try app.performAccessibilityAudit(for: [.sufficientElementDescription, .contrast]) { issue in
            let element = issue.element
            let elementType = element?.elementType
            let desc = element?.debugDescription ?? ""
            // Ignore macOS system UI that isn't part of our app: on Macs with a Touch Bar,
            // the emoji/symbols "Candidate Bar" (TouchBar + its PopUpButton) is injected
            // into the accessibility tree and has no description. Not ours to fix.
            if desc.contains("TouchBar") || elementType == .touchBar {
                return true
            }
            // Ignore structural container groups that have no description by nature.
            // On macOS, NavigationSplitView exposes window-sized container Groups
            // (SplitGroup / SidebarNavigationSplitView) — layout, not content.
            let isContainer = elementType == .group
                || elementType == .splitGroup
                || desc.contains("NavigationSplitView")
                || desc.contains("SplitGroup")
            let isDescriptionIssue = issue.auditType.contains(.sufficientElementDescription)
            if isDescriptionIssue && isContainer {
                return true   // ignore framework structural container
            }
            let typeName = elementType.map(String.init(describing:)) ?? "unknown"
            issues.append("[\(typeName)] \(issue.compactDescription) :: \(desc.prefix(300))")
            return true
        }
        // Single-line message so the full detail (incl. element type) shows in Xcode's
        // inline error popup, not just a header.
        XCTAssertTrue(issues.isEmpty, "[\(label)] audit issues — " + issues.joined(separator: " ||| "))
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
        // Query by accessibility identifier across ALL element types, not by
        // `.segmentedControls`: a SwiftUI segmented Picker is a segmentedControl on iOS
        // but maps to a different role on macOS, so a type-specific query finds 0 there.
        let toggles = app.descendants(matching: .any).matching(identifier: "toggleButton")
        XCTAssertGreaterThan(toggles.count, 0,
                             "+/− toggle controls must exist with the 'toggleButton' identifier")
        // Verify the Add/Subtract segment labels are present somewhere in the first toggle.
        let first = toggles.firstMatch
        let add = first.descendants(matching: .any).matching(NSPredicate(format: "label == 'Add'")).firstMatch
        let subtract = first.descendants(matching: .any).matching(NSPredicate(format: "label == 'Subtract'")).firstMatch
        XCTAssertTrue(add.exists, "Add segment must exist with 'Add' accessibility label")
        XCTAssertTrue(subtract.exists, "Subtract segment must exist with 'Subtract' accessibility label")
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
        // iOS: scroll the button into view. macOS: it's in the always-visible sidebar.
#if os(iOS)
        app.swipeUp(velocity: .slow)
#endif
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

        // 3. Toggle the first row from + to −.
        // iOS only: tapping a segment and reading `.isSelected` through XCUITest works on
        // iOS but is unreliable on the macOS NSSegmentedControl. The toggle's accessibility
        // (existence + Add/Subtract labels) is verified cross-platform in
        // testToggleButtonsHaveLabels; here we only need to exercise the toggle on iOS.
#if os(iOS)
        let firstToggle = app.segmentedControls.matching(identifier: "toggleButton").firstMatch
        firstToggle.buttons["Subtract"].tap()
        XCTAssertTrue(firstToggle.buttons["Subtract"].isSelected, "Toggle should switch to subtract")
#endif

        // 4. Add a new row
        app.buttons["addRowButton"].tap()
        XCTAssertEqual(app.textFields.matching(hoursPredicate).count, initialRowCount + 1,
                       "Should have one more row after tapping Add Another Row")

        // 5. Enter a value in the new row
        let newRowHours = app.textFields.matching(hoursPredicate).element(boundBy: initialRowCount)
        newRowHours.tap()
        newRowHours.typeText("3")

        // 6. Scroll down to reveal Reset and tap it (iOS only; macOS shows it without scroll)
#if os(iOS)
        app.swipeUp(velocity: .slow)
#endif
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

        // iOS only: segment selection state is unreliable through XCUITest on macOS.
        // (We only switched the toggle to Subtract on iOS in step 3, so only iOS needs
        // to verify it returned to Add.)
#if os(iOS)
        XCTAssertTrue(app.segmentedControls.matching(identifier: "toggleButton").firstMatch.buttons["Add"].isSelected,
                      "Toggle should be back to + after reset")
#endif
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
