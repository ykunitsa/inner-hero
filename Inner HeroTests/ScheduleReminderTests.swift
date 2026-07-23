import Foundation
import Testing

@testable import Inner_Hero

/// §11.6d2 — what the schedule asks the system to hold.
///
/// The planner is pure on purpose: `UNUserNotificationCenter` does not exist in a
/// unit test, so "what does a monthly entry on the 31st turn into" would otherwise
/// be unassertable.
@Suite("Schedule reminders")
struct ScheduleReminderTests {

    private static func calendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        calendar.firstWeekday = 2
        return calendar
    }

    private static func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar().date(from: DateComponents(year: year, month: month, day: day))!
    }

    private static let now = date(2026, 7, 24)

    @Test("A daily entry costs one request, not seven")
    func dailyIsOneRequest() {
        let item = ScheduleItem(
            exercise: .breathing, recurrence: .weekly, hour: 18, minute: 0,
            weekdays: Array(1...7)
        )
        let request = ScheduleReminderService.request(for: item, now: Self.now, calendar: Self.calendar())

        #expect(request?.trigger == .daily(hour: 18, minute: 0))
        #expect(request?.trigger.systemRequestCount == 1)
    }

    @Test("An empty weekday set is daily too")
    func emptyWeekdaysIsDaily() {
        let item = ScheduleItem(exercise: .breathing, recurrence: .weekly, hour: 7, minute: 30)
        let request = ScheduleReminderService.request(for: item, now: Self.now, calendar: Self.calendar())

        #expect(request?.trigger == .daily(hour: 7, minute: 30))
    }

    @Test("A weekday subset costs one request per day")
    func weeklySubset() {
        let item = ScheduleItem(
            exercise: .relaxation, recurrence: .weekly, hour: 21, minute: 30,
            weekdays: [6, 2, 4]
        )
        let request = ScheduleReminderService.request(for: item, now: Self.now, calendar: Self.calendar())

        #expect(request?.trigger == .weekly(weekdays: [2, 4, 6], hour: 21, minute: 30))
        #expect(request?.trigger.systemRequestCount == 3)
    }

    @Test("A monthly entry keeps its day number")
    func monthly() {
        let item = ScheduleItem(
            exercise: .relaxation, recurrence: .monthly, hour: 9, minute: 0, monthDay: 31
        )
        let request = ScheduleReminderService.request(for: item, now: Self.now, calendar: Self.calendar())

        #expect(request?.trigger == .monthly(day: 31, hour: 9, minute: 0))
        #expect(request?.trigger.systemRequestCount == 1)
    }

    @Test("A one-off fires at its own day and time")
    func onceFiresAtItsMoment() {
        let calendar = Self.calendar()
        let item = ScheduleItem(
            exercise: .exposure, recurrence: .once, hour: 19, minute: 0,
            onceDate: Self.date(2026, 7, 25)
        )
        let request = ScheduleReminderService.request(for: item, now: Self.now, calendar: calendar)

        let expected = calendar.date(from: DateComponents(
            year: 2026, month: 7, day: 25, hour: 19, minute: 0
        ))!
        #expect(request?.trigger == .once(expected))
    }

    @Test("A one-off whose moment has passed schedules nothing")
    func pastOnceIsNotScheduled() {
        let calendar = Self.calendar()
        let noon = calendar.date(byAdding: .hour, value: 12, to: Self.now)!

        let earlierToday = ScheduleItem(
            exercise: .exposure, recurrence: .once, hour: 9, minute: 0,
            onceDate: Self.now
        )
        let laterToday = ScheduleItem(
            exercise: .exposure, recurrence: .once, hour: 19, minute: 0,
            onceDate: Self.now
        )

        #expect(ScheduleReminderService.request(for: earlierToday, now: noon, calendar: calendar) == nil)
        #expect(ScheduleReminderService.request(for: laterToday, now: noon, calendar: calendar) != nil)
    }

    @Test("A disabled entry schedules nothing")
    func disabledSchedulesNothing() {
        let item = ScheduleItem(
            exercise: .breathing, recurrence: .weekly, hour: 18, minute: 0, isEnabled: false
        )
        #expect(ScheduleReminderService.request(for: item, now: Self.now, calendar: Self.calendar()) == nil)
    }

    /// Decision 19: the BA tail and the exposure end-signal share this queue, so a
    /// re-sync has to be able to pick out exactly the schedule's own requests.
    @Test("Every identifier carries the schedule prefix and survives a re-sync")
    func identifiersArePrefixedAndStable() {
        let items = [
            ScheduleItem(exercise: .breathing, recurrence: .weekly, hour: 18, minute: 0),
            ScheduleItem(exercise: .relaxation, recurrence: .monthly, hour: 21, minute: 30, monthDay: 14),
        ]
        let first = ScheduleReminderService.requests(for: items, now: Self.now, calendar: Self.calendar())
        let second = ScheduleReminderService.requests(for: items, now: Self.now, calendar: Self.calendar())

        #expect(first.count == 2)
        let allPrefixed = first.allSatisfy { $0.id.hasPrefix(ScheduleItem.reminderPrefix) }
        #expect(allPrefixed)
        #expect(first.map(\.id) == second.map(\.id))
        #expect(Set(first.map(\.id)).count == 2, "two entries must not share an identifier")
    }

    @Test("The title names the exercise and the body does not urge")
    func content() {
        let item = ScheduleItem(exercise: .relaxation, recurrence: .weekly, hour: 21, minute: 30)
        let request = ScheduleReminderService.request(for: item, now: Self.now, calendar: Self.calendar())

        #expect(request?.title == ScheduledExercise.relaxation.title)
        #expect(request?.body == String(localized: "On your schedule"))
    }

    @Test("Disabled entries drop out of the batch, the rest keep their order")
    func batchSkipsDisabled() {
        let items = [
            ScheduleItem(exercise: .breathing, recurrence: .weekly, hour: 7, minute: 0),
            ScheduleItem(exercise: .relaxation, recurrence: .weekly, hour: 21, minute: 0, isEnabled: false),
            ScheduleItem(exercise: .activation, recurrence: .monthly, hour: 10, minute: 0, monthDay: 1),
        ]
        let requests = ScheduleReminderService.requests(for: items, now: Self.now, calendar: Self.calendar())

        #expect(requests.count == 2)
        #expect(requests.map(\.title) == [
            ScheduledExercise.breathing.title,
            ScheduledExercise.activation.title,
        ])
    }
}
