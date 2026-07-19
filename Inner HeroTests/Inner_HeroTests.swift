//
//  Inner_HeroTests.swift
//  Inner HeroTests
//
//  Smoke tests for the app shell. Model tests return together with the
//  new 2.0 data models.
//

import Testing
import SwiftUI
@testable import Inner_Hero

@Suite("App shell")
struct AppShellTests {

    @Test("MainTabView initializes without crashing")
    @MainActor
    func mainTabViewInitializes() {
        let view = MainTabView()
        #expect(String(describing: view).isEmpty == false)
    }

    @Test("All app tabs are distinct")
    func appTabsAreDistinct() {
        let tabs = AppTab.allCases
        #expect(Set(tabs.map(\.rawValue)).count == tabs.count)
    }
}
