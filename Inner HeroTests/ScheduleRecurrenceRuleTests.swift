import Foundation
import Testing

@testable import Inner_Hero

/// §11.7 — "when does this fire next", the question the widget has to answer without
/// the app.
///
/// `occurs` and `isSpent` keep their coverage in `ScheduleTests`, which still calls
/// them through `ScheduleItem`: that the extraction changed nothing is the point of
/// leaving those tests where they are.
@Suite("Schedule recurrence rule")
struct ScheduleRecurrenceRuleTests {

    private static func calendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        calendar.firstWeekday = 2
        return calendar
    }

    private static func date(
        _ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0, _ minute: Int = 0
    ) -> Date {
        calendar().date(
            from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute)
        )!
    }

    /// Friday, 24 July 2026, 10:00.
    private static let now = date(2026, 7, 24, 10)

    @Test("Later today comes before tomorrow")
    func laterToday() {
        let next = ScheduleRecurrenceRule.nextOccurrence(
            recurrence: .weekly, weekdays: [], monthDay: 1, onceDate: nil,
            hour: 18, minute: 0, after: Self.now, calendar: Self.calendar()
        )

        #expect(next == Self.date(2026, 7, 24, 18))
    }

    @Test("A time already past today lands on tomorrow, not on itself")
    func pastTimeRollsOver() {
        let next = ScheduleRecurrenceRule.nextOccurrence(
            recurrence: .weekly, weekdays: [], monthDay: 1, onceDate: nil,
            hour: 7, minute: 0, after: Self.now, calendar: Self.calendar()
        )

        #expect(next == Self.date(2026, 7, 25, 7))
    }

    @Test("The exact current minute is behind us, not ahead")
    func theCurrentMomentIsNotNext() {
        let next = ScheduleRecurrenceRule.nextOccurrence(
            recurrence: .weekly, weekdays: [], monthDay: 1, onceDate: nil,
            hour: 10, minute: 0, after: Self.now, calendar: Self.calendar()
        )

        #expect(next == Self.date(2026, 7, 25, 10))
    }

    @Test("A weekday subset skips the days it does not name")
    func weekdaySubset() {
        // Saturday (7) only; the search reaches it one day out.
        let next = ScheduleRecurrenceRule.nextOccurrence(
            recurrence: .weekly, weekdays: [7], monthDay: 1, onceDate: nil,
            hour: 9, minute: 0, after: Self.now, calendar: Self.calendar()
        )

        #expect(next == Self.date(2026, 7, 25, 9))
    }

    @Test("A month without the 31st is skipped rather than moved — same as the reminder")
    func monthlyDoesNotFallBack() {
        // From 27 February 2027, a monthly-on-the-31st entry does not fire in
        // February at all. Nothing within the search window, and no 28th invented.
        let next = ScheduleRecurrenceRule.nextOccurrence(
            recurrence: .monthly, weekdays: [], monthDay: 31, onceDate: nil,
            hour: 9, minute: 0, after: Self.date(2027, 2, 27), calendar: Self.calendar()
        )

        #expect(next == nil)
    }

    @Test("A one-off fires once and never again")
    func oneOff() {
        let day = Self.date(2026, 7, 25)
        let calendar = Self.calendar()

        #expect(
            ScheduleRecurrenceRule.nextOccurrence(
                recurrence: .once, weekdays: [], monthDay: 1, onceDate: day,
                hour: 9, minute: 0, after: Self.now, calendar: calendar
            ) == Self.date(2026, 7, 25, 9)
        )
        #expect(
            ScheduleRecurrenceRule.nextOccurrence(
                recurrence: .once, weekdays: [], monthDay: 1, onceDate: day,
                hour: 9, minute: 0, after: Self.date(2026, 7, 25, 10), calendar: calendar
            ) == nil
        )
    }

    @Test("The search window is honoured rather than run away with")
    func boundedSearch() {
        // Sunday is two days out; a one-day window must not find it.
        let next = ScheduleRecurrenceRule.nextOccurrence(
            recurrence: .weekly, weekdays: [1], monthDay: 1, onceDate: nil,
            hour: 9, minute: 0, after: Self.now, withinDays: 1, calendar: Self.calendar()
        )

        #expect(next == nil)
    }
}
