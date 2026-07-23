import Foundation
import Testing

@testable import Inner_Hero

/// §11.7 — the app's one external entry point.
///
/// Both a widget tap and a notification tap travel as the same value, so this is the
/// seam where "tapping the breathing reminder opens breathing" stops being a device
/// run and becomes an assertion.
@Suite("Deep links")
struct DeepLinkTests {

    @Test("Every link survives a round trip through its URL", arguments: [
        DeepLink.logExposure,
        .exercise(.exposure),
        .exercise(.breathing),
        .exercise(.relaxation),
        .exercise(.activation),
    ])
    func roundTrip(_ link: DeepLink) {
        #expect(DeepLink(url: link.url) == link)
    }

    @Test("Every link survives a round trip through a notification payload", arguments: [
        DeepLink.logExposure,
        .exercise(.breathing),
    ])
    func userInfoRoundTrip(_ link: DeepLink) {
        #expect(DeepLink(userInfo: link.userInfo) == link)
    }

    @Test("Another app's scheme is not ours")
    func foreignScheme() {
        #expect(DeepLink(url: URL(string: "https://example.com/exercise/breathing")!) == nil)
    }

    @Test("An unknown destination is refused rather than guessed")
    func unknownDestinations() {
        #expect(DeepLink(url: URL(string: "innerhero://exercise/meditation")!) == nil)
        #expect(DeepLink(url: URL(string: "innerhero://exercise")!) == nil)
        #expect(DeepLink(url: URL(string: "innerhero://history")!) == nil)
    }

    @Test("A payload without a link is not a link")
    func emptyUserInfo() {
        #expect(DeepLink(userInfo: [:]) == nil)
        #expect(DeepLink(userInfo: ["deepLink": "not a url at all ://"]) == nil)
    }

    @Test("A schedule reminder carries the exercise it is about")
    func scheduleReminderCarriesItsExercise() {
        let item = ScheduleItem(exercise: .relaxation, recurrence: .weekly, hour: 21, minute: 30)
        let request = ScheduleReminderService.request(for: item)

        #expect(request?.deepLink == .exercise(.relaxation))
    }

    // MARK: Inbox

    @MainActor
    @Test("A parked link is delivered once and only once")
    func inboxSpendsTheLink() {
        let inbox = DeepLinkInbox()
        inbox.receive(.exercise(.breathing))

        #expect(inbox.pending == .exercise(.breathing))
        #expect(inbox.take() == .exercise(.breathing))
        #expect(inbox.take() == nil)
    }

    @MainActor
    @Test("A URL that means nothing does not clear what is already waiting")
    func inboxIgnoresJunk() {
        let inbox = DeepLinkInbox()
        inbox.receive(.logExposure)
        inbox.receive(url: URL(string: "innerhero://nowhere")!)

        #expect(inbox.pending == .logExposure)
    }
}
