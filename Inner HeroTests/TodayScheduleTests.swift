import Foundation
import Testing

@testable import Inner_Hero

/// §11.6d2 — the day list on Today and its quiet "done" marks.
@Suite("Today schedule")
struct TodayScheduleTests {

    private static func calendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        calendar.firstWeekday = 2
        return calendar
    }

    private static func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar().date(from: DateComponents(year: year, month: month, day: day))!
    }

    /// 2026-07-24 is a Friday (weekday 6).
    private static let today = date(2026, 7, 24)
    private static let yesterday = date(2026, 7, 23)

    // MARK: - Rows

    @Test("Only what falls on today, in time order")
    func rowsAreTodaysInTimeOrder() {
        let calendar = Self.calendar()
        let evening = ScheduleItem(exercise: .relaxation, recurrence: .weekly, hour: 21, minute: 30)
        let morning = ScheduleItem(exercise: .breathing, recurrence: .weekly, hour: 7, minute: 0)
        let otherDay = ScheduleItem(
            exercise: .activation, recurrence: .weekly, hour: 9, minute: 0, weekdays: [1]
        )
        let tomorrow = ScheduleItem(
            exercise: .exposure, recurrence: .once, hour: 19, minute: 0,
            onceDate: Self.date(2026, 7, 25)
        )

        let rows = TodayViewModel.rows(
            schedule: [evening, morning, otherDay, tomorrow],
            done: [],
            on: Self.today,
            calendar: calendar
        )

        #expect(rows.map(\.item.hour) == [7, 21])
    }

    @Test("A disabled entry is not on the day")
    func disabledIsNotShown() {
        let item = ScheduleItem(
            exercise: .breathing, recurrence: .weekly, hour: 18, minute: 0, isEnabled: false
        )
        let rows = TodayViewModel.rows(
            schedule: [item], done: [], on: Self.today, calendar: Self.calendar()
        )
        #expect(rows.isEmpty)
    }

    @Test("Two entries for one exercise both appear")
    func twoEntriesOneExercise() {
        let morning = ScheduleItem(exercise: .relaxation, recurrence: .weekly, hour: 7, minute: 0)
        let night = ScheduleItem(exercise: .relaxation, recurrence: .weekly, hour: 22, minute: 0)

        let rows = TodayViewModel.rows(
            schedule: [night, morning], done: [.relaxation], on: Self.today, calendar: Self.calendar()
        )

        let allDone = rows.allSatisfy(\.isDone)
        #expect(rows.count == 2)
        // One log marks the exercise done, so both of its rows carry the mark.
        // The alternative — guessing which of the two the session belonged to —
        // would be inventing data (§1.6).
        #expect(allDone)
    }

    @Test("A done exercise marks its row, an untouched one does not")
    func doneMarksItsRow() {
        let breathing = ScheduleItem(exercise: .breathing, recurrence: .weekly, hour: 7, minute: 0)
        let pmr = ScheduleItem(exercise: .relaxation, recurrence: .weekly, hour: 21, minute: 0)

        let rows = TodayViewModel.rows(
            schedule: [breathing, pmr], done: [.breathing], on: Self.today, calendar: Self.calendar()
        )

        #expect(rows.first?.isDone == true)
        #expect(rows.last?.isDone == false)
    }

    // MARK: - Done marks

    @Test("Today's log counts, yesterday's does not")
    func doneIsPerDay() {
        let calendar = Self.calendar()

        var done = TodayViewModel.doneExercises(
            exposures: [ExposureLogEntry(createdAt: Self.today, situation: "Metro", anxiety: 5, behavior: .stayed, safetyBehaviors: [])],
            breathing: [], pmr: [], activation: [],
            on: Self.today, calendar: calendar
        )
        #expect(done == [.exposure])

        done = TodayViewModel.doneExercises(
            exposures: [ExposureLogEntry(createdAt: Self.yesterday, situation: "Metro", anxiety: 5, behavior: .stayed, safetyBehaviors: [])],
            breathing: [], pmr: [], activation: [],
            on: Self.today, calendar: calendar
        )
        #expect(done.isEmpty)
    }

    /// The one exception, and it is forced: an open tail is already on this screen
    /// asking "Did it happen?" — a row saying "done" beside it would make Today
    /// contradict itself.
    @Test("An open BA entry is not done; a closed one is")
    func openBAIsNotDone() {
        let calendar = Self.calendar()
        let open = BALogEntry(
            createdAt: Self.today, activityID: nil, activityTitle: "Walk",
            effort: .easy, energy: .little, forecast: nil
        )

        var done = TodayViewModel.doneExercises(
            exposures: [], breathing: [], pmr: [], activation: [open],
            on: Self.today, calendar: calendar
        )
        #expect(done.isEmpty, "the tail is still asking")

        // "Couldn't" closes the entry and counts: the person went through the
        // exercise, and grading the outcome is not the app's job (§1.5).
        open.outcomeRaw = BAOutcome.couldNot.rawValue
        done = TodayViewModel.doneExercises(
            exposures: [], breathing: [], pmr: [], activation: [open],
            on: Self.today, calendar: calendar
        )
        #expect(done == [.activation])
    }

    @Test("Each log marks its own exercise")
    func eachLogMarksItsOwn() {
        let calendar = Self.calendar()
        let ba = BALogEntry(
            createdAt: Self.today, activityID: nil, activityTitle: "Walk",
            effort: .easy, energy: .little, forecast: nil
        )
        ba.outcomeRaw = BAOutcome.done.rawValue

        let done = TodayViewModel.doneExercises(
            exposures: [ExposureLogEntry(createdAt: Self.today, situation: "Metro", anxiety: 5, behavior: .stayed, safetyBehaviors: [])],
            breathing: [BreathingSessionEntry(createdAt: Self.today, pattern: .box, plannedDurationSeconds: 600)],
            pmr: [PMRSessionEntry(createdAt: Self.today, step: .sevenGroups, plannedDurationSeconds: 900)],
            activation: [ba],
            on: Self.today, calendar: calendar
        )

        #expect(done == [.exposure, .breathing, .relaxation, .activation])
    }

    // MARK: - Meta

    @Test("The meta line is the time, and says so quietly when it is done")
    func metaShape() {
        let calendar = Self.calendar()
        let item = ScheduleItem(exercise: .breathing, recurrence: .weekly, hour: 18, minute: 0)
        let time = ScheduleViewModel.timeText(hour: 18, minute: 0, calendar: calendar)

        let pending = TodayViewModel.meta(
            for: TodayScheduleRow(item: item, isDone: false), calendar: calendar
        )
        #expect(pending == time)

        let done = TodayViewModel.meta(
            for: TodayScheduleRow(item: item, isDone: true), calendar: calendar
        )
        #expect(done.hasPrefix(time))
        #expect(done.hasSuffix(String(localized: "done")))
        // No counting, ever: the mark is a fact about one row, not a tally (§1.4).
        #expect(!done.contains("/"))
    }
}
