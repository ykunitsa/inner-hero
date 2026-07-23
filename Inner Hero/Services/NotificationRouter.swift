import Foundation
import UserNotifications

/// Turns a tap on a notification into a deep link (§11.7).
///
/// The delegate exists only for this. Foreground presentation is deliberately left
/// at the system default — a reminder for 18:00 that appears as a banner while the
/// person is already inside the app would be the app talking over itself.
///
/// A tap on a notification that carries no destination (the planned-exposure end
/// signal) does nothing beyond opening the app, which is the whole of its job.
final class NotificationRouter: NSObject, UNUserNotificationCenterDelegate {
    private let inbox: DeepLinkInbox

    init(inbox: DeepLinkInbox) {
        self.inbox = inbox
        super.init()
    }

    /// Must run before the launch finishes: a notification tapped from a cold start
    /// is delivered to whatever delegate exists by then, and to nobody if there is
    /// none.
    func start() {
        UNUserNotificationCenter.current().delegate = self
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        // Parsed here, in the delegate's own context: only the resulting value
        // crosses to the main actor, never the notification's payload.
        guard let link = DeepLink(
            userInfo: response.notification.request.content.userInfo
        ) else { return }
        await inbox.receive(link)
    }
}
