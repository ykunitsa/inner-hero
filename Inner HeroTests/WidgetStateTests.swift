import Foundation
import Testing

@testable import Inner_Hero

/// §11.7 / spec §9 — the hard priority, and the arithmetic that keeps a widget
/// truthful for days without the app being opened.
@Suite("Widget state")
struct WidgetStateTests {

    private static func calendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        calendar.firstWeekday = 2
        return calendar
    }

    /// Friday, 24 July 2026, 10:00 UTC.
    private static let now = calendar().date(
        from: DateComponents(year: 2026, month: 7, day: 24, hour: 10)
    )!

    private static func item(
        _ exercise: ScheduledExercise,
        hour: Int,
        minute: Int = 0,
        recurrence: ScheduleRecurrence = .weekly,
        weekdays: [Int] = [],
        monthDay: Int = 1,
        onceDate: Date? = nil
    ) -> WidgetSnapshot.Item {
        WidgetSnapshot.Item(
            exerciseRaw: exercise.rawValue,
            timeText: "\(hour):00",
            hour: hour,
            minute: minute,
            recurrenceRaw: recurrence.rawValue,
            weekdays: weekdays,
            monthDay: monthDay,
            onceDate: onceDate
        )
    }

    // MARK: Priority (spec §9)

    @Test("An open tail outranks everything")
    func tailWins() {
        let snapshot = WidgetSnapshot(
            openTailTitle: "Walk to the park",
            items: [Self.item(.breathing, hour: 18)]
        )
        let state = WidgetState.resolve(snapshot: snapshot, now: Self.now, calendar: Self.calendar())

        #expect(state == .tail(title: "Walk to the park"))
        #expect(state.deepLink == .exercise(.activation))
    }

    @Test("With no tail, the schedule shows")
    func scheduleIsSecond() {
        let snapshot = WidgetSnapshot(items: [Self.item(.breathing, hour: 18)])
        let state = WidgetState.resolve(snapshot: snapshot, now: Self.now, calendar: Self.calendar())

        #expect(state == .scheduled(exercise: .breathing, meta: "18:00"))
        #expect(state.deepLink == .exercise(.breathing))
    }

    @Test("With nothing waiting, the exposure entry shows")
    func exposureIsTheFallback() {
        let state = WidgetState.resolve(
            snapshot: WidgetSnapshot(), now: Self.now, calendar: Self.calendar()
        )

        #expect(state == .logExposure)
        #expect(state.deepLink == .logExposure)
    }

    @Test("A widget added before the app was ever opened still says something true")
    func emptySnapshotIsUsable() {
        let state = WidgetState.resolve(
            snapshot: .empty, now: Self.now, calendar: Self.calendar()
        )

        #expect(state == .logExposure)
    }

    @Test("A tail with an empty title is not a tail")
    func blankTailIsIgnored() {
        let snapshot = WidgetSnapshot(openTailTitle: "", items: [Self.item(.breathing, hour: 18)])
        let state = WidgetState.resolve(snapshot: snapshot, now: Self.now, calendar: Self.calendar())

        #expect(state == .scheduled(exercise: .breathing, meta: "18:00"))
    }

    // MARK: What is next

    @Test("The soonest entry wins, not the first in the list")
    func soonestWins() {
        let snapshot = WidgetSnapshot(items: [
            Self.item(.relaxation, hour: 21),
            Self.item(.breathing, hour: 12),
        ])
        let next = WidgetState.nextUp(in: snapshot, now: Self.now, calendar: Self.calendar())

        #expect(next?.exercise == .breathing)
    }

    @Test("An entry whose time has passed today gives way to the next one")
    func passedTimesAreSkipped() {
        let snapshot = WidgetSnapshot(items: [
            Self.item(.breathing, hour: 7),
            Self.item(.relaxation, hour: 21),
        ])
        let next = WidgetState.nextUp(in: snapshot, now: Self.now, calendar: Self.calendar())

        #expect(next?.exercise == .relaxation)
    }

    @Test("Tomorrow's entry is labelled, so a time alone never means the wrong day")
    func tomorrowIsLabelled() {
        // Today's 7:00 has passed; the next occurrence is tomorrow at 7:00.
        let snapshot = WidgetSnapshot(items: [Self.item(.breathing, hour: 7)])
        let state = WidgetState.resolve(snapshot: snapshot, now: Self.now, calendar: Self.calendar())

        // Built from the localized token rather than a literal: the test host runs
        // in Russian, and the assertion is about the label being present, not about
        // its language.
        let expected = WidgetState.joined([String(localized: "Tomorrow"), "7:00"])
        #expect(state == .scheduled(exercise: .breathing, meta: expected))
    }

    @Test("Nothing within a day is nothing to announce")
    func beyondTheHorizonIsSilence() {
        // Monthly on the 1st: three days after the mocked now.
        let snapshot = WidgetSnapshot(items: [
            Self.item(.relaxation, hour: 9, recurrence: .monthly, monthDay: 1)
        ])
        let state = WidgetState.resolve(snapshot: snapshot, now: Self.now, calendar: Self.calendar())

        #expect(state == .logExposure)
    }

    @Test("The ladder position joins the time when there is one")
    func ladderPositionIsAppended() {
        let snapshot = WidgetSnapshot(
            items: [Self.item(.breathing, hour: 18)],
            subtitles: [ScheduledExercise.breathing.rawValue: "Box · 10 min"]
        )
        let state = WidgetState.resolve(snapshot: snapshot, now: Self.now, calendar: Self.calendar())

        #expect(state == .scheduled(exercise: .breathing, meta: "18:00 · Box · 10 min"))
    }

    @Test("A weekday subset only fires on its own days")
    func weekdaySubset() {
        // Sunday and Monday only; the mocked now is a Friday, so the next is Sunday —
        // beyond the 24-hour horizon.
        let snapshot = WidgetSnapshot(items: [
            Self.item(.breathing, hour: 9, weekdays: [1, 2])
        ])
        let state = WidgetState.resolve(snapshot: snapshot, now: Self.now, calendar: Self.calendar())

        #expect(state == .logExposure)
    }

    @Test("A one-off that has already happened is not next")
    func spentOneOff() {
        let yesterday = Self.calendar().date(byAdding: .day, value: -1, to: Self.now)!
        let snapshot = WidgetSnapshot(items: [
            Self.item(.exposure, hour: 15, recurrence: .once, onceDate: yesterday)
        ])
        let state = WidgetState.resolve(snapshot: snapshot, now: Self.now, calendar: Self.calendar())

        #expect(state == .logExposure)
    }

    // MARK: Refresh points

    @Test("The widget wakes at midnight, so the day rolls without the app")
    func midnightIsARefreshPoint() {
        let dates = WidgetState.refreshDates(
            snapshot: WidgetSnapshot(), now: Self.now, calendar: Self.calendar()
        )
        let midnight = Self.calendar().date(
            from: DateComponents(year: 2026, month: 7, day: 25)
        )!

        #expect(dates == [midnight])
    }

    @Test("Every scheduled time is a refresh point, in order")
    func scheduledTimesAreRefreshPoints() {
        let snapshot = WidgetSnapshot(items: [
            Self.item(.relaxation, hour: 21),
            Self.item(.breathing, hour: 12),
        ])
        let dates = WidgetState.refreshDates(
            snapshot: snapshot, now: Self.now, calendar: Self.calendar()
        )

        #expect(dates == dates.sorted())
        #expect(dates.allSatisfy { $0 > Self.now })
        // 12:00 and 21:00 today, midnight, then both again tomorrow.
        #expect(dates.count == 5)
    }

    // MARK: Presentation

    @Test("The states carry their own copy and the tail carries the activity's name")
    func copyIsWiredUp() {
        // Compared against the localized tokens, not English literals — the host
        // runs in Russian. The tone check (no praise, no urging) lives in
        // /design-review; here we assert the wiring.
        #expect(WidgetState.logExposure.subtitle == String(localized: "If it happened"))
        #expect(WidgetState.tail(title: "Walk").subtitle == String(localized: "Did it happen?"))
        #expect(WidgetState.tail(title: "Walk").title == "Walk")
    }
}
