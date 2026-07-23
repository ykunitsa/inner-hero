import Foundation

/// The one thing the "Today" widget shows, and the hard priority behind it
/// (spec §9).
///
/// Pure and free of WidgetKit so the priority can be asserted in a unit test — the
/// same split as `ScheduleReminderService`: decide here, render outside.
///
/// The order is the spec's and is not negotiable at the view layer: an open tail
/// outranks the schedule, the schedule outranks the exposure button. Everything the
/// widget draws is derived from this value, which is why there is no way for the
/// small and medium layouts to disagree about what is showing.
nonisolated enum WidgetState: Equatable, Sendable {
    /// An open BA activity is waiting for its answer (spec §6).
    case tail(title: String)
    /// The next thing on the schedule, within the next day.
    case scheduled(exercise: ScheduledExercise, meta: String)
    /// Nothing is waiting — the entry that is always available (spec §2.1).
    case logExposure

    // MARK: Resolution

    static func resolve(
        snapshot: WidgetSnapshot,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> WidgetState {
        if let title = snapshot.openTailTitle, !title.isEmpty {
            return .tail(title: title)
        }
        if let next = nextUp(in: snapshot, now: now, calendar: calendar) {
            return .scheduled(exercise: next.exercise, meta: next.meta)
        }
        return .logExposure
    }

    /// The soonest entry that has not fired yet, and the line describing it.
    ///
    /// Bounded to the next 24 hours. Beyond that the honest answer is "nothing is
    /// waiting": a widget announcing Thursday's session on Monday is not telling
    /// the user what to do now, it is filling space.
    static func nextUp(
        in snapshot: WidgetSnapshot,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> (exercise: ScheduledExercise, meta: String, date: Date)? {
        let horizon = now.addingTimeInterval(24 * 60 * 60)

        let candidates: [(exercise: ScheduledExercise, item: WidgetSnapshot.Item, date: Date)] =
            snapshot.items.compactMap { item in
                guard
                    let exercise = item.exercise,
                    let recurrence = item.recurrence,
                    let date = ScheduleRecurrenceRule.nextOccurrence(
                        recurrence: recurrence,
                        weekdays: item.weekdays,
                        monthDay: item.monthDay,
                        onceDate: item.onceDate,
                        hour: item.hour,
                        minute: item.minute,
                        after: now,
                        calendar: calendar
                    ),
                    date <= horizon
                else { return nil }
                return (exercise, item, date)
            }

        guard let soonest = candidates.min(by: { $0.date < $1.date }) else { return nil }
        return (
            soonest.exercise,
            meta(
                timeText: soonest.item.timeText,
                // The ladder position is stored once, under the exercise, and read
                // from there by both the "Today" widget and the exercise's own tile.
                detail: snapshot.subtitle(for: soonest.exercise),
                at: soonest.date,
                now: now,
                calendar: calendar
            ),
            soonest.date
        )
    }

    /// "18:00 · Box · 10 min", or "Tomorrow · 9:00" when the day has turned.
    ///
    /// The exercise's name is not in here: it is the title above. Same split as the
    /// rows on Today, so one event never reads as two different things.
    static func meta(
        timeText: String,
        detail: String?,
        at date: Date,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> String {
        var parts: [String] = []
        if !calendar.isDate(date, inSameDayAs: now) {
            parts.append(String(localized: "Tomorrow"))
        }
        parts.append(timeText)
        if let detail, !detail.isEmpty {
            parts.append(detail)
        }
        return joined(parts)
    }

    /// Folds parts with the separator the rest of the app already uses, rather than
    /// introducing a second one.
    static func joined(_ parts: [String]) -> String {
        guard var result = parts.first else { return "" }
        for part in parts.dropFirst() {
            result = String(format: String(localized: "%1$@ · %2$@"), result, part)
        }
        return result
    }

    // MARK: Presentation

    var title: String {
        switch self {
        case .tail(let title): title
        case .scheduled(let exercise, _): exercise.title
        case .logExposure: String(localized: "Log an exposure")
        }
    }

    var subtitle: String {
        switch self {
        case .tail: String(localized: "Did it happen?")
        case .scheduled(_, let meta): meta
        case .logExposure: String(localized: "If it happened")
        }
    }

    var icon: String {
        switch self {
        case .tail: ScheduledExercise.activation.icon
        case .scheduled(let exercise, _): exercise.icon
        case .logExposure: "pencil"
        }
    }

    var deepLink: DeepLink {
        switch self {
        case .tail: .exercise(.activation)
        case .scheduled(let exercise, _): .exercise(exercise)
        case .logExposure: .logExposure
        }
    }

    // MARK: Timeline

    /// When the widget has to be redrawn: every moment something on it changes.
    ///
    /// Two kinds of moment, and nothing else. A scheduled time passing moves the
    /// "next up" along; midnight turns "Tomorrow" into a time and rolls the day.
    /// No polling interval — a widget that refreshes on a timer to show the same
    /// text is spending the system's budget to say nothing.
    static func refreshDates(
        snapshot: WidgetSnapshot,
        now: Date = Date(),
        calendar: Calendar = .current,
        limit: Int = 12
    ) -> [Date] {
        var dates: Set<Date> = []

        for item in snapshot.items {
            guard let recurrence = item.recurrence else { continue }
            var cursor = now
            // Two per entry is enough: the next one, and the one that takes its
            // place. Further out, another entry's date arrives first anyway.
            for _ in 0..<2 {
                guard let date = ScheduleRecurrenceRule.nextOccurrence(
                    recurrence: recurrence,
                    weekdays: item.weekdays,
                    monthDay: item.monthDay,
                    onceDate: item.onceDate,
                    hour: item.hour,
                    minute: item.minute,
                    after: cursor,
                    calendar: calendar
                ) else { break }
                dates.insert(date)
                cursor = date
            }
        }

        if let midnight = calendar.date(
            byAdding: .day, value: 1, to: calendar.startOfDay(for: now)
        ) {
            dates.insert(midnight)
        }

        return dates.filter { $0 > now }.sorted().prefix(limit).map { $0 }
    }
}
