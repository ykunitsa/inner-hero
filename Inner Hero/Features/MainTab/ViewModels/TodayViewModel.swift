import Foundation
import Observation

/// Logic of the "Today" tab (spec §2.1). Time is injected rather than read
/// from the clock inside the view, so the greeting is testable and refreshes
/// on a real event instead of whenever SwiftUI happens to re-evaluate `body`.
@Observable @MainActor
final class TodayViewModel {

    private let calendar: Calendar

    /// The moment the screen is rendering for. Bumped by the view when the
    /// app returns to the foreground, so a session left open past 17:00
    /// doesn't keep saying "Good afternoon".
    private(set) var now: Date

    init(now: Date = Date(), calendar: Calendar = .current) {
        self.now = now
        self.calendar = calendar
    }

    func refresh(now: Date = Date()) {
        self.now = now
    }

    // MARK: Greeting

    var greeting: String {
        Self.greeting(forHour: calendar.component(.hour, from: now))
    }

    /// Split out so the boundaries can be tested without building a `Date`
    /// for every hour of the day.
    nonisolated static func greeting(forHour hour: Int) -> String {
        switch hour {
        case 5..<12:  String(localized: "Good morning")
        case 12..<17: String(localized: "Good afternoon")
        case 17..<22: String(localized: "Good evening")
        default:      String(localized: "Good night")
        }
    }

    // MARK: Day schedule

    /// Planned exercises for today. The schedule itself lands with the shell
    /// rebuild (spec §11.6); until then the screen always shows the quiet
    /// "nothing planned" line rather than pretending the section is absent.
    var hasPlannedExposure: Bool { false }

    /// Spec §2.1: a plain line of text, never a card and never a prompt to go
    /// set something up.
    var emptyScheduleText: String {
        String(localized: "No exposure planned for today")
    }
}
