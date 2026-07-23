import Foundation
import UserNotifications

/// One reminder the schedule wants the system to hold.
///
/// A description of intent, not a `UNNotificationRequest`: the whole point of the
/// split is that "what a monthly entry on the 31st turns into" can be asserted in a
/// unit test, where `UNUserNotificationCenter` does not exist. The same shape as
/// `ExerciseStatus` — compute in a pure function, perform the effect outside it.
nonisolated struct ScheduleReminderRequest: Equatable, Sendable {

    enum Trigger: Equatable, Sendable {
        /// An exact moment, fired once.
        case once(Date)
        case daily(hour: Int, minute: Int)
        /// A non-empty, sorted subset of 1...7 (`Calendar` semantics). A full week
        /// is `.daily` instead.
        case weekly(weekdays: [Int], hour: Int, minute: Int)
        case monthly(day: Int, hour: Int, minute: Int)

        /// How many of the system's 64 pending slots this trigger occupies.
        /// A repeating request costs one slot no matter how often it fires; a
        /// weekday subset costs one per day, because that is one request each.
        var systemRequestCount: Int {
            switch self {
            case .once, .daily, .monthly: 1
            case .weekly(let weekdays, _, _): weekdays.count
            }
        }
    }

    let id: String
    let title: String
    let body: String
    let trigger: Trigger
    /// Where a tap lands. Part of the request rather than of the delivery step, so
    /// "the 18:00 breathing reminder opens breathing" is a unit test and not a
    /// device run (§11.7).
    let deepLink: DeepLink
}

/// Turns the schedule into local reminders (spec §1.10: scheduling is the shared
/// layer).
///
/// Re-syncing is deliberately dumb: clear everything under the schedule's prefix,
/// lay it all out again. Idempotent, so it can run on every foreground without
/// bookkeeping about what changed — and never accumulates duplicates.
nonisolated enum ScheduleReminderService {

    // MARK: - Planning (pure)

    static func requests(
        for items: [ScheduleItem],
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> [ScheduleReminderRequest] {
        items.compactMap { request(for: $0, now: now, calendar: calendar) }
    }

    static func request(
        for item: ScheduleItem,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> ScheduleReminderRequest? {
        guard item.isEnabled, let exercise = item.exercise, let recurrence = item.recurrence else {
            return nil
        }
        guard let trigger = trigger(for: item, recurrence: recurrence, now: now, calendar: calendar) else {
            return nil
        }

        return ScheduleReminderRequest(
            id: item.reminderID,
            title: exercise.title,
            // States why the notification exists and stops there. Not "time to
            // practise": the person picked this hour, and the app does not urge
            // (§1.1, codex §5).
            body: String(localized: "On your schedule"),
            trigger: trigger,
            deepLink: .exercise(exercise)
        )
    }

    private static func trigger(
        for item: ScheduleItem,
        recurrence: ScheduleRecurrence,
        now: Date,
        calendar: Calendar
    ) -> ScheduleReminderRequest.Trigger? {
        switch recurrence {
        case .once:
            // A one-off whose moment has passed schedules nothing. It is also
            // swept from the list on the next day (decision 6); this guard covers
            // the hours in between, and the case of a time earlier today.
            guard
                let day = item.onceDate,
                let fireDate = calendar.date(
                    bySettingHour: item.hour, minute: item.minute, second: 0, of: day
                ),
                fireDate > now
            else { return nil }
            return .once(fireDate)

        case .weekly:
            let weekdays = Set(item.weekdays).sorted()
            // Empty means every day by storage convention, and a full week means
            // the same thing — both become one request rather than seven.
            guard !weekdays.isEmpty, weekdays.count < 7 else {
                return .daily(hour: item.hour, minute: item.minute)
            }
            return .weekly(weekdays: weekdays, hour: item.hour, minute: item.minute)

        case .monthly:
            return .monthly(day: item.monthDay, hour: item.hour, minute: item.minute)
        }
    }

    // MARK: - Delivery

    /// Clears the schedule's reminders and lays them out again from `items`.
    ///
    /// Silently does nothing past the clearing step when notifications are not
    /// authorised: the day list is the part that has to keep working either way
    /// (decision 8), and this is not the moment to ask — the request belongs to
    /// the screen where a person just set something up.
    @MainActor
    static func sync(
        _ items: [ScheduleItem],
        via manager: NotificationManager,
        now: Date = Date(),
        calendar: Calendar = .current
    ) async {
        await manager.removePendingReminders(withPrefix: ScheduleItem.reminderPrefix)
        guard await manager.checkAuthorizationStatus() == .authorized else { return }

        for request in requests(for: items, now: now, calendar: calendar) {
            switch request.trigger {
            case .once(let date):
                await manager.scheduleOneTimeReminder(
                    id: request.id, title: request.title, body: request.body, at: date,
                    deepLink: request.deepLink
                )
            case .daily(let hour, let minute):
                try? await manager.scheduleDailyReminder(
                    id: request.id, title: request.title, body: request.body,
                    hour: hour, minute: minute, deepLink: request.deepLink
                )
            case .weekly(let weekdays, let hour, let minute):
                try? await manager.scheduleWeeklyReminder(
                    id: request.id, title: request.title, body: request.body,
                    weekdays: weekdays, hour: hour, minute: minute,
                    deepLink: request.deepLink
                )
            case .monthly(let day, let hour, let minute):
                try? await manager.scheduleMonthlyReminder(
                    id: request.id, title: request.title, body: request.body,
                    day: day, hour: hour, minute: minute, deepLink: request.deepLink
                )
            }
        }
    }
}
