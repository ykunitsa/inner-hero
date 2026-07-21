//
//  BreathingFlowTests.swift
//  Inner HeroTests
//
//  Coverage for the breathing flow view model (spec §4, §11.3): the entry is
//  inserted at "Start", the pause stops the clock, and every exit leaves a
//  truthful record rather than cancelling one.
//

import Foundation
import Testing
import SwiftData
@testable import Inner_Hero

// MARK: - Helpers

private func makeContext() throws -> ModelContext {
    let container = try ModelContainer(
        for: BreathingSessionEntry.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    return ModelContext(container)
}

private let start = Date(timeIntervalSinceReferenceDate: 1_000_000)

// MARK: - Start

@Suite("Breathing flow: start")
@MainActor
struct BreathingFlowStartTests {

    @Test("Starting inserts the plan into the store before a single breath")
    func startInsertsEntry() throws {
        let context = try makeContext()
        let model = BreathingFlowViewModel()
        model.pattern = .fourSix
        model.plannedDuration = 300

        try model.start(in: context, now: start)

        #expect(model.stage == .session)
        let stored = try context.fetch(FetchDescriptor<BreathingSessionEntry>())
        #expect(stored.count == 1)
        #expect(stored.first?.pattern == .fourSix)
        #expect(stored.first?.plannedDurationSeconds == 300)
        // Not finished yet — the truthful state of a session in progress.
        #expect(stored.first?.actualDurationSeconds == nil)
        #expect(stored.first?.didRelax == nil)
        #expect(stored.first?.wasPaused == false)
    }

    @Test("Starting twice does not create a second entry")
    func startIsIdempotent() throws {
        let context = try makeContext()
        let model = BreathingFlowViewModel()

        try model.start(in: context, now: start)
        try model.start(in: context, now: start.addingTimeInterval(5))

        #expect(try context.fetch(FetchDescriptor<BreathingSessionEntry>()).count == 1)
    }

    @Test("A first-ever session starts at the top of the ladder")
    func defaultsForFirstSession() {
        let model = BreathingFlowViewModel()
        model.configure(history: [])

        #expect(model.plannedDuration == BreathingLadder.initialDuration)
        #expect(model.pattern == .box)
        #expect(model.suggestion == nil)
    }

    @Test("The last session's type and duration carry over")
    func lastSessionCarriesOver() {
        let previous = BreathingSessionEntry(
            createdAt: start,
            pattern: .rhythmic,
            plannedDurationSeconds: 180
        )
        let model = BreathingFlowViewModel()
        model.configure(history: [previous])

        #expect(model.pattern == .rhythmic)
        #expect(model.plannedDuration == 180)
    }
}

// MARK: - Clock

@Suite("Breathing flow: clock")
@MainActor
struct BreathingFlowClockTests {

    @Test("Elapsed and remaining track the session clock")
    func clockRuns() throws {
        let context = try makeContext()
        let model = BreathingFlowViewModel()
        model.plannedDuration = 600
        try model.start(in: context, now: start)

        #expect(model.elapsed(now: start.addingTimeInterval(90)) == 90)
        #expect(model.remaining(now: start.addingTimeInterval(90)) == 510)
        #expect(model.isFinished(now: start.addingTimeInterval(599)) == false)
        #expect(model.isFinished(now: start.addingTimeInterval(600)))
    }

    @Test("Pause stops the clock and resume picks it back up")
    func pauseStopsTheClock() throws {
        let context = try makeContext()
        let model = BreathingFlowViewModel()
        model.plannedDuration = 600
        try model.start(in: context, now: start)

        model.togglePause(now: start.addingTimeInterval(60))
        #expect(model.isPaused)
        // Sixty seconds of wall clock pass while paused — none of them count.
        #expect(model.elapsed(now: start.addingTimeInterval(120)) == 60)

        model.togglePause(now: start.addingTimeInterval(120))
        #expect(model.isPaused == false)
        #expect(model.elapsed(now: start.addingTimeInterval(150)) == 90)
    }

    @Test("Pause is recorded on the entry")
    func pauseIsRecorded() throws {
        let context = try makeContext()
        let model = BreathingFlowViewModel()
        try model.start(in: context, now: start)

        #expect(model.entry?.wasPaused == false)
        model.togglePause(now: start.addingTimeInterval(10))
        #expect(model.wasPaused)
        #expect(model.entry?.wasPaused == true)

        // Resuming does not erase the fact that a pause happened.
        model.togglePause(now: start.addingTimeInterval(20))
        #expect(model.entry?.wasPaused == true)
    }

    @Test("Remaining time is formatted as mm:ss and rounds up")
    func formatting() {
        #expect(BreathingFlowViewModel.formatRemaining(600) == "10:00")
        #expect(BreathingFlowViewModel.formatRemaining(59.2) == "01:00")
        #expect(BreathingFlowViewModel.formatRemaining(0) == "00:00")
        #expect(BreathingFlowViewModel.formatRemaining(-5) == "00:00")
    }
}

// MARK: - Ending

@Suite("Breathing flow: ending")
@MainActor
struct BreathingFlowEndTests {

    @Test("Running out writes the planned duration and moves to the question")
    func completeWritesDuration() throws {
        let context = try makeContext()
        let model = BreathingFlowViewModel()
        model.plannedDuration = 600
        try model.start(in: context, now: start)

        model.complete(in: context, now: start.addingTimeInterval(600))

        #expect(model.stage == .after)
        #expect(model.entry?.actualDurationSeconds == 600)
        #expect(model.didFinishEarly == false)
    }

    @Test("Finishing early saves the real duration and still asks the question")
    func finishEarlySaves() throws {
        let context = try makeContext()
        let model = BreathingFlowViewModel()
        model.plannedDuration = 600
        try model.start(in: context, now: start)

        model.finishEarly(in: context, now: start.addingTimeInterval(240))

        // Not a cancel: the record stands and the flow goes on to "after"
        // (principle 1.5).
        #expect(model.stage == .after)
        #expect(model.entry?.actualDurationSeconds == 240)
        #expect(model.didFinishEarly)
    }

    @Test("Answering writes the answer and the note")
    func saveAfter() throws {
        let context = try makeContext()
        let model = BreathingFlowViewModel()
        try model.start(in: context, now: start)
        model.complete(in: context, now: start.addingTimeInterval(900))

        model.didRelax = true
        model.note = "  quieter than last time  "
        try model.saveAfter(in: context)

        #expect(model.entry?.didRelax == true)
        #expect(model.entry?.note == "quieter than last time")
    }

    @Test("Closing without answering keeps the partial record")
    func savePartial() throws {
        let context = try makeContext()
        let model = BreathingFlowViewModel()
        model.plannedDuration = 300
        try model.start(in: context, now: start)
        model.finishEarly(in: context, now: start.addingTimeInterval(100))

        #expect(model.canSaveAfter == false)
        try model.savePartial(in: context)

        let stored = try context.fetch(FetchDescriptor<BreathingSessionEntry>())
        #expect(stored.count == 1)
        #expect(stored.first?.actualDurationSeconds == 100)
        // No answer is nil, not "no" — the ladder rule skips it.
        #expect(stored.first?.didRelax == nil)
        #expect(stored.first?.note == nil)
    }
}

// MARK: - Suggestion

@Suite("Breathing flow: ladder suggestion")
@MainActor
struct BreathingFlowSuggestionTests {

    private func history(count: Int, didRelax: Bool) -> [BreathingSessionEntry] {
        (0..<count).map { index in
            let entry = BreathingSessionEntry(
                createdAt: start.addingTimeInterval(TimeInterval(-index * 86_400)),
                pattern: .box,
                plannedDurationSeconds: 600
            )
            entry.didRelax = didRelax
            return entry
        }
    }

    @Test("A five-session streak surfaces the suggestion on configure")
    func suggestionAppears() {
        let model = BreathingFlowViewModel()
        model.configure(history: history(count: 5, didRelax: true))

        #expect(model.suggestion == .stepDown(seconds: 420))
    }

    @Test("Accepting the suggestion moves the duration and clears the line")
    func applySuggestion() {
        let model = BreathingFlowViewModel()
        model.configure(history: history(count: 5, didRelax: true))

        model.applySuggestion()

        #expect(model.plannedDuration == 420)
        #expect(model.suggestion == nil)
    }

    @Test("The suggestion is recomputed when the type changes")
    func suggestionFollowsPattern() {
        let model = BreathingFlowViewModel()
        let entries = history(count: 5, didRelax: true)
        model.configure(history: entries)
        #expect(model.suggestion != nil)

        model.pattern = .fourSix
        model.refreshSuggestion(history: entries)
        // The streak belongs to box breathing and says nothing about 4-6.
        #expect(model.suggestion == nil)
    }
}
