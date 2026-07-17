//
//  Inner_HeroTests.swift
//  Inner HeroTests
//
//  Smoke tests for the app shell. Model tests return together with the
//  new 2.0 data models.
//

import XCTest
import SwiftUI
@testable import Inner_Hero

final class Inner_HeroTests: XCTestCase {

    /// Test: MainTabView initializes without errors
    @MainActor
    func testMainTabViewInitialization() throws {
        let view = MainTabView()
        XCTAssertNotNil(view, "MainTabView should be created")
    }

    /// Test: all app tabs are distinct
    func testAppTabsAreDistinct() throws {
        let tabs = AppTab.allCases
        XCTAssertEqual(Set(tabs.map(\.rawValue)).count, tabs.count)
    }
}
