import Foundation
import Observation
import SwiftData

/// The schedule tab (spec §2.1, §1.10) and the editor sheet behind it.
///
/// Nothing here reads the clock: `now` and `calendar` are injected everywhere, so
/// every weekday and month-day boundary is testable without waiting for the date
/// to come round.
@Observable
@MainActor
final class ScheduleViewModel {

    // MARK: - Sections

    nonisolated enum Section: String, Identifiable {
        case once
        case recurring

        nonisolated var id: String { rawValue }

        var title: String {
            switch self {
            case .once: String(localized: "One-off")
            case .recurring: String(localized: "Repeating")
            }
        }
    }

    /// One-off entries first — they have a deadline, repeating ones do not.
    /// Empty sections are skipped: a header with nothing under it is a label, not
    /// information.
    nonisolated func sections(
        _ items: [ScheduleItem]
    ) -> [(section: Section, items: [ScheduleItem])] {
        let once = items
            .filter { $0.recurrence == .once }
            .sorted {
                ($0.onceDate ?? .distantFuture, $0.minutesOfDay)
                    < ($1.onceDate ?? .distantFuture, $1.minutesOfDay)
            }
        let recurring = items
            .filter { $0.recurrence != .once }
            .sorted { ($0.minutesOfDay, $0.createdAt) < ($1.minutesOfDay, $1.createdAt) }

        return [(Section.once, once), (Section.recurring, recurring)]
            .filter { !$0.1.isEmpty }
    }

    // MARK: - Draft (the editor sheet)

    private(set) var editing: ScheduleItem?

    var draftExercise: ScheduledExercise = .breathing
    var draftRecurrence: ScheduleRecurrence = .weekly
    /// Holder for the time wheel; only its hour and minute are persisted.
    var draftTime: Date = .distantPast
    var draftWeekdays: Set<Int> = Set(1...7)
    var draftMonthDay: Int = 1
    var draftOnceDate: Date = .distantPast

    var isEditing: Bool { editing != nil }

    /// A new entry starts on the most common case — daily practice — with a time
    /// that is merely mechanical. The spec's own examples (breathing at 18:00, PMR
    /// at 21:30) are deliberately *not* used as defaults: a suggested time to
    /// practise is quiet advice, and this app does not advise (§1.1).
    func beginAdd(now: Date = Date(), calendar: Calendar = .current) {
        editing = nil
        draftExercise = .breathing
        draftRecurrence = .weekly
        draftTime = Self.defaultTime(now: now, calendar: calendar)
        draftWeekdays = Set(1...7)
        draftMonthDay = calendar.component(.day, from: now)
        draftOnceDate = calendar.startOfDay(for: now)
    }

    func beginEdit(_ item: ScheduleItem, now: Date = Date(), calendar: Calendar = .current) {
        editing = item
        draftExercise = item.exercise ?? .breathing
        draftRecurrence = item.recurrence ?? .weekly
        draftTime = Self.time(hour: item.hour, minute: item.minute, now: now, calendar: calendar)
        draftWeekdays = item.weekdays.isEmpty ? Set(1...7) : Set(item.weekdays)
        draftMonthDay = item.monthDay
        draftOnceDate = item.onceDate ?? calendar.startOfDay(for: now)
    }

    /// The last selected day cannot be removed: a weekly entry with no days would
    /// silently mean "every day" (the storage convention) — a control that flips
    /// to its opposite when emptied.
    func toggleWeekday(_ weekday: Int) {
        if draftWeekdays.contains(weekday) {
            guard draftWeekdays.count > 1 else { return }
            draftWeekdays.remove(weekday)
        } else {
            draftWeekdays.insert(weekday)
        }
    }

    // MARK: - Persistence

    func save(in context: ModelContext, now: Date = Date(), calendar: Calendar = .current) throws {
        let components = calendar.dateComponents([.hour, .minute], from: draftTime)
        let hour = components.hour ?? 9
        let minute = components.minute ?? 0
        let weekdays = draftRecurrence == .weekly ? draftWeekdays.sorted() : []
        let onceDate = draftRecurrence == .once ? calendar.startOfDay(for: draftOnceDate) : nil
        let monthDay = draftRecurrence == .monthly ? draftMonthDay : 1

        if let editing {
            editing.exerciseRaw = draftExercise.rawValue
            editing.recurrenceRaw = draftRecurrence.rawValue
            editing.hour = hour
            editing.minute = minute
            editing.weekdays = weekdays
            editing.monthDay = monthDay
            editing.onceDate = onceDate
        } else {
            context.insert(
                ScheduleItem(
                    exercise: draftExercise,
                    recurrence: draftRecurrence,
                    hour: hour,
                    minute: minute,
                    weekdays: weekdays,
                    monthDay: monthDay,
                    onceDate: onceDate,
                    createdAt: now
                )
            )
        }
        try context.save()
    }

    func setEnabled(_ isEnabled: Bool, for item: ScheduleItem, in context: ModelContext) throws {
        item.isEnabled = isEnabled
        try context.save()
    }

    func delete(_ item: ScheduleItem, in context: ModelContext) throws {
        context.delete(item)
        try context.save()
    }

    /// Drops one-off entries whose day has passed (plan decision 6). Runs on
    /// opening the tab; silent by design — there is nothing to report about a day
    /// that is simply over.
    @discardableResult
    func removeSpent(
        _ items: [ScheduleItem],
        in context: ModelContext,
        now: Date = Date(),
        calendar: Calendar = .current
    ) throws -> Int {
        let spent = items.filter { $0.isSpent(now: now, calendar: calendar) }
        guard !spent.isEmpty else { return 0 }
        for item in spent {
            context.delete(item)
        }
        try context.save()
        return spent.count
    }

    /// Gives fresh tokens to entries that share one.
    ///
    /// CoreData hands every row migrated into a new attribute the **same** default
    /// value, so entries that predate `reminderToken` all carry an identical one.
    /// A shared token is a shared notification identifier, where the last entry
    /// scheduled silently replaces the others — a reminder that never arrives and
    /// nothing on screen to explain why. Runs once on opening the tab; a no-op
    /// forever after.
    @discardableResult
    func healDuplicateTokens(_ items: [ScheduleItem], in context: ModelContext) throws -> Int {
        var seen: Set<UUID> = []
        var healed = 0

        for item in items.sorted(by: { $0.createdAt < $1.createdAt }) {
            if seen.contains(item.reminderToken) {
                item.reminderToken = UUID()
                healed += 1
            }
            seen.insert(item.reminderToken)
        }

        if healed > 0 { try context.save() }
        return healed
    }

    // MARK: - Text

    /// The row's second line: when this happens, and how often.
    nonisolated func meta(for item: ScheduleItem, calendar: Calendar = .current) -> String {
        let time = Self.timeText(hour: item.hour, minute: item.minute, calendar: calendar)
        guard let recurrence = item.recurrence else { return time }

        switch recurrence {
        case .once:
            guard let date = item.onceDate else { return time }
            // The date leads: for a one-off, *which day* is the thing that has to
            // be read first.
            return String(
                format: String(localized: "%1$@ · %2$@"),
                date.formatted(.dateTime.weekday(.abbreviated).day().month(.wide)),
                time
            )
        case .weekly, .monthly:
            return String(
                format: String(localized: "%1$@ · %2$@"),
                time,
                Self.recurrenceText(for: item, calendar: calendar)
            )
        }
    }

    nonisolated static func recurrenceText(
        for item: ScheduleItem,
        calendar: Calendar = .current
    ) -> String {
        switch item.recurrence {
        case .monthly:
            return String(
                format: String(localized: "day %d", comment: "Monthly recurrence: day 14"),
                item.monthDay
            )
        case .weekly:
            return weekdaysText(Set(item.weekdays), calendar: calendar)
        default:
            return ""
        }
    }

    /// Both the empty set and the full week read as "Daily": the editor always
    /// writes an explicit set, and empty is what an entry that never went through
    /// the editor means.
    nonisolated static func weekdaysText(_ weekdays: Set<Int>, calendar: Calendar = .current) -> String {
        guard !weekdays.isEmpty, weekdays.count < 7 else {
            return String(localized: "Daily")
        }
        let symbols = calendar.shortWeekdaySymbols
        return weekdayOrder(calendar: calendar)
            .filter { weekdays.contains($0) }
            .compactMap { symbols.indices.contains($0 - 1) ? symbols[$0 - 1] : nil }
            .joined(separator: ", ")
    }

    /// 1...7 in `Calendar` semantics, rotated so the week starts where the user's
    /// locale starts it. The stored values never change — only the reading order.
    nonisolated static func weekdayOrder(calendar: Calendar = .current) -> [Int] {
        let first = calendar.firstWeekday
        return (0..<7).map { (first - 1 + $0) % 7 + 1 }
    }

    nonisolated static func shortWeekdaySymbol(_ weekday: Int, calendar: Calendar = .current) -> String {
        let symbols = calendar.shortWeekdaySymbols
        return symbols.indices.contains(weekday - 1) ? symbols[weekday - 1] : ""
    }

    nonisolated static func timeText(hour: Int, minute: Int, calendar: Calendar = .current) -> String {
        let date = time(hour: hour, minute: minute, now: Date(timeIntervalSince1970: 0), calendar: calendar)
        // `.shortened` so a 12-hour locale gets 6:00 PM rather than a forced 18:00.
        return date.formatted(date: .omitted, time: .shortened)
    }

    /// Builds a `Date` carrying the given wall-clock time, for the pickers and the
    /// formatter. The day it lands on is irrelevant — only hour and minute are read
    /// back out.
    nonisolated static func time(
        hour: Int,
        minute: Int,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> Date {
        calendar.date(bySettingHour: hour, minute: minute, second: 0, of: now) ?? now
    }

    /// The current time rounded **up** to the next half hour, seconds dropped.
    /// Mechanical on purpose: a default that looked chosen would be advice about
    /// when to practise (§1.1).
    nonisolated static func defaultTime(now: Date = Date(), calendar: Calendar = .current) -> Date {
        let minute = calendar.component(.minute, from: now)
        let delta = (30 - minute % 30) % 30
        let rounded = calendar.date(byAdding: .minute, value: delta, to: now) ?? now
        let components = calendar.dateComponents([.hour, .minute], from: rounded)
        return time(
            hour: components.hour ?? 0,
            minute: components.minute ?? 0,
            now: now,
            calendar: calendar
        )
    }
}
