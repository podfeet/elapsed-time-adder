//
//  LayoutTests.swift
//  ElapsedTimeAdderTests
//
//  Unit tests for isWideLayout() — the wide (sidebar) vs. narrow (List) layout
//  decision. Tests the pure decision logic directly with size-class values rather
//  than automating real device rotation in a UI test, which proved unreliable
//  (XCUIDevice.shared.orientation produced a false failure even when the app was
//  visually confirmed correct on an iPhone 17 Pro Max simulator).

import XCTest
import SwiftUI
@testable import ElapsedTimeAdder

final class LayoutTests: XCTestCase {

    func testRegularRegularIsWide() {
        XCTAssertTrue(isWideLayout(horizontalSizeClass: .regular, verticalSizeClass: .regular),
                      "iPad/Mac-style regular/regular should use the wide layout")
    }

    func testPlusMaxLandscapeIsNotWide() {
        // A Plus/Max iPhone in landscape reports horizontal .regular (like an iPad)
        // but vertical .compact — this is the exact case isWideLayout must keep on
        // the narrow layout.
        XCTAssertFalse(isWideLayout(horizontalSizeClass: .regular, verticalSizeClass: .compact),
                       "Regular width but compact height (Plus/Max iPhone landscape) must stay on the narrow layout")
    }

    func testCompactPortraitIsNotWide() {
        XCTAssertFalse(isWideLayout(horizontalSizeClass: .compact, verticalSizeClass: .regular),
                       "Compact width should never select the wide layout")
    }

    func testCompactCompactIsNotWide() {
        XCTAssertFalse(isWideLayout(horizontalSizeClass: .compact, verticalSizeClass: .compact),
                       "Compact/compact (standard iPhone portrait) should use the narrow layout")
    }

    func testNilSizeClassesAreNotWide() {
        // Defensive: environment values can be nil before the view hierarchy has
        // fully established size classes.
        XCTAssertFalse(isWideLayout(horizontalSizeClass: nil, verticalSizeClass: nil),
                       "Missing size class info should not default to the wide layout")
    }
}
