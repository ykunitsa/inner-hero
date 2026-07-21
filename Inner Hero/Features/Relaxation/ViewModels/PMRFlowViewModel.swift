import Foundation
import SwiftData

/// The whole PMR flow (spec §5): before → session → after.
///
/// One view model for three stages, like breathing — the stages share the step,
/// the clock and the entry, and splitting them would mean threading all three
/// through callbacks.
///
/// The clock is never read in here: every method that needs the time takes
/// `now` (CLAUDE.md), which is what lets the whole session be tested at
/// arbitrary offsets without waiting eleven minutes.
@Observable
@MainActor
final class PMRFlowViewModel {

    enum Stage {
        case before
        case session
        case after
    }

    private(set) var stage: Stage = .before

    // MARK: "Before"

    var step: PMRStep = PMRLadder.initialStep
    private(set) var suggestion: PMRLadder.Suggestion?

    /// What the script will take, derived — never typed in (spec §5).
    var plannedDuration: Int { Int(step.estimatedDuration.rounded()) }

    // MARK: Session

    private(set) var entry: PMRSessionEntry?
    private(set) var cues: [PMRCue] = []
    /// Cumulative end offset of each cue, so the current one is a lookup rather
    /// than a walk.
    private var cueEnds: [TimeInterval] = []

    /// True while the audio route is taken by something else. The script stops
    /// where it is; it never resumes itself mid-instruction.
    private(set) var isInterrupted = false

    private var accumulated: TimeInterval = 0
    private var runningSince: Date?

    // MARK: "After"

    var didRelax: Bool?
    var note = ""
    private(set) var actualDuration = 0
    private(set) var groupsCompleted = 0

    // MARK: Setup

    func configure(history: [PMRSessionEntry]) {
        if let last = history.first?.step {
            step = last
        }
        refreshSuggestion(history: history)
    }

    func refreshSuggestion(history: [PMRSessionEntry]) {
        suggestion = PMRLadder.suggestion(
            history: history.compactMap(PMRLadder.Outcome.init(entry:)),
            currentStep: step
        )
    }

    /// The rule proposes, the user disposes (principle 1.8) — this only ever
    /// runs from an explicit tap on the suggestion line.
    func applySuggestion() {
        guard let suggestion else { return }
        step = suggestion.step
        self.suggestion = nil
    }

    // MARK: Start

    func start(in context: ModelContext, now: Date = Date()) throws {
        guard stage == .before, entry == nil else { return }

        cues = PMRScript.cues(for: step)
        cueEnds = cues.reduce(into: []) { ends, cue in
            ends.append((ends.last ?? 0) + cue.duration)
        }

        let newEntry = PMRSessionEntry(
            createdAt: now,
            step: step,
            plannedDurationSeconds: plannedDuration
        )
        // Inserted before a word is spoken: killing the app mid-session must
        // leave a truthful partial record, not nothing (principle 1.5).
        context.insert(newEntry)
        try context.save()

        entry = newEntry
        accumulated = 0
        runningSince = now
        stage = .session
    }

    // MARK: Session clock

    func elapsed(now: Date) -> TimeInterval {
        guard let runningSince else { return accumulated }
        return accumulated + max(now.timeIntervalSince(runningSince), 0)
    }

    var totalDuration: TimeInterval { cueEnds.last ?? 0 }

    func isFinished(now: Date) -> Bool {
        stage == .session && elapsed(now: now) >= totalDuration
    }

    /// Which cue the script is on, or nil once it has run out.
    func currentCueIndex(now: Date) -> Int? {
        let time = elapsed(now: now)
        guard let last = cueEnds.last, time < last else { return nil }
        return cueEnds.firstIndex { time < $0 }
    }

    func currentCue(now: Date) -> PMRCue? {
        currentCueIndex(now: now).map { cues[$0] }
    }

    /// How many muscle groups have been worked through, counting a group done
    /// once its last **working** cue has passed. The pause after it is a seam,
    /// not part of the work.
    func completedGroups(now: Date) -> Int {
        let time = elapsed(now: now)
        return step.groups.reduce(into: 0) { count, group in
            guard
                let index = cues.lastIndex(where: { $0.group == group && $0.phase != .pause })
            else { return }
            if cueEnds[index] <= time { count += 1 }
        }
    }

    /// Position in the script for the meta line: "3 of 4 · torso". Nil for the
    /// cue-controlled step, which has no groups to count.
    func groupPosition(now: Date) -> (index: Int, total: Int, group: PMRMuscleGroup)? {
        guard !step.groups.isEmpty, let group = currentCue(now: now)?.group else { return nil }
        guard let index = step.groups.firstIndex(of: group) else { return nil }
        return (index + 1, step.groups.count, group)
    }

    // MARK: Interruption

    /// A call took the audio. Stop the clock where it is — the seconds spent
    /// listening to a ringtone are not seconds of relaxation.
    func interrupt(now: Date = Date()) {
        guard runningSince != nil else { return }
        accumulated = elapsed(now: now)
        runningSince = nil
        isInterrupted = true
    }

    func resumeAfterInterruption(now: Date = Date()) {
        guard isInterrupted else { return }
        runningSince = now
        isInterrupted = false
    }

    // MARK: Session end

    /// Both endings write the fact and go to "after" — leaving early is data,
    /// not a cancel (principle 1.5), and "did you manage to relax" is a fair
    /// question after a short session too.
    func complete(in context: ModelContext, now: Date = Date()) {
        finish(in: context, duration: plannedDuration, groups: step.groups.count)
    }

    func finishEarly(in context: ModelContext, now: Date = Date()) {
        finish(
            in: context,
            duration: min(Int(elapsed(now: now)), plannedDuration),
            groups: completedGroups(now: now)
        )
    }

    private func finish(in context: ModelContext, duration: Int, groups: Int) {
        guard stage == .session else { return }
        actualDuration = duration
        groupsCompleted = groups
        entry?.actualDurationSeconds = duration
        entry?.groupsCompleted = groups
        try? context.save()
        stage = .after
    }

    // MARK: "After"

    /// Mirrors breathing: "Done" waits for the answer, and closing with the
    /// cross is the escape that still keeps everything already recorded.
    var canSaveAfter: Bool { didRelax != nil }

    var trimmedNote: String {
        note.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// True when the session stopped short of the script — the "after" screen
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
