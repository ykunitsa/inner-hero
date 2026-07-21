import Foundation
import Observation
import SwiftData

/// Logic of the breathing flow (spec §4, §11.3): the "before" setup, the paced
/// session, and the one-question "after" screen.
///
/// One entry travels through all three stages. It is inserted at "Start" with
/// the plan only, so killing the app mid-session leaves a truthful partial
/// record instead of nothing (principle 1.5); the session end writes the actual
/// duration, and "after" writes the answer.
@Observable @MainActor
final class BreathingFlowViewModel {

    enum Stage {
        case before
        case session
        case after
    }

    private(set) var stage: Stage = .before

    // MARK: "Before" state

    var pattern: BreathingPattern = .box
    var plannedDuration: Int = BreathingLadder.initialDuration
    /// The ladder line shown on "before" — a suggestion, never applied on its
    /// own (principle 1.8).
    private(set) var suggestion: BreathingLadder.Suggestion?

    // MARK: Session state

    private(set) var entry: BreathingSessionEntry?
    private(set) var isPaused = false
    /// Whether the user actually pressed pause. Going to the background does
    /// not count — that would be inventing an intent they never had.
    private(set) var wasPaused = false

    /// Time counted before the current running stretch began.
    private var accumulated: TimeInterval = 0
    /// When the current running stretch started; nil while paused.
    private var runningSince: Date?

    // MARK: "After" state

    var didRelax: Bool?
    var note = ""
    private(set) var actualDuration: Int = 0

    // MARK: Configuration

    /// - Parameter history: sessions **newest first**.
    func configure(history: [BreathingSessionEntry]) {
        // Smart default (codex §2): pick up where the last session left off.
        if let last = history.first, let lastPattern = last.pattern {
            pattern = lastPattern
            plannedDuration = last.plannedDurationSeconds
        }
        refreshSuggestion(history: history)
    }

    func refreshSuggestion(history: [BreathingSessionEntry]) {
        suggestion = BreathingLadder.suggestion(
            history: history.compactMap(BreathingLadder.Outcome.init(entry:)),
            pattern: pattern,
            currentDuration: plannedDuration
        )
    }

    /// Accepting the suggestion moves the ruler; the line then has nothing left
    /// to offer at the new duration and disappears on its own.
    func applySuggestion() {
        guard let suggestion else { return }
        plannedDuration = suggestion.seconds
        self.suggestion = nil
    }

    // MARK: Start

    func start(in context: ModelContext, now: Date = Date()) throws {
        guard stage == .before, entry == nil else { return }
        let newEntry = BreathingSessionEntry(
            createdAt: now,
            pattern: pattern,
            plannedDurationSeconds: plannedDuration
        )
        context.insert(newEntry)
        try context.save()

        entry = newEntry
        accumulated = 0
        runningSince = now
        stage = .session
    }

    // MARK: Session clock

    /// Seconds of *breathing* so far — a pause stops this, going to the
    /// background does not (the wall clock keeps running, decision 11).
    func elapsed(now: Date) -> TimeInterval {
        guard let runningSince else { return accumulated }
        return accumulated + max(now.timeIntervalSince(runningSince), 0)
    }

    func remaining(now: Date) -> TimeInterval {
        max(TimeInterval(plannedDuration) - elapsed(now: now), 0)
    }

    func isFinished(now: Date) -> Bool {
        stage == .session && remaining(now: now) <= 0
    }

    /// The phase to show and how far into it — pure, delegated to the pattern.
    func phase(now: Date) -> (phase: BreathPhase, progress: Double) {
        pattern.phase(at: elapsed(now: now))
    }

    func phaseDuration(_ phase: BreathPhase) -> TimeInterval {
        pattern.phaseDurations.first { $0.phase == phase }?.seconds ?? 0
    }

    func togglePause(now: Date = Date()) {
        if isPaused {
            runningSince = now
            isPaused = false
        } else {
            accumulated = elapsed(now: now)
            runningSince = nil
            isPaused = true
            wasPaused = true
            entry?.wasPaused = true
        }
    }

    nonisolated static func formatRemaining(_ interval: TimeInterval) -> String {
        let total = max(Int(interval.rounded(.up)), 0)
        return String(format: "%02d:%02d", total / 60, total % 60)
    }

    // MARK: Session end

    /// The session ran out. Both endings write the fact and go to "after" —
    /// leaving early is data, not a cancel (principle 1.5), and "did you manage
    /// to relax" is a fair question for a short session too.
    func complete(in context: ModelContext, now: Date = Date()) {
        finish(in: context, duration: plannedDuration)
    }

    func finishEarly(in context: ModelContext, now: Date = Date()) {
        finish(in: context, duration: min(Int(elapsed(now: now)), plannedDuration))
    }

    private func finish(in context: ModelContext, duration: Int) {
        guard stage == .session else { return }
        actualDuration = duration
        entry?.actualDurationSeconds = duration
        try? context.save()
        stage = .after
    }

    // MARK: "After"

    var canSaveAfter: Bool { didRelax != nil }

    var trimmedNote: String {
        note.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// True when the session stopped short of the plan — the "after" screen
    /// states the fact without calling it a failure.
    var didFinishEarly: Bool {
        actualDuration < plannedDuration
    }

    func saveAfter(in context: ModelContext) throws {
        guard let entry else { return }
        entry.didRelax = didRelax
        entry.note = trimmedNote.isEmpty ? nil : trimmedNote
        try context.save()
    }

    /// Closing "after" without answering keeps everything already recorded.
    func savePartial(in context: ModelContext) throws {
        try saveAfter(in: context)
    }
}
