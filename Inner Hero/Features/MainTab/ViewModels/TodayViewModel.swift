import Foundation
import Observation
import SwiftData

/// One line of the day list on Today.
///
/// `isDone` is computed from the logs, never stored (plan decision 12/16): a
/// denormalised "completed" flag would disagree with the log the first time an
/// entry is deleted.
nonisolated struct TodayScheduleRow: Identifiable {
    let item: ScheduleItem
    let isDone: Bool

    /// The stored object's own identity, not one of its fields. `reminderToken`
    /// looked like a fine id until migration proved otherwise: CoreData gives
    /// every row migrated into a new attribute the *same* default value, so two
    /// entries shared a token and `ForEach` drew one of them twice.
    var id: PersistentIdentifier { item.persistentModelID }
}

/// Logic of the "Today" tab (spec §2.1). Time is injected rather than read
/// from the clock inside the view, so the greeting is testable and refreshes
/// on a real event instead of whenever SwiftUI happens to re-evaluate `body`.
@Observable @MainActor
final class TodayViewModel {

    private let calendar: Calendar

    /// The moment the screen is rendering for. Bumped by the view when the
    /// app returns to the foreground, so a session left open past 17:00
    /// doesn't keep saying "Good afternoon" — and so the day list and its
    /// "done" marks roll over at midnight.
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

    /// What falls on today, in the order it falls.
    ///
    /// Entries that have already happened keep their place: nothing sinks to the
    /// bottom and nothing turns a colour when its time has passed. An overdue
    /// state is a reproach, not information (codex §8, principle 1.4).
    func rows(
        schedule: [ScheduleItem],
        done: Set<ScheduledExercise>
    ) -> [TodayScheduleRow] {
        Self.rows(schedule: schedule, done: done, on: now, calendar: calendar)
    }

    nonisolated static func rows(
        schedule: [ScheduleItem],
        done: Set<ScheduledExercise>,
        on date: Date,
        calendar: Calendar = .current
    ) -> [TodayScheduleRow] {
        schedule
            .filter { $0.occurs(on: date, calendar: calendar) }
            .sorted { ($0.minutesOfDay, $0.createdAt) < ($1.minutesOfDay, $1.createdAt) }
            .map { item in
                TodayScheduleRow(
                    item: item,
                    isDone: item.exercise.map { done.contains($0) } ?? false
                )
            }
    }

    /// Which exercises already have something logged today.
    ///
    /// A session ended early counts: leaving early is data, not a failed attempt
    /// (§1.5). BA is the one exception — an **open** entry does not count, because
    /// its tail is still on this very screen asking "Did it happen?", and a row
    /// saying "done" beside it would make the screen contradict itself. Answering
    /// "couldn't" closes the entry and does count: the person went through the
    /// exercise, and grading the outcome is not the app's job.
    nonisolated static func doneExercises(
        exposures: [ExposureLogEntry],
        breathing: [BreathingSessionEntry],
        pmr: [PMRSessionEntry],
        activation: [BALogEntry],
        on date: Date,
        calendar: Calendar = .current
    ) -> Set<ScheduledExercise> {
        var done: Set<ScheduledExercise> = []

        if exposures.contains(where: { calendar.isDate($0.createdAt, inSameDayAs: date) }) {
            done.insert(.exposure)
        }
        if breathing.contains(where: { calendar.isDate($0.createdAt, inSameDayAs: date) }) {
            done.insert(.breathing)
        }
        if pmr.contains(where: { calendar.isDate($0.createdAt, inSameDayAs: date) }) {
            done.insert(.relaxation)
        }
        if activation.contains(where: {
            !$0.isOpen && calendar.isDate($0.createdAt, inSameDayAs: date)
        }) {
            done.insert(.activation)
        }

        return done
    }

    /// Whether an exposure is on today's list — the one thing the quiet line at the
    /// bottom answers. Lives here rather than in the view so the rule behind that
    /// line is testable.
    nonisolated static func hasExposure(in rows: [TodayScheduleRow]) -> Bool {
        rows.contains { $0.item.exercise == .exposure }
    }

    /// The row's second line: the time, plus a quiet fact if it already happened.
    nonisolated static func meta(for row: TodayScheduleRow, calendar: Calendar = .current) -> String {
        let time = ScheduleViewModel.timeText(
            hour: row.item.hour, minute: row.item.minute, calendar: calendar
        )
        guard row.isDone else { return time }
        return String(
            format: String(localized: "%1$@ · %2$@"),
            time,
            String(localized: "done", comment: "A scheduled exercise already logged today")
        )
    }

    /// Spec §2.1: a plain line of text, never a card and never a prompt to go
    /// set something up. Shown only while no exposure is on today's list.
    var emptyScheduleText: String {
        String(localized: "No exposure planned for today")
    }
}
