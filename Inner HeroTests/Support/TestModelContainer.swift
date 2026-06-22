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

    // MARK: - "Today"-anchored helpers
    //
    // Some logic (e.g. ScheduleViewModel streaks) reads `Date()` / `Calendar.current`
    // directly and is not yet time-injectable (see TECH_DEBT A2). These helpers anchor
    // seed data to the same real clock the code under test uses, so tests stay
    // deterministic relative to the moment they run. Once time injection lands,
    // prefer the fixed-date `date(...)` helper above.

    /// Start of the current day in `Calendar.current`, shifted by `offsetDays`.
    static func dayStart(offsetDays: Int = 0) -> Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return calendar.date(byAdding: .day, value: offsetDays, to: today) ?? today
    }

    /// Midday on the current day in `Calendar.current`, shifted by `offsetDays`.
    /// Useful for `performedAt`-style timestamps that should fall inside a day window.
    static func midday(offsetDays: Int = 0) -> Date {
        Calendar.current.date(byAdding: .hour, value: 12, to: dayStart(offsetDays: offsetDays))
            ?? dayStart(offsetDays: offsetDays)
    }
}
