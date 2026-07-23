import Foundation
import SwiftData
import Testing

@testable import Inner_Hero

/// §11.6d1 — the schedule model and the tab's view model.
///
/// Every boundary that depends on the date is driven through injected `now:` /
/// `calendar:`, so nothing here waits for a weekday or a month to come round.
@Suite("Schedule")
struct ScheduleTests {

    /// UTC and a fixed first weekday: a test that silently changes meaning in
    /// another region is worse than no test.
    private static func calendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        calendar.firstWeekday = 2 // Monday
        return calendar
    }

    private static func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar().date(from: DateComponents(year: year, month: month, day: day))!
    }

    // MARK: - Occurrence

    @Test("A one-off entry falls only on its own day")
    func onceOccursOnItsDay() {
        let calendar = Self.calendar()
        let day = Self.date(2026, 7, 24)

        #expect(ScheduleItem.occurs(
            recurrence: .once, weekdays: [], monthDay: 1, onceDate: day,
            on: day, calendar: calendar
        ))
        #expect(!ScheduleItem.occurs(
            recurrence: .once, weekdays: [], monthDay: 1, onceDate: day,
            on: Self.date(2026, 7, 25), calendar: calendar
        ))
        #expect(!ScheduleItem.occurs(
            recurrence: .once, weekdays: [], monthDay: 1, onceDate: day,
            on: Self.date(2026, 7, 23), calendar: calendar
        ))
    }

    @Test("A weekly entry falls on its weekdays")
    func weeklyOccursOnSelectedWeekdays() {
        let calendar = Self.calendar()
        // 2026-07-24 is a Friday (weekday 6), 2026-07-25 a Saturday (7).
        let friday = Self.date(2026, 7, 24)
        let saturday = Self.date(2026, 7, 25)

        #expect(ScheduleItem.occurs(
            recurrence: .weekly, weekdays: [6], monthDay: 1, onceDate: nil,
            on: friday, calendar: calendar
        ))
        #expect(!ScheduleItem.occurs(
            recurrence: .weekly, weekdays: [6], monthDay: 1, onceDate: nil,
            on: saturday, calendar: calendar
        ))
    }

    @Test("An empty weekday set means every day")
    func emptyWeekdaysMeansDaily() {
        let calendar = Self.calendar()
        for day in 20...26 {
            #expect(ScheduleItem.occurs(
                recurrence: .weekly, weekdays: [], monthDay: 1, onceDate: nil,
                on: Self.date(2026, 7, day), calendar: calendar
            ))
        }
    }

    @Test("Sunday is weekday 1, the boundary Calendar counts from")
    func sundayBoundary() {
        let calendar = Self.calendar()
        let sunday = Self.date(2026, 7, 26)
        #expect(calendar.component(.weekday, from: sunday) == 1)
        #expect(ScheduleItem.occurs(
            recurrence: .weekly, weekdays: [1], monthDay: 1, onceDate: nil,
            on: sunday, calendar: calendar
        ))
    }

    @Test("A monthly entry falls on its day number")
    func monthlyOccursOnItsDay() {
        let calendar = Self.calendar()
        #expect(ScheduleItem.occurs(
            recurrence: .monthly, weekdays: [], monthDay: 14, onceDate: nil,
            on: Self.date(2026, 7, 14), calendar: calendar
        ))
        #expect(ScheduleItem.occurs(
            recurrence: .monthly, weekdays: [], monthDay: 14, onceDate: nil,
            on: Self.date(2026, 8, 14), calendar: calendar
        ))
        #expect(!ScheduleItem.occurs(
            recurrence: .monthly, weekdays: [], monthDay: 14, onceDate: nil,
            on: Self.date(2026, 7, 15), calendar: calendar
        ))
    }

    /// Plan decision 7: no fallback to the last day of the month. The list has to
    /// agree with `UNCalendarNotificationTrigger`, which simply skips.
    @Test("The 31st skips months that do not have one")
    func monthlySkipsShortMonths() {
        let calendar = Self.calendar()
        for day in 1...28 {
            #expect(!ScheduleItem.occurs(
                recurrence: .monthly, weekdays: [], monthDay: 31, onceDate: nil,
                on: Self.date(2026, 2, day), calendar: calendar
            ))
        }
        #expect(ScheduleItem.occurs(
            recurrence: .monthly, weekdays: [], monthDay: 31, onceDate: nil,
            on: Self.date(2026, 3, 31), calendar: calendar
        ))
    }

    @Test("February 29 fires in a leap year and never in a common one")
    func februaryTwentyNinth() {
        let calendar = Self.calendar()
        #expect(ScheduleItem.occurs(
            recurrence: .monthly, weekdays: [], monthDay: 29, onceDate: nil,
            on: Self.date(2028, 2, 29), calendar: calendar
        ))
        for day in 1...28 {
            #expect(!ScheduleItem.occurs(
                recurrence: .monthly, weekdays: [], monthDay: 29, onceDate: nil,
                on: Self.date(2026, 2, day), calendar: calendar
            ))
        }
    }

    @Test("A disabled entry falls on no day at all")
    func disabledOccursNowhere() {
        let calendar = Self.calendar()
        let item = ScheduleItem(
            exercise: .breathing, recurrence: .weekly, hour: 18, minute: 0,
            weekdays: [], isEnabled: false
        )
        #expect(!item.occurs(on: Self.date(2026, 7, 24), calendar: calendar))

        item.isEnabled = true
        #expect(item.occurs(on: Self.date(2026, 7, 24), calendar: calendar))
    }

    // MARK: - Spent one-offs

    @Test("A one-off is spent the day after, and not before")
    func spentOneOff() {
        let calendar = Self.calendar()
        let item = ScheduleItem(
            exercise: .exposure, recurrence: .once, hour: 19, minute: 0,
            onceDate: Self.date(2026, 7, 24)
        )

        #expect(!item.isSpent(now: Self.date(2026, 7, 23), calendar: calendar))
        // Still on its own day, right up to midnight.
        #expect(!item.isSpent(
            now: calendar.date(byAdding: .hour, value: 23, to: Self.date(2026, 7, 24))!,
            calendar: calendar
        ))
        #expect(item.isSpent(now: Self.date(2026, 7, 25), calendar: calendar))
    }

    @Test("Repeating entries are never spent")
    func repeatingNeverSpent() {
        let calendar = Self.calendar()
        let weekly = ScheduleItem(
            exercise: .breathing, recurrence: .weekly, hour: 18, minute: 0
        )
        let monthly = ScheduleItem(
            exercise: .relaxation, recurrence: .monthly, hour: 21, minute: 30, monthDay: 14
        )

        #expect(!weekly.isSpent(now: Self.date(2030, 1, 1), calendar: calendar))
        #expect(!monthly.isSpent(now: Self.date(2030, 1, 1), calendar: calendar))
    }

    // MARK: - Storage

    @MainActor
    @Test("Saving inserts one entry and editing updates it in place")
    func saveAndEdit() throws {
        let calendar = Self.calendar()
        let container = try ModelContainer(
            for: ScheduleItem.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext
        let viewModel = ScheduleViewModel()
        let now = Self.date(2026, 7, 24)

        viewModel.beginAdd(now: now, calendar: calendar)
        viewModel.draftExercise = .relaxation
        viewModel.draftRecurrence = .weekly
        viewModel.draftTime = ScheduleViewModel.time(hour: 21, minute: 30, now: now, calendar: calendar)
        viewModel.draftWeekdays = [2, 4, 6]
        try viewModel.save(in: context, now: now, calendar: calendar)

        var stored = try context.fetch(FetchDescriptor<ScheduleItem>())
        #expect(stored.count == 1)
        #expect(stored.first?.exercise == .relaxation)
        #expect(stored.first?.hour == 21)
        #expect(stored.first?.minute == 30)
        #expect(stored.first?.weekdays == [2, 4, 6])

        let item = try #require(stored.first)
        viewModel.beginEdit(item, now: now, calendar: calendar)
        viewModel.draftTime = ScheduleViewModel.time(hour: 7, minute: 0, now: now, calendar: calendar)
        try viewModel.save(in: context, now: now, calendar: calendar)

        stored = try context.fetch(FetchDescriptor<ScheduleItem>())
        #expect(stored.count == 1, "editing must not create a second entry")
        #expect(stored.first?.hour == 7)
    }

    @MainActor
    @Test("Several entries can share one exercise")
    func severalPerExercise() throws {
        let calendar = Self.calendar()
        let container = try ModelContainer(
            for: ScheduleItem.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext
        let viewModel = ScheduleViewModel()
        let now = Self.date(2026, 7, 24)

        for hour in [7, 21] {
            viewModel.beginAdd(now: now, calendar: calendar)
            viewModel.draftExercise = .relaxation
            viewModel.draftTime = ScheduleViewModel.time(hour: hour, minute: 0, now: now, calendar: calendar)
            try viewModel.save(in: context, now: now, calendar: calendar)
        }

        let stored = try context.fetch(FetchDescriptor<ScheduleItem>())
        #expect(stored.count == 2)
    }

    @MainActor
    @Test("Spent one-offs are removed, today's and tomorrow's are kept")
    func removeSpent() throws {
        let calendar = Self.calendar()
        let container = try ModelContainer(
            for: ScheduleItem.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext
        let now = Self.date(2026, 7, 24)

        let items = [
            ScheduleItem(exercise: .exposure, recurrence: .once, hour: 19, minute: 0,
                         onceDate: Self.date(2026, 7, 23)),
            ScheduleItem(exercise: .exposure, recurrence: .once, hour: 19, minute: 0,
                         onceDate: Self.date(2026, 7, 24)),
            ScheduleItem(exercise: .exposure, recurrence: .once, hour: 19, minute: 0,
                         onceDate: Self.date(2026, 7, 25)),
            ScheduleItem(exercise: .breathing, recurrence: .weekly, hour: 18, minute: 0),
        ]
        for item in items { context.insert(item) }
        try context.save()

        let viewModel = ScheduleViewModel()
        let removed = try viewModel.removeSpent(items, in: context, now: now, calendar: calendar)

        #expect(removed == 1)
        #expect(try context.fetch(FetchDescriptor<ScheduleItem>()).count == 3)
    }

    /// Migration reality, found on a device: CoreData gives every row migrated
    /// into a new attribute the same default value, so entries that predate
    /// `reminderToken` all carry one — and one token means one notification
    /// identifier for several entries.
    @MainActor
    @Test("Entries sharing a reminder token are given fresh ones")
    func healDuplicateTokens() throws {
        let container = try ModelContainer(
            for: ScheduleItem.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext
        let shared = UUID()

        let first = ScheduleItem(
            exercise: .breathing, recurrence: .weekly, hour: 7, minute: 0,
            createdAt: Self.date(2026, 7, 20), reminderToken: shared
        )
        let second = ScheduleItem(
            exercise: .exposure, recurrence: .weekly, hour: 19, minute: 0,
            createdAt: Self.date(2026, 7, 21), reminderToken: shared
        )
        let third = ScheduleItem(
            exercise: .relaxation, recurrence: .weekly, hour: 21, minute: 0,
            createdAt: Self.date(2026, 7, 22), reminderToken: shared
        )
        for item in [first, second, third] { context.insert(item) }
        try context.save()

        let viewModel = ScheduleViewModel()
        let healed = try viewModel.healDuplicateTokens([first, second, third], in: context)

        #expect(healed == 2)
        // The oldest entry keeps the token it had — the fix must not churn
        // identifiers that are already unique.
        #expect(first.reminderToken == shared)
        #expect(Set([first, second, third].map(\.reminderToken)).count == 3)

        #expect(try viewModel.healDuplicateTokens([first, second, third], in: context) == 0)
    }

    // MARK: - Sections and drafts

    @MainActor
    @Test("One-offs come first, each section sorted by its own key")
    func sectionOrder() {
        let viewModel = ScheduleViewModel()
        let early = ScheduleItem(exercise: .breathing, recurrence: .weekly, hour: 7, minute: 0)
        let late = ScheduleItem(exercise: .relaxation, recurrence: .weekly, hour: 21, minute: 30)
        let soon = ScheduleItem(exercise: .exposure, recurrence: .once, hour: 19, minute: 0,
                                onceDate: Self.date(2026, 7, 24))
        let later = ScheduleItem(exercise: .exposure, recurrence: .once, hour: 9, minute: 0,
                                 onceDate: Self.date(2026, 8, 1))

        let sections = viewModel.sections([late, later, early, soon])

        #expect(sections.count == 2)
        #expect(sections[0].section == .once)
        #expect(sections[0].items.map(\.onceDate) == [soon.onceDate, later.onceDate])
        #expect(sections[1].section == .recurring)
        #expect(sections[1].items.map(\.hour) == [7, 21])
    }

    @MainActor
    @Test("A section with nothing in it is not rendered")
    func emptySectionSkipped() {
        let viewModel = ScheduleViewModel()
        let sections = viewModel.sections([
            ScheduleItem(exercise: .breathing, recurrence: .weekly, hour: 18, minute: 0)
        ])
        #expect(sections.count == 1)
        #expect(sections[0].section == .recurring)
    }

    @MainActor
    @Test("The last selected weekday cannot be removed")
    func lastWeekdayStays() {
        let viewModel = ScheduleViewModel()
        viewModel.draftWeekdays = [3]

        viewModel.toggleWeekday(3)
        #expect(viewModel.draftWeekdays == [3], "an empty set would silently mean daily")

        viewModel.toggleWeekday(5)
        #expect(viewModel.draftWeekdays == [3, 5])
        viewModel.toggleWeekday(3)
        #expect(viewModel.draftWeekdays == [5])
    }

    @MainActor
    @Test("A new entry defaults to daily at the next half hour")
    func addDefaults() {
        let calendar = Self.calendar()
        let viewModel = ScheduleViewModel()
        let now = calendar.date(byAdding: .minute, value: 47, to: Self.date(2026, 7, 24))!

        viewModel.beginAdd(now: now, calendar: calendar)

        #expect(viewModel.draftRecurrence == .weekly)
        #expect(viewModel.draftWeekdays == Set(1...7))
        #expect(viewModel.draftMonthDay == 24)
        #expect(calendar.component(.hour, from: viewModel.draftTime) == 1)
        #expect(calendar.component(.minute, from: viewModel.draftTime) == 0)
    }

    @Test("Rounding up lands on the boundary it is already standing on")
    func defaultTimeRounding() {
        let calendar = Self.calendar()
        let midnight = Self.date(2026, 7, 24)

        func rounded(_ minutes: Int) -> (Int, Int) {
            let now = calendar.date(byAdding: .minute, value: minutes, to: midnight)!
            let time = ScheduleViewModel.defaultTime(now: now, calendar: calendar)
            return (
                calendar.component(.hour, from: time),
                calendar.component(.minute, from: time)
            )
        }

        #expect(rounded(0) == (0, 0))
        #expect(rounded(1) == (0, 30))
        #expect(rounded(30) == (0, 30))
        #expect(rounded(31) == (1, 0))
    }

    // MARK: - Text

    @MainActor
    @Test("A full week and an empty set both read as daily")
    func dailyText() {
        let calendar = Self.calendar()
        let daily = String(localized: "Daily")

        #expect(ScheduleViewModel.weekdaysText([], calendar: calendar) == daily)
        #expect(ScheduleViewModel.weekdaysText(Set(1...7), calendar: calendar) == daily)
        #expect(ScheduleViewModel.weekdaysText([2, 4], calendar: calendar) != daily)
    }

    @Test("Weekday order starts where the locale starts the week")
    func weekdayOrderFollowsLocale() {
        var monday = Calendar(identifier: .gregorian)
        monday.firstWeekday = 2
        #expect(ScheduleViewModel.weekdayOrder(calendar: monday) == [2, 3, 4, 5, 6, 7, 1])

        var sunday = Calendar(identifier: .gregorian)
        sunday.firstWeekday = 1
        #expect(ScheduleViewModel.weekdayOrder(calendar: sunday) == [1, 2, 3, 4, 5, 6, 7])
    }

    @MainActor
    @Test("Selected days are listed in the locale's order, not the order tapped")
    func weekdaysTextOrder() {
        let calendar = Self.calendar()
        let symbols = calendar.shortWeekdaySymbols
        // Wednesday (4) and Monday (2), stored in the reverse of reading order.
        let text = ScheduleViewModel.weekdaysText([4, 2], calendar: calendar)
        #expect(text == "\(symbols[1]), \(symbols[3])")
    }

    @MainActor
    @Test("The meta line leads with the date for one-offs and the time otherwise")
    func metaShape() {
        let calendar = Self.calendar()
        let viewModel = ScheduleViewModel()

        let once = ScheduleItem(exercise: .exposure, recurrence: .once, hour: 19, minute: 0,
                                onceDate: Self.date(2026, 7, 24))
        let time = ScheduleViewModel.timeText(hour: 19, minute: 0, calendar: calendar)
        #expect(viewModel.meta(for: once, calendar: calendar).hasSuffix(time))

        let weekly = ScheduleItem(exercise: .breathing, recurrence: .weekly, hour: 18, minute: 0)
        #expect(viewModel.meta(for: weekly, calendar: calendar)
            .hasPrefix(ScheduleViewModel.timeText(hour: 18, minute: 0, calendar: calendar)))
        #expect(viewModel.meta(for: weekly, calendar: calendar)
            .hasSuffix(String(localized: "Daily")))
    }
}
