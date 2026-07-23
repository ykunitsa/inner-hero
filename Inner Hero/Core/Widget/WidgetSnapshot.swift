import Foundation

/// What the app tells its widgets about the world (§11.7).
///
/// A flat snapshot rather than a shared SwiftData store. The widgets need three
/// strings and a schedule; moving the store into an App Group container would move
/// the file (losing the data), compile the whole schema into every extension, and
/// put a reader in the same store the app writes to — all to answer "what is next".
///
/// The schedule travels as **raw recurrence fields**, not as "today's list". That is
/// what lets a widget stay truthful for days without the app being opened: it runs
/// `ScheduleRecurrenceRule` itself. Formatting is done here, in the app, where the
/// formatters and the ladders already live.
nonisolated struct WidgetSnapshot: Codable, Equatable, Sendable {

    /// One schedule entry, carrying both its rendered text and the fields the rule
    /// needs to place it on a day.
    struct Item: Codable, Equatable, Sendable {
        var exerciseRaw: String
        var timeText: String
        var hour: Int
        var minute: Int
        var recurrenceRaw: String
        var weekdays: [Int]
        var monthDay: Int
        var onceDate: Date?

        var exercise: ScheduledExercise? { ScheduledExercise(rawValue: exerciseRaw) }
        var recurrence: ScheduleRecurrence? { ScheduleRecurrence(rawValue: recurrenceRaw) }
    }

    /// The open BA activity's title, if one is waiting.
    var openTailTitle: String?
    var items: [Item]
    /// Ladder positions by exercise rawValue — "Box · 10 min", "7 groups". Absent
    /// means `sessions == 0`, and the widget falls back to the corrective phrase —
    /// the same rule as the launcher tile (§1.7), expressed once.
    ///
    /// Positions, not the launcher's dated subtitles: see `ExerciseStatus.pmrPosition`.
    var subtitles: [String: String]
    /// Written while App Lock is on. The snapshot then carries no titles, no times
    /// and no ladder positions at all — redaction happens on write, so the shared
    /// container never holds them in the first place.
    var isRedacted: Bool

    init(
        openTailTitle: String? = nil,
        items: [Item] = [],
        subtitles: [String: String] = [:],
        isRedacted: Bool = false
    ) {
        self.openTailTitle = openTailTitle
        self.items = items
        self.subtitles = subtitles
        self.isRedacted = isRedacted
    }

    /// What a widget shows before the app has ever written anything — someone who
    /// added the widget straight from the gallery. Not an error state: logging an
    /// exposure is available from zero sessions, so the fallback is simply true.
    static let empty = WidgetSnapshot()

    func subtitle(for exercise: ScheduledExercise) -> String? {
        subtitles[exercise.rawValue]
    }
}

// MARK: - Store

/// Reads and writes the snapshot in the App Group container.
///
/// Both sides go through this type, so the key and the encoding exist once. If the
/// group is unavailable — the entitlement not yet added, a build without it — every
/// read returns `nil` and every widget degrades to its default state. A missing
/// snapshot is a state the widgets are designed for, not a failure to report.
nonisolated struct WidgetSnapshotStore {
    static let appGroupID = "group.wrongteam.Inner-Hero"
    static let key = "widget.snapshot.v1"

    let defaults: UserDefaults?

    init(defaults: UserDefaults? = UserDefaults(suiteName: WidgetSnapshotStore.appGroupID)) {
        self.defaults = defaults
    }

    func read() -> WidgetSnapshot? {
        guard
            let data = defaults?.data(forKey: Self.key),
            let snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
        else { return nil }
        return snapshot
    }

    func write(_ snapshot: WidgetSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults?.set(data, forKey: Self.key)
    }
}
