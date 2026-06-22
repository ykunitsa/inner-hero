//
//  TestModelContainer.swift
//  Inner HeroTests
//
//  Shared helpers for SwiftData unit tests: a fresh in-memory container per test
//  (never touches the on-disk store) and a deterministic calendar for day math.
//

import Foundation
import SwiftData
@testable import Inner_Hero

enum TestSupport {

    /// Builds a fresh, isolated in-memory `ModelContainer` using the app's current schema.
    /// Each call returns a brand-new store, so tests never share state.
    static func makeInMemoryContainer() throws -> ModelContainer {
        let schema = Schema(SchemaV2.models)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }

    /// Convenience: a fresh in-memory `ModelContext` ready to use in a test.
    @MainActor
    static func makeInMemoryContext() throws -> ModelContext {
        let container = try makeInMemoryContainer()
        return ModelContext(container)
    }

    /// Fixed UTC Gregorian calendar so `startOfDay` and day boundaries are deterministic
    /// regardless of the machine's locale/timezone.
    static let fixedCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    /// Builds a concrete `Date` in `fixedCalendar` (UTC) for the given components.
    static func date(
        year: Int,
        month: Int,
        day: Int,
        hour: Int = 0,
        minute: Int = 0
    ) -> Date {
        let components = DateComponents(
            calendar: fixedCalendar,
            timeZone: fixedCalendar.timeZone,
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute
        )
        return fixedCalendar.date(from: components)!
    }
}
