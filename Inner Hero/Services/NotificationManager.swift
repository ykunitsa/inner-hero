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
        minute: Int
    ) async throws {
        await removeReminder(id: id)

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

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

    /// Schedules a one-shot reminder at a specific date.
    func scheduleOneTimeReminder(id: String, title: String, body: String, at date: Date) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        try? await notificationCenter.add(request)
    }

    /// Removes a reminder scheduled with `scheduleWeeklyReminder` or
    /// `scheduleOneTimeReminder` (including all per-weekday variants).
    func removeReminder(id: String) async {
        var identifiers = [id]
        for weekday in 1...7 {
            identifiers.append("\(id)_\(weekday)")
        }
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
        notificationCenter.removeDeliveredNotifications(withIdentifiers: identifiers)
    }

    // MARK: - Cleanup

    func removeAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        notificationCenter.removeAllDeliveredNotifications()
    }
}
