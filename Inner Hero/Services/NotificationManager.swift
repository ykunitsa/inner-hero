import Foundation
import UserNotifications

/// Generic local-notification plumbing (spec principle 1.10: the shared layer
/// is scheduling + logging). Exercise-specific scheduling is built on top of
/// these primitives as the new schedule models land.
@Observable
@MainActor
final class NotificationManager {
    private let notificationCenter = UNUserNotificationCenter.current()

    init() {}

    // MARK: - Permission Management

    func requestAuthorization() async -> Bool {
        do {
            return try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func checkAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await notificationCenter.notificationSettings()
        return settings.authorizationStatus
    }

    // MARK: - Scheduling primitives

    /// Schedules a weekly repeating reminder for each of the given weekdays
    /// (1 = Sunday ... 7 = Saturday) at the given hour/minute.
    /// Identifiers are "\(id)_\(weekday)".
    func scheduleWeeklyReminder(
        id: String,
        title: String,
        body: String,
        weekdays: [Int],
        hour: Int,
        minute: Int,
        deepLink: DeepLink? = nil
    ) async throws {
        await removeReminder(id: id)

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = deepLink?.userInfo ?? [:]

        for weekday in weekdays {
            var dateComponents = DateComponents()
            dateComponents.weekday = weekday
            dateComponents.hour = hour
            dateComponents.minute = minute

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(
                identifier: "\(id)_\(weekday)",
                content: content,
                trigger: trigger
            )
            try await notificationCenter.add(request)
        }
    }

    /// Schedules one repeating reminder at the given hour/minute of every day.
    ///
    /// Not the same as passing all seven weekdays to `scheduleWeeklyReminder`:
    /// that would occupy seven of the system's 64 pending slots to say what one
    /// request says.
    func scheduleDailyReminder(
        id: String,
        title: String,
        body: String,
        hour: Int,
        minute: Int,
        sound: UNNotificationSound? = .default,
        deepLink: DeepLink? = nil
    ) async throws {
        try await schedule(
            id: id,
            title: title,
            body: body,
            components: DateComponents(hour: hour, minute: minute),
            repeats: true,
            sound: sound,
            deepLink: deepLink
        )
    }

    /// Schedules one repeating reminder on the given day of every month.
    ///
    /// Months without that day are skipped by the system rather than moved to the
    /// last day — which is exactly what the schedule screen shows, on purpose
    /// (`docs/plans/11.6d-schedule.md`, decision 7).
    func scheduleMonthlyReminder(
        id: String,
        title: String,
        body: String,
        day: Int,
        hour: Int,
        minute: Int,
        sound: UNNotificationSound? = .default,
        deepLink: DeepLink? = nil
    ) async throws {
        try await schedule(
            id: id,
            title: title,
            body: body,
            components: DateComponents(day: day, hour: hour, minute: minute),
            repeats: true,
            sound: sound,
            deepLink: deepLink
        )
    }

    private func schedule(
        id: String,
        title: String,
        body: String,
        components: DateComponents,
        repeats: Bool,
        sound: UNNotificationSound?,
        deepLink: DeepLink?
    ) async throws {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = sound
        content.userInfo = deepLink?.userInfo ?? [:]

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: repeats)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        try await notificationCenter.add(request)
    }

    /// Schedules a one-shot reminder at a specific date.
    func scheduleOneTimeReminder(
        id: String,
        title: String,
        body: String,
        at date: Date,
        deepLink: DeepLink? = nil
    ) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = deepLink?.userInfo ?? [:]

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        try? await notificationCenter.add(request)
    }

    /// Schedules a one-shot signal with second precision (calendar triggers
    /// only resolve to the minute). Used as the session-end vibration when
    /// the app is in the background (spec §3: planned exposure timer).
    ///
    /// - Parameter sound: pass `nil` for a silent delivery. The BA tail reminder
    ///   (spec §6: "одно тихое напоминание") uses it — it asks whether something
    ///   from hours ago happened, which never warrants pulling attention with a
    ///   chime.
    /// - Parameter deepLink: where a tap should land. The planned-exposure end
    ///   signal deliberately passes none: it is a vibration marking the end of a
    ///   session, and its "after" form lives inside a flow that is no longer
    ///   running (§11.7).
    func scheduleOneTimeSignal(
        id: String,
        title: String,
        body: String,
        after seconds: TimeInterval,
        sound: UNNotificationSound? = .default,
        deepLink: DeepLink? = nil
    ) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = sound
        content.userInfo = deepLink?.userInfo ?? [:]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(seconds, 1), repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        try? await notificationCenter.add(request)
    }

    /// Removes a reminder scheduled with `scheduleWeeklyReminder`,
    /// `scheduleOneTimeReminder` or `scheduleOneTimeSignal` (including all
    /// per-weekday variants).
    func removeReminder(id: String) async {
        var identifiers = [id]
        for weekday in 1...7 {
            identifiers.append("\(id)_\(weekday)")
        }
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
        notificationCenter.removeDeliveredNotifications(withIdentifiers: identifiers)
    }

    /// Removes every pending request whose identifier starts with `prefix`.
    ///
    /// This is how the schedule re-syncs itself. The blunt instrument —
    /// `removeAllNotifications()` — is wrong here: the BA tail reminder and the
    /// exposure end-signal share this queue, and a schedule edit must not silence
    /// a walk someone committed to an hour ago.
    func removePendingReminders(withPrefix prefix: String) async {
        let pending = await notificationCenter.pendingNotificationRequests()
        let identifiers = pending
            .map(\.identifier)
            .filter { $0.hasPrefix(prefix) }
        guard !identifiers.isEmpty else { return }
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    // MARK: - Cleanup

    func removeAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        notificationCenter.removeAllDeliveredNotifications()
    }
}
