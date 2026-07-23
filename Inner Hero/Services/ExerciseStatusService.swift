import Foundation

/// Launcher subtitles for the four exercises (spec §2.2) and the `sessions == 0`
/// rule behind them (§1.7).
///
/// Every entry point returns `nil` while the exercise has no sessions yet; the
/// caller then falls back to its own corrective phrase. That keeps the two kinds
/// of copy where they belong — the corrective phrase is written once next to the
/// tile it describes, the state is computed here.
///
/// Nothing reads the clock: `now` and `calendar` are injected, so every
/// relative-day boundary is testable without waiting for midnight.
///
/// The four shapes differ on purpose. Each exercise has its own ladder and the
/// subtitle shows the position on *that* ladder — there is no common template
/// for exercises (§1.10), and forcing one here would be the first crack.
nonisolated enum ExerciseStatus {

    /// The exposure ratio runs over a rolling window rather than all time.
    /// An all-time fraction ossifies: after a hundred sessions nothing the user
    /// does moves it, and the subtitle stops describing where they are now —
    /// which is the only thing it promises.
    static let ratioWindow = 10

    // MARK: - Exposures

    /// Spec §2.2: `July 16 · stayed 6 of 7`.
    ///
    /// Both forms count. §3 keeps situational and planned exposures in one
    /// table because they are one exercise; splitting them here would report a
    /// number the History tab contradicts.
    ///
    /// "Stayed" means anything that is not `leftEarly` — wanting to leave and
    /// staying anyway is staying, and that is the whole point of the exercise.
    /// Entries with no behaviour recorded are left out of the fraction instead
    /// of counting as failures.
    static func exposure(
        _ entries: [ExposureLogEntry],
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> String? {
        guard let last = entries.max(by: { $0.createdAt < $1.createdAt }) else { return nil }
        let day = relativeDay(last.createdAt, now: now, calendar: calendar)

        let judged = entries
            .sorted { $0.createdAt > $1.createdAt }
            .prefix(ratioWindow)
            .compactMap(\.behavior)
        guard !judged.isEmpty else { return day }

        let stayed = judged.filter { $0 != .leftEarly }.count
        return String(
            format: String(localized: "%1$@ · stayed %2$d of %3$d"),
            day, stayed, judged.count
        )
    }

    // MARK: - Breathing

    /// Spec §2.2: `Box · 10 min`. No date — for breathing the ladder position
    /// *is* the state, and a third segment does not fit the tile.
    ///
    /// The planned duration, not the actual one: the ladder step is what the
    /// user chose to work at, and a session cut short should not look like a
    /// demotion they never made.
    static func breathing(_ entries: [BreathingSessionEntry]) -> String? {
        guard let last = entries.max(by: { $0.createdAt < $1.createdAt }) else { return nil }
        let minutes = String(
            format: String(localized: "%@ min"),
            BreathingLadder.minutesLabel(seconds: last.plannedDurationSeconds)
        )
        guard let pattern = last.pattern else { return minutes }
        return String(format: String(localized: "%1$@ · %2$@"), pattern.title, minutes)
    }

    // MARK: - Relaxation (PMR)

    /// Spec §2.2: `7 groups · today`.
    static func pmr(
        _ entries: [PMRSessionEntry],
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> String? {
        guard let last = entries.max(by: { $0.createdAt < $1.createdAt }) else { return nil }
        let day = relativeDay(last.createdAt, now: now, calendar: calendar)
        guard let step = last.step else { return day }
        return String(format: String(localized: "%1$@ · %2$@"), step.title, day)
    }

    // MARK: - Behavioral activation

    /// `Easy · yesterday` — the effort basket the user last worked in, in the
    /// shape of the PMR subtitle. Spec §2.2 gives no BA example; the BA ladder
    /// is the basket (§6), so the basket is the position.
    static func activation(
        _ entries: [BALogEntry],
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> String? {
        guard let last = entries.max(by: { $0.createdAt < $1.createdAt }) else { return nil }
        let day = relativeDay(last.createdAt, now: now, calendar: calendar)
        guard let effort = last.effort else { return day }
        return String(format: String(localized: "%1$@ · %2$@"), effort.title, day)
    }

    // MARK: - Ladder position without the day

    /// The ladder position alone, with no relative day attached (§11.7).
    ///
    /// The widgets use these instead of the full subtitles above, and the reason is
    /// not layout. A precomputed "today" becomes a lie at midnight, and a widget
    /// cannot recompute it — the app has to be opened first. The position never
    /// goes stale, so it is the part that can safely live on a home screen; the day
    /// is History's job anyway.
    ///
    /// Breathing needs no variant: `breathing(_:)` carries no day to begin with.
    static func pmrPosition(_ entries: [PMRSessionEntry]) -> String? {
        entries.max(by: { $0.createdAt < $1.createdAt })?.step?.title
    }

    static func activationPosition(_ entries: [BALogEntry]) -> String? {
        entries.max(by: { $0.createdAt < $1.createdAt })?.effort?.title
    }

    // MARK: - Relative day

    /// Split out so every boundary is testable without building a log entry —
    /// the same reason `TodayViewModel.greeting(forHour:)` is a free function.
    ///
    /// Deliberately relative only inside the last week. "Six days ago" is a
    /// calculation; "Tuesday" is a memory. Beyond that a weekday name is
    /// ambiguous and the date is the honest answer.
    static func relativeDay(
        _ date: Date,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> String {
        if calendar.isDate(date, inSameDayAs: now) {
            return String(localized: "today", comment: "Relative day in an exercise subtitle")
        }

        let days = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: date),
            to: calendar.startOfDay(for: now)
        ).day ?? 0

        if days == 1 {
            return String(localized: "yesterday", comment: "Relative day in an exercise subtitle")
        }
        if (2..<7).contains(days) {
            return date.formatted(.dateTime.weekday(.wide))
        }
        // Also covers dates in the future (`days < 0`): a clock moved backwards
        // should show a plain date, never "in 3 days".
        return date.formatted(.dateTime.day().month(.wide))
    }
}

/// Spec §8: the article standing at the door of each exercise before the first
/// session. Kept in one place so a renamed article breaks one line, not four —
/// `ExerciseStatusTests` asserts every id still resolves against `Articles.json`.
nonisolated enum ExerciseArticle {
    static let exposure = "exposure-therapy-basics"
    static let breathing = "breathing-techniques"
    static let relaxation = "progressive-muscle-relaxation"
    static let activation = "behavioral-activation"
}
