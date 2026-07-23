import Foundation

/// The app's one external entry point (§11.7).
///
/// Widgets and notifications both need to say "open this exercise", so they say it
/// the same way. Built once rather than twice: a notification that routes through
/// its own mechanism and a widget that routes through another is two chances for
/// the same tap to land somewhere different.
///
/// Deliberately small. A deep link may name a **door**, never a step inside a flow:
/// the planned-exposure end signal, for instance, carries no link at all, because
/// its "after" form only exists inside a session this app is no longer running.
/// A link that reconstructs mid-flow state would be a link that invents data
/// (§1.6).
nonisolated enum DeepLink: Equatable, Hashable, Sendable {
    /// The situational form — the entry with a shelf life (§1.6: while it's fresh).
    case logExposure
    /// The exercise's own door. Behavioral activation opens on its tail when one is
    /// open, which is what the tail reminder and the "Сегодня" widget both want,
    /// so the tail needs no case of its own.
    case exercise(ScheduledExercise)

    static let scheme = "innerhero"

    private static let exposureHost = "log-exposure"
    private static let exerciseHost = "exercise"

    // MARK: URL

    var url: URL {
        var components = URLComponents()
        components.scheme = Self.scheme
        switch self {
        case .logExposure:
            components.host = Self.exposureHost
        case .exercise(let exercise):
            components.host = Self.exerciseHost
            components.path = "/\(exercise.rawValue)"
        }
        // The components above are fixed strings and a rawValue from a closed
        // enum, so this cannot fail — but a crash on the home screen's behalf is
        // never worth a `!`.
        return components.url ?? URL(string: "\(Self.scheme)://\(Self.exposureHost)")!
    }

    init?(url: URL) {
        guard url.scheme == Self.scheme else { return nil }
        switch url.host() {
        case Self.exposureHost:
            self = .logExposure
        case Self.exerciseHost:
            let raw = url.pathComponents.filter { $0 != "/" }.first ?? ""
            guard let exercise = ScheduledExercise(rawValue: raw) else { return nil }
            self = .exercise(exercise)
        default:
            return nil
        }
    }

    // MARK: Notification payload

    /// The key a scheduled notification carries its destination under.
    static let userInfoKey = "deepLink"

    var userInfo: [String: String] { [Self.userInfoKey: url.absoluteString] }

    init?(userInfo: [AnyHashable: Any]) {
        guard
            let raw = userInfo[Self.userInfoKey] as? String,
            let url = URL(string: raw)
        else { return nil }
        self.init(url: url)
    }
}

// MARK: - Inbox

/// Where an external tap waits until a screen can act on it.
///
/// A link arrives before there is anywhere to put it: on a cold launch the tab bar
/// does not exist yet, and under App Lock the app is on screen but must not open
/// anything. So the link is *parked*, and whoever can honour it takes it — the same
/// shape as the BA tail, which also waits rather than expiring.
@Observable
@MainActor
final class DeepLinkInbox {
    private(set) var pending: DeepLink?

    func receive(_ link: DeepLink) {
        pending = link
    }

    func receive(url: URL) {
        guard let link = DeepLink(url: url) else { return }
        pending = link
    }

    /// Takes the link, leaving the inbox empty. Callers must be able to act on it
    /// *now* — reading it under a lock screen would drop it silently.
    func take() -> DeepLink? {
        defer { pending = nil }
        return pending
    }
}
