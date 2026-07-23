import Foundation

// MARK: - Recurrence

/// How a schedule entry repeats (`docs/plans/11.6d-schedule.md`, decision 4).
///
/// Three kinds, not the Reminders app's four: yearly has no meaning here, since
/// neither practice nor therapy homework arrives once a year, and every extra kind
/// multiplies the editor's states, the "what falls on today" logic and the
/// notification triggers.
nonisolated enum ScheduleRecurrence: String, CaseIterable, Identifiable {
    // Persisted rawValues — never rename (CLAUDE.md).
    case once
    case weekly
    case monthly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .once: String(localized: "Once")
        case .weekly: String(localized: "Days")
        case .monthly: String(localized: "Monthly")
        }
    }
}

// MARK: - The rule

/// When a schedule entry falls, as pure arithmetic over plain values.
///
/// Split out of `ScheduleItem` for two reasons. The old one: every boundary is
/// testable without building a store. The new one (§11.7): the widget has to answer
/// "what is next" days after the app was last opened, so it needs this rule — and
/// it must get it without the `@Model`, the schema and SwiftData coming along.
///
/// `ScheduleItem` delegates here and owns no occurrence logic of its own.
nonisolated enum ScheduleRecurrenceRule {

    /// Does an entry with these fields fall on the given day?
    ///
    /// Monthly deliberately has **no fallback** for the 29th–31st: a month without
    /// that day simply does not fire. `UNCalendarNotificationTrigger` behaves
    /// exactly this way, and a cleverer rule here would make the day list disagree
    /// with when the notification actually arrives.
    static func occurs(
        recurrence: ScheduleRecurrence,
        weekdays: [Int],
        monthDay: Int,
        onceDate: Date?,
        on date: Date,
        calendar: Calendar = .current
    ) -> Bool {
        switch recurrence {
        case .once:
            guard let onceDate else { return false }
            return calendar.isDate(onceDate, inSameDayAs: date)
        case .weekly:
            guard !weekdays.isEmpty else { return true }
            return weekdays.contains(calendar.component(.weekday, from: date))
        case .monthly:
            return calendar.component(.day, from: date) == monthDay
        }
    }

    /// A one-off entry whose day is behind us.
    ///
    /// Spent entries are removed rather than kept as "past" (plan decision 6):
    /// a list of things planned and not done is exactly the reproach material
    /// principle 1.4 forbids. What actually happened lives in History; the
    /// schedule is not a log.
    static func isSpent(
        recurrence: ScheduleRecurrence?,
        onceDate: Date?,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> Bool {
        guard recurrence == .once, let onceDate else { return false }
        return calendar.startOfDay(for: onceDate) < calendar.startOfDay(for: now)
    }

    /// The first moment strictly after `date` when this entry fires, searched over
    /// `withinDays` days.
    ///
    /// A bounded search rather than closed-form arithmetic: the closed form for
    /// "monthly on the 31st" is exactly the kind of calendar cleverness that
    /// disagrees with `UNCalendarNotificationTrigger` in February. Walking the days
    /// and asking `occurs` cannot disagree with the day list, because it *is* the
    /// day list.
    static func nextOccurrence(
        recurrence: ScheduleRecurrence,
        weekdays: [Int],
        monthDay: Int,
        onceDate: Date?,
        hour: Int,
        minute: Int,
        after date: Date,
        withinDays: Int = 2,
        calendar: Calendar = .current
    ) -> Date? {
        for offset in 0...max(withinDays, 0) {
            guard
                let day = calendar.date(byAdding: .day, value: offset, to: date),
                occurs(
                    recurrence: recurrence, weekdays: weekdays, monthDay: monthDay,
                    onceDate: onceDate, on: day, calendar: calendar
                ),
                let fireDate = calendar.date(
                    bySettingHour: hour, minute: minute, second: 0, of: day
                ),
                fireDate > date
            else { continue }
            return fireDate
        }
        return nil
    }
}
