//
//  TodayViewModelTests.swift
//  Inner HeroTests
//
//  Today tab logic (spec §2.1): greeting boundaries, empty schedule.
//

import Testing
import Foundation
@testable import Inner_Hero

@Suite("Today")
@MainActor
struct TodayViewModelTests {

    @Test("Greeting covers every hour, boundaries included")
    func greetingBoundaries() {
        let expected: [(Int, String)] = [
            (0,  "Good night"),   (4,  "Good night"),
            (5,  "Good morning"), (11, "Good morning"),
            (12, "Good afternoon"), (16, "Good afternoon"),
            (17, "Good evening"), (21, "Good evening"),
            (22, "Good night"),  (23, "Good night"),
        ]
        for (hour, key) in expected {
            #expect(
                TodayViewModel.greeting(forHour: hour) == String(localized: String.LocalizationValue(key)),
                "hour \(hour) should greet with \(key)"
            )
        }
    }

    @Test("Every hour of the day maps to some greeting")
    func greetingTotality() {
        for hour in 0..<24 {
            #expect(!TodayViewModel.greeting(forHour: hour).isEmpty)
        }
    }

    @Test("Greeting follows the injected clock, not the wall clock")
    func greetingUsesInjectedTime() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar = { var c = calendar; c.timeZone = TimeZone(identifier: "UTC")!; return c }()

        let morning = try #require(
            calendar.date(from: DateComponents(year: 2026, month: 7, day: 20, hour: 9))
        )
        let evening = try #require(
            calendar.date(from: DateComponents(year: 2026, month: 7, day: 20, hour: 19))
        )

        let viewModel = TodayViewModel(now: morning, calendar: calendar)
        #expect(viewModel.greeting == String(localized: "Good morning"))

        viewModel.refresh(now: evening)
        #expect(viewModel.greeting == String(localized: "Good evening"))
    }

    /// Spec §2.1: the empty state is a line of text, never a prompt to go
    /// configure something. It shows exactly while no exposure is on today's list.
    @Test("The quiet line shows until an exposure is on the day")
    func emptySchedule() {
        let viewModel = TodayViewModel()
        #expect(viewModel.emptyScheduleText.isEmpty == false)
        #expect(TodayViewModel.hasExposure(in: []) == false)

        let exposure = ScheduleItem(exercise: .exposure, recurrence: .weekly, hour: 19, minute: 0)
        let breathing = ScheduleItem(exercise: .breathing, recurrence: .weekly, hour: 7, minute: 0)

        #expect(TodayViewModel.hasExposure(in: [
            TodayScheduleRow(item: breathing, isDone: false)
        ]) == false)
        #expect(TodayViewModel.hasExposure(in: [
            TodayScheduleRow(item: breathing, isDone: false),
            TodayScheduleRow(item: exposure, isDone: false),
        ]))
    }
}
