import Foundation
import SwiftData

// `ScheduledExercise` and `ScheduleRecurrence` live in their own files
// (`ScheduledExercise.swift`, `ScheduleRecurrenceRule.swift`): the widget extension
// needs both, and neither may drag a `@Model` into it (§11.7).

// MARK: - Schedule item

/// One thing the user put on their own schedule (spec §2.1, §1.10).
///
/// There can be **several per exercise**: a one-off exposure next Thursday and a
/// daily breathing slot coexist, and PMR in the morning and again at night is two
/// entries rather than a choice between them. That is why this is a list, not a
/// fixed row per exercise.
///
/// The recurrence is stored as flat fields rather than an enum with associated
/// values: SwiftData persists properties, not payloads, and a flat model stays
/// queryable without a Codable blob. `hour`/`minute` are shared by all three kinds
/// on purpose — switching the kind must not lose the time already picked.
@Model
final class ScheduleItem {
    /// Every non-optional property is defaulted **in the declaration**. Without a
    /// default CoreData cannot migrate a store that predates the property, and the
    /// retry in `makeContainer()` does not save us (CLAUDE.md, SwiftData section).
    var exerciseRaw: String = ScheduledExercise.breathing.rawValue
    var recurrenceRaw: String = ScheduleRecurrence.weekly.rawValue
    var hour: Int = 9
    var minute: Int = 0
    /// `weekly` only. `Calendar` semantics (1 = Sunday). Empty means every day —
    /// the editor writes the explicit set, this is the safe reading for anything
    /// that never went through it.
    var weekdays: [Int] = []
    /// `monthly` only, 1...31.
    var monthDay: Int = 1
    /// `once` only: the start of the day it falls on. The time of day lives in
    /// `hour`/`minute` like everywhere else.
    var onceDate: Date? = nil
    var isEnabled: Bool = true
    var createdAt: Date = Date.distantPast
    /// Identifier for this entry's reminders, so a re-sync can take exactly its
    /// own requests out of the queue. Stored rather than derived from
    /// `persistentModelID`, which is not guaranteed to hash to the same value
    /// across launches — the same reason `BALogEntry` carries one, and a reminder
    /// that cannot be cancelled would go on ringing for a deleted entry.
    var reminderToken: UUID = UUID()

    init(
        exercise: ScheduledExercise,
        recurrence: ScheduleRecurrence,
        hour: Int,
        minute: Int,
        weekdays: [Int] = [],
        monthDay: Int = 1,
        onceDate: Date? = nil,
        isEnabled: Bool = true,
        createdAt: Date = Date(),
        reminderToken: UUID = UUID()
    ) {
        self.reminderToken = reminderToken
        self.exerciseRaw = exercise.rawValue
        self.recurrenceRaw = recurrence.rawValue
        self.hour = hour
        self.minute = minute
        self.weekdays = weekdays
        self.monthDay = monthDay
        self.onceDate = onceDate
        self.isEnabled = isEnabled
        self.createdAt = createdAt
    }

    var exercise: ScheduledExercise? { ScheduledExercise(rawValue: exerciseRaw) }
    var recurrence: ScheduleRecurrence? { ScheduleRecurrence(rawValue: recurrenceRaw) }

    /// Every schedule reminder starts with `ScheduleItem.reminderPrefix`, so a
    /// re-sync can clear the whole schedule out of the notification queue without
    /// touching the BA tail or the exposure end-signal, which live in the same
    /// queue (plan decision 19).
    static let reminderPrefix = "schedule."

    var reminderID: String { "\(Self.reminderPrefix)\(reminderToken.uuidString)" }

    /// Minutes since midnight — the sort key of a day.
    var minutesOfDay: Int { hour * 60 + minute }

    // MARK: Occurrence

    /// Does this entry fall on the given day?
    ///
    /// A disabled entry falls on no day at all: the switch is what "not this week"
    /// means, and it keeps the time rather than deleting it.
    func occurs(on date: Date, calendar: Calendar = .current) -> Bool {
        guard isEnabled, let recurrence else { return false }
        return Self.occurs(
            recurrence: recurrence,
            weekdays: weekdays,
            monthDay: monthDay,
            onceDate: onceDate,
            on: date,
            calendar: calendar
        )
    }

    /// The rule itself lives in `ScheduleRecurrenceRule` — testable without a store,
    /// and reachable from the widget without SwiftData. This stays as the call site
    /// everything in the app already uses.
    static func occurs(
        recurrence: ScheduleRecurrence,
        weekdays: [Int],
        monthDay: Int,
        onceDate: Date?,
        on date: Date,
        calendar: Calendar = .current
    ) -> Bool {
        ScheduleRecurrenceRule.occurs(
            recurrence: recurrence,
            weekdays: weekdays,
            monthDay: monthDay,
            onceDate: onceDate,
            on: date,
            calendar: calendar
        )
    }

    // MARK: Cleanup

    /// A one-off entry whose day is behind us.
    ///
    /// Spent entries are removed rather than kept as "past" (plan decision 6):
    /// a list of things planned and not done is exactly the reproach material
    /// principle 1.4 forbids. What actually happened lives in History; the
    /// schedule is not a log.
    func isSpent(now: Date = Date(), calendar: Calendar = .current) -> Bool {
        Self.isSpent(
            recurrence: recurrence,
            onceDate: onceDate,
            now: now,
            calendar: calendar
        )
    }

    static func isSpent(
        recurrence: ScheduleRecurrence?,
        onceDate: Date?,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> Bool {
        ScheduleRecurrenceRule.isSpent(
            recurrence: recurrence, onceDate: onceDate, now: now, calendar: calendar
        )
    }
}
