//
//  PMRFlowTests.swift
//  Inner HeroTests
//
//  Coverage for the PMR flow view model (spec §5): what is written and when,
//  where the script is at a given moment, and that every exit saves.
//

import Foundation
import SwiftData
import Testing
@testable import Inner_Hero

// MARK: - Helpers

private func makeContext() throws -> ModelContext {
    let container = try ModelContainer(
        for: PMRSessionEntry.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    return ModelContext(container)
}

/// A fixed origin, so every offset in these tests is exact.
private let start = Date(timeIntervalSinceReferenceDate: 1_000_000)

// MARK: - Start

@Suite("PMR flow: starting")
@MainActor
struct PMRFlowStartTests {

    @Test("Start inserts the record before a word is spoken")
    func insertsAtStart() throws {
        let context = try makeContext()
        let viewModel = PMRFlowViewModel()
        viewModel.step = .fourGroups

        try viewModel.start(in: context, now: start)

        let entries = try context.fetch(FetchDescriptor<PMRSessionEntry>())
        #expect(entries.count == 1)
        #expect(entries.first?.step == .fourGroups)
        #expect(entries.first?.createdAt == start)
        // Nothing has happened yet, and the record says so.
        #expect(entries.first?.actualDurationSeconds == nil)
        #expect(entries.first?.groupsCompleted == 0)
        #expect(entries.first?.didRelax == nil)
    }

    @Test("Start moves to the session and builds the script")
    func buildsScript() throws {
        let context = try makeContext()
        let viewModel = PMRFlowViewModel()
        viewModel.step = .fourGroups

        try viewModel.start(in: context, now: start)

        #expect(viewModel.stage == .session)
        #expect(viewModel.cues == PMRScript.cues(for: .fourGroups))
        #expect(viewModel.totalDuration == PMRScript.totalDuration(for: .fourGroups))
    }

    @Test("The planned duration is the script's, not a typed-in number")
    func plannedDurationIsDerived() {
        let viewModel = PMRFlowViewModel()
        for step in PMRStep.allCases {
            viewModel.step = step
            #expect(viewModel.plannedDuration == Int(step.estimatedDuration.rounded()))
        }
    }

    @Test("Starting twice does not insert a second record")
    func startIsIdempotent() throws {
        let context = try makeContext()
        let viewModel = PMRFlowViewModel()

        try viewModel.start(in: context, now: start)
        try viewModel.start(in: context, now: start.addingTimeInterval(5))

        #expect(try context.fetch(FetchDescriptor<PMRSessionEntry>()).count == 1)
    }
}

// MARK: - Clock

@Suite("PMR flow: the session clock")
@MainActor
struct PMRFlowClockTests {

    private func started() throws -> (PMRFlowViewModel, ModelContext) {
        let context = try makeContext()
        let viewModel = PMRFlowViewModel()
        viewModel.step = .fourGroups
        try viewModel.start(in: context, now: start)
        return (viewModel, context)
    }

    @Test("Elapsed time follows the injected clock")
    func elapsedFollowsClock() throws {
        let (viewModel, _) = try started()
        #expect(viewModel.elapsed(now: start) == 0)
        #expect(viewModel.elapsed(now: start.addingTimeInterval(30)) == 30)
    }

    @Test("The script opens on the intro cue")
    func opensOnIntro() throws {
        let (viewModel, _) = try started()
        #expect(viewModel.currentCue(now: start)?.phase == .intro)
    }

    @Test("The cue advances with the clock")
    func cueAdvances() throws {
        let (viewModel, _) = try started()
        let timings = PMRScript.Timings.canonical

        // Just past the intro: the first group is being tensed.
        let intoFirstTense = start.addingTimeInterval(timings.intro + 1)
        let first = viewModel.currentCue(now: intoFirstTense)
        #expect(first?.phase == .tense)
        #expect(first?.group == .arms)

        // Past the tension: the same group, now releasing.
        let intoFirstRelease = start.addingTimeInterval(timings.intro + timings.tense + 1)
        let second = viewModel.currentCue(now: intoFirstRelease)
        #expect(second?.phase == .release)
        #expect(second?.group == .arms)
    }

    @Test("The cue runs out exactly when the script does")
    func cueRunsOut() throws {
        let (viewModel, _) = try started()
        let end = start.addingTimeInterval(viewModel.totalDuration)
        #expect(viewModel.currentCue(now: end) == nil)
        #expect(viewModel.isFinished(now: end))
        #expect(!viewModel.isFinished(now: end.addingTimeInterval(-1)))
    }

    @Test("The group position reads as 'n of total'")
    func groupPosition() throws {
        let (viewModel, _) = try started()
        let timings = PMRScript.Timings.canonical
        let intoFirst = start.addingTimeInterval(timings.intro + 1)

        let position = viewModel.groupPosition(now: intoFirst)
        #expect(position?.index == 1)
        #expect(position?.total == 4)
        #expect(position?.group == .arms)
    }

    /// The cue-controlled step has no groups, so there is no "n of total" to
    /// show — the meta line must be absent rather than reading "0 of 0".
    @Test("The cue-controlled step reports no group position")
    func cueControlledHasNoPosition() throws {
        let context = try makeContext()
        let viewModel = PMRFlowViewModel()
        viewModel.step = .cueControlled
        try viewModel.start(in: context, now: start)

        #expect(viewModel.groupPosition(now: start.addingTimeInterval(30)) == nil)
    }

    @Test("No groups are complete at the start, all are at the end")
    func completedGroups() throws {
        let (viewModel, _) = try started()
        #expect(viewModel.completedGroups(now: start) == 0)
        let end = start.addingTimeInterval(viewModel.totalDuration)
        #expect(viewModel.completedGroups(now: end) == 4)
    }
}

// MARK: - Interruption

@Suite("PMR flow: interruption")
@MainActor
struct PMRFlowInterruptionTests {

    @Test("An interruption stops the clock where it is")
    func interruptionStopsTheClock() throws {
        let context = try makeContext()
        let viewModel = PMRFlowViewModel()
        try viewModel.start(in: context, now: start)

        viewModel.interrupt(now: start.addingTimeInterval(60))
        #expect(viewModel.isInterrupted)
        // A minute of ringtone is not a minute of relaxation.
        #expect(viewModel.elapsed(now: start.addingTimeInterval(300)) == 60)
    }

    @Test("Resuming restarts the clock from where it stopped")
    func resumeContinues() throws {
        let context = try makeContext()
        let viewModel = PMRFlowViewModel()
        try viewModel.start(in: context, now: start)

        viewModel.interrupt(now: start.addingTimeInterval(60))
        viewModel.resumeAfterInterruption(now: start.addingTimeInterval(300))

        #expect(!viewModel.isInterrupted)
        #expect(viewModel.elapsed(now: start.addingTimeInterval(310)) == 70)
    }
}

// MARK: - Ending

@Suite("PMR flow: ending")
@MainActor
struct PMRFlowEndTests {

    @Test("Completing writes the full plan and every group")
    func completeWritesPlan() throws {
        let context = try makeContext()
        let viewModel = PMRFlowViewModel()
        viewModel.step = .fourGroups
        try viewModel.start(in: context, now: start)

        viewModel.complete(in: context, now: start.addingTimeInterval(viewModel.totalDuration))

        #expect(viewModel.stage == .after)
        #expect(!viewModel.didFinishEarly)
        #expect(viewModel.entry?.actualDurationSeconds == viewModel.plannedDuration)
        #expect(viewModel.entry?.groupsCompleted == 4)
    }

    /// Principle 1.5: leaving early is a fact to record, never a cancel.
    @Test("Ending early writes the actual time and still asks the question")
    func finishEarlyWritesFact() throws {
        let context = try makeContext()
        let viewModel = PMRFlowViewModel()
        viewModel.step = .fourGroups
        try viewModel.start(in: context, now: start)

        viewModel.finishEarly(in: context, now: start.addingTimeInterval(90))

        #expect(viewModel.stage == .after)
        #expect(viewModel.didFinishEarly)
        #expect(viewModel.entry?.actualDurationSeconds == 90)
        // Ninety seconds is inside the first group — nothing was finished.
        #expect(viewModel.entry?.groupsCompleted == 0)
    }

    @Test("Ending early never records more than was planned")
    func finishEarlyIsClamped() throws {
        let context = try makeContext()
        let viewModel = PMRFlowViewModel()
        try viewModel.start(in: context, now: start)

        viewModel.finishEarly(in: context, now: start.addingTimeInterval(99_999))

        #expect(viewModel.entry?.actualDurationSeconds == viewModel.plannedDuration)
    }
}

// MARK: - "After"

@Suite("PMR flow: the after screen")
@MainActor
struct PMRFlowAfterTests {

    private func finished() throws -> (PMRFlowViewModel, ModelContext) {
        let context = try makeContext()
        let viewModel = PMRFlowViewModel()
        viewModel.step = .fourGroups
        try viewModel.start(in: context, now: start)
        viewModel.complete(in: context, now: start.addingTimeInterval(viewModel.totalDuration))
        return (viewModel, context)
    }

    @Test("Done waits for the answer")
    func doneWaitsForAnswer() throws {
        let (viewModel, _) = try finished()
        #expect(!viewModel.canSaveAfter)
        viewModel.didRelax = false
        #expect(viewModel.canSaveAfter)
    }

    @Test("Saving writes the answer and the note")
    func savesAnswerAndNote() throws {
        let (viewModel, context) = try finished()
        viewModel.didRelax = true
        viewModel.note = "  shoulders stayed tight  "

        try viewModel.saveAfter(in: context)

        #expect(viewModel.entry?.didRelax == true)
        #expect(viewModel.entry?.note == "shoulders stayed tight")
    }

    @Test("A blank note is stored as nothing, not as an empty string")
    func blankNoteIsNil() throws {
        let (viewModel, context) = try finished()
        viewModel.didRelax = true
        viewModel.note = "   "

        try viewModel.saveAfter(in: context)

        #expect(viewModel.entry?.note == nil)
    }

    /// Closing without answering keeps the session — and keeps "unanswered"
    /// distinguishable from "no", which the ladder rule depends on.
    @Test("Closing without answering keeps the session and stays unanswered")
    func partialSaveKeepsUnanswered() throws {
        let (viewModel, context) = try finished()

        try viewModel.savePartial(in: context)

        let entries = try context.fetch(FetchDescriptor<PMRSessionEntry>())
        #expect(entries.count == 1)
        #expect(entries.first?.didRelax == nil)
        #expect(entries.first?.actualDurationSeconds != nil)
    }
}

// MARK: - Suggestion

@Suite("PMR flow: the ladder suggestion")
@MainActor
struct PMRFlowSuggestionTests {

    private func history(count: Int, didRelax: Bool, step: PMRStep) -> [PMRSessionEntry] {
        (0..<count).map { index in
            let entry = PMRSessionEntry(
                createdAt: start.addingTimeInterval(TimeInterval(-index)),
                step: step,
                plannedDurationSeconds: Int(step.estimatedDuration)
            )
            entry.actualDurationSeconds = Int(step.estimatedDuration)
            entry.didRelax = didRelax
            return entry
        }
    }

    @Test("The last used step is seeded from history")
    func seedsLastStep() {
        let viewModel = PMRFlowViewModel()
        viewModel.configure(history: history(count: 1, didRelax: true, step: .sevenGroups))
        #expect(viewModel.step == .sevenGroups)
    }

    @Test("A first-ever session starts at four groups")
    func firstSessionStartsAtFour() {
        let viewModel = PMRFlowViewModel()
        viewModel.configure(history: [])
        #expect(viewModel.step == .fourGroups)
    }

    @Test("Five relaxed sessions surface the step-down suggestion")
    func surfacesSuggestion() {
        let viewModel = PMRFlowViewModel()
        viewModel.configure(history: history(count: 5, didRelax: true, step: .fourGroups))
        #expect(viewModel.suggestion == .stepDown(.fourGroupsRecall))
    }

    /// Principle 1.8: the rule proposes, it never changes the setting itself.
    @Test("The suggestion does not change the step until it is applied")
    func suggestionIsInert() {
        let viewModel = PMRFlowViewModel()
        viewModel.configure(history: history(count: 5, didRelax: true, step: .fourGroups))

        #expect(viewModel.step == .fourGroups)

        viewModel.applySuggestion()

        #expect(viewModel.step == .fourGroupsRecall)
        #expect(viewModel.suggestion == nil)
    }
}
