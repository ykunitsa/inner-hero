import Foundation

/// Turns the store into the flat snapshot the widgets read (§11.7).
///
/// A pure function over arrays, like `TodayViewModel.doneExercises` — the app's
/// state goes in, a value comes out, and the effect (writing it, asking WidgetKit to
/// reload) happens at the call site.
nonisolated enum WidgetSnapshotBuilder {

    /// - Parameter isLocked: whether App Lock is on. When it is, the snapshot is
    ///   built **empty of content**: no activity title, no schedule, no ladder
    ///   positions. Redaction happens here rather than in the widget, so the shared
    ///   container never holds what the lock exists to hide — a widget that received
    ///   the strings and chose not to draw them would still be leaking them to
    ///   anything that can read the group.
    /// - Note: no `now` parameter, and no exposure log. Nothing built here depends
    ///   on the current time — that is the point of shipping ladder positions and
    ///   raw recurrence fields rather than "today's list".
    static func build(
        schedule: [ScheduleItem],
        breathing: [BreathingSessionEntry],
        pmr: [PMRSessionEntry],
        activation: [BALogEntry],
        isLocked: Bool,
        calendar: Calendar = .current
    ) -> WidgetSnapshot {
        guard !isLocked else { return WidgetSnapshot(isRedacted: true) }

        // Ladder positions, never the dated subtitles: see
        // `ExerciseStatus.pmrPosition`. Exposure has no position — its ladder is a
        // ratio over a window, which is a statement about the log rather than a
        // place to stand, and it is not something to put on a home screen.
        var subtitles: [String: String] = [:]
        subtitles[ScheduledExercise.breathing.rawValue] =
            ExerciseStatus.breathing(breathing)
        subtitles[ScheduledExercise.relaxation.rawValue] =
            ExerciseStatus.pmrPosition(pmr)
        subtitles[ScheduledExercise.activation.rawValue] =
            ExerciseStatus.activationPosition(activation)

        let items = schedule
            // A disabled entry is absent, exactly as it is absent from the day list.
            .filter { $0.isEnabled && $0.exercise != nil && $0.recurrence != nil }
            .map { item in
                WidgetSnapshot.Item(
                    exerciseRaw: item.exerciseRaw,
                    timeText: ScheduleViewModel.timeText(
                        hour: item.hour, minute: item.minute, calendar: calendar
                    ),
                    hour: item.hour,
                    minute: item.minute,
                    recurrenceRaw: item.recurrenceRaw,
                    weekdays: item.weekdays,
                    monthDay: item.monthDay,
                    onceDate: item.onceDate
                )
            }

        return WidgetSnapshot(
            // The open tail, if there is one. Sorted here rather than trusted from
            // the query, so the snapshot does not depend on the caller's sort.
            openTailTitle: activation
                .filter(\.isOpen)
                .max(by: { $0.createdAt < $1.createdAt })?
                .activityTitle,
            items: items,
            subtitles: subtitles,
            isRedacted: false
        )
    }
}
