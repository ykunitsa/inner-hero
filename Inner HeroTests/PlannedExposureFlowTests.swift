//
//  PlannedExposureFlowTests.swift
//  Inner HeroTests
//
//  Coverage for the planned exposure flow (spec §11.2): prediction enums'
//  rawValue contract, the hidden random end, the session clock signals,
//  early finish, and the prediction-block immutability on "after".
//

import Foundation
import Testing
import SwiftData
@testable import Inner_Hero

// MARK: - Helpers

private func makeContext() throws -> ModelContext {
    let container = try ModelContainer(
        for: ExposureLogEntry.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    return ModelContext(container)
}

/// Deterministic RNG (SplitMix64) for the hidden-end tests.
private struct SeededGenerator: RandomNumberGenerator {
    var state: UInt64
    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

@MainActor
private func filledModel(
    generator: any RandomNumberGenerator = SeededGenerator(state: 7)
) -> PlannedExposureFlowViewModel {
    let model = PlannedExposureFlowViewModel(generator: generator)
    model.activity = "  Walk to the park  "
    model.fearedOutcome = "  I'll leave in two minutes  "
    model.confidence = .likely
    return model
}

private let start = Date(timeIntervalSinceReferenceDate: 1_000_000)

// MARK: - Model

@Suite("Prediction enums")
struct PredictionEnumTests {

    @Test("Confidence rawValues are a persistence contract")
    func confidenceRawValuesAreStable() {
        #expect(PredictionConfidence.certain.rawValue == "certain")
        #expect(PredictionConfidence.likely.rawValue == "likely")
        #expect(PredictionConfidence.fiftyFifty.rawValue == "fiftyFifty")
        #expect(PredictionConfidence.unlikely.rawValue == "unlikely")
        #expect(PredictionConfidence.allCases.count == 4)
    }

    @Test("Outcome rawValues are a persistence contract")
    func outcomeRawValuesAreStable() {
        #expect(PredictionOutcome.cameTrue.rawValue == "cameTrue")
        #expect(PredictionOutcome.partially.rawValue == "partially")
        #expect(PredictionOutcome.didNotComeTrue.rawValue == "didNotComeTrue")
        #expect(PredictionOutcome.allCases.count == 3)
    }

    @Test("isPlanned is derived from the prediction, not stored")
    func isPlannedDerived() {
        let situational = ExposureLogEntry(
            createdAt: start, situation: "Metro", anxiety: 5,
            behavior: .stayed, safetyBehaviors: []
        )
        #expect(!situational.isPlanned)

        let planned = ExposureLogEntry(
            plannedAt: start, activity: "Walk", fearedOutcome: "Fear",
            confidence: .certain, expectedAnxiety: 5,
            plannedMinSeconds: 60, plannedMaxSeconds: 120, targetDurationSeconds: 90
        )
        #expect(planned.isPlanned)
        #expect(planned.behavior == nil)
        #expect(planned.anxiety == nil)
        #expect(planned.predictionOutcome == nil)
    }
}

// MARK: - Hidden random end

@Suite("Random target")
struct RandomTargetTests {

    @Test("Always inside the range")
    func targetInsideRange() {
        var generator: any RandomNumberGenerator = SeededGenerator(state: 1)
        for _ in 0..<200 {
            let target = PlannedExposureFlowViewModel.randomTargetSeconds(
                minSeconds: 180, maxSeconds: 480, using: &generator
            )
            #expect((180...480).contains(target))
        }
    }

    @Test("Deterministic under a seeded generator")
    func deterministic() {
        var first: any RandomNumberGenerator = SeededGenerator(state: 42)
        var second: any RandomNumberGenerator = SeededGenerator(state: 42)
        for _ in 0..<20 {
            let a = PlannedExposureFlowViewModel.randomTargetSeconds(
                minSeconds: 60, maxSeconds: 1200, using: &first
            )
            let b = PlannedExposureFlowViewModel.randomTargetSeconds(
                minSeconds: 60, maxSeconds: 1200, using: &second
            )
            #expect(a == b)
        }
    }

    @Test("Degenerate range collapses to the single value")
    func degenerateRange() {
        var generator: any RandomNumberGenerator = SeededGenerator(state: 3)
        let target = PlannedExposureFlowViewModel.randomTargetSeconds(
            minSeconds: 120, maxSeconds: 120, using: &generator
        )
        #expect(target == 120)
    }
}

// MARK: - "Before" stage

@MainActor
@Suite("Planned exposure — before")
struct PlannedExposureBeforeTests {

    @Test("Start requires activity and feared outcome; confidence comes seeded")
    func startValidation() {
        let model = PlannedExposureFlowViewModel()
        // Seeded with the option that claims the least, so the scale shows it
        // wants an answer without asserting one.
        #expect(model.confidence == .fiftyFifty)
        #expect(!model.canStart)

        model.activity = "Walk"
        #expect(!model.canStart)

        model.fearedOutcome = "I'll run away"
        #expect(model.canStart)

        model.activity = "   "
        #expect(!model.canStart)
    }

    @Test("An untouched form is not a draft, despite the seeded confidence")
    func seededConfidenceIsNotADraft() {
        let model = PlannedExposureFlowViewModel()
        #expect(!model.hasBeforeDraft)

        model.confidence = .certain
        #expect(!model.hasBeforeDraft)

        model.activity = "Walk"
        #expect(model.hasBeforeDraft)
    }

    @Test("Start inserts the prediction block; fact columns stay empty")
    func startPersistsPrediction() throws {
        let context = try makeContext()
        let model = filledModel()
        model.rangeMinMinutes = 2
        model.rangeMaxMinutes = 5

        try model.startSession(in: context, now: start)

        let saved = try context.fetch(FetchDescriptor<ExposureLogEntry>())
        let entry = try #require(saved.first)
        #expect(saved.count == 1)
        #expect(entry.createdAt == start)
        #expect(entry.activity == "Walk to the park")
        // The fact column stays empty until "after" — the plan lives in
        // `activity` and is never overwritten by it.
        #expect(entry.situation.isEmpty)
        #expect(entry.fearedOutcome == "I'll leave in two minutes")
        #expect(entry.confidence == .likely)
        #expect(entry.expectedAnxiety == PlannedExposureFlowViewModel.defaultIntensity)
        #expect(entry.plannedMinSeconds == 120)
        #expect(entry.plannedMaxSeconds == 300)
        let target = try #require(entry.targetDurationSeconds)
        #expect((120...300).contains(target))
        // Fact block untouched until "after".
        #expect(entry.behavior == nil)
        #expect(entry.anxiety == nil)
        #expect(entry.actualDurationSeconds == nil)
        #expect(entry.predictionOutcomeRaw == nil)

        #expect(model.stage == .during)
        // "What actually happened" is seeded from the prediction, so the after
        // screen offers the feared sentence to edit into the truth.
        #expect(model.actualSituation == "I'll leave in two minutes")
        #expect(model.targetDuration == TimeInterval(target))
    }

    @Test("Invalid form does not start or write")
    func invalidStartWritesNothing() throws {
        let context = try makeContext()
        let model = PlannedExposureFlowViewModel()

        try model.startSession(in: context, now: start)

        #expect(model.stage == .before)
        #expect(try context.fetch(FetchDescriptor<ExposureLogEntry>()).isEmpty)
    }

    @Test("Last planned range carries over as the default")
    func rangePrefillFromHistory() {
        let older = ExposureLogEntry(
            plannedAt: start.addingTimeInterval(-86_400), activity: "Old", fearedOutcome: "f",
            confidence: .certain, expectedAnxiety: 5,
            plannedMinSeconds: 60, plannedMaxSeconds: 120, targetDurationSeconds: 90
        )
        let newer = ExposureLogEntry(
            plannedAt: start, activity: "New", fearedOutcome: "f",
            confidence: .certain, expectedAnxiety: 5,
            plannedMinSeconds: 300, plannedMaxSeconds: 600, targetDurationSeconds: 400
        )
        let situational = ExposureLogEntry(
            createdAt: start.addingTimeInterval(60), situation: "Metro", anxiety: 5,
            behavior: .stayed, safetyBehaviors: []
        )

        let model = PlannedExposureFlowViewModel()
        model.configure(history: [older, situational, newer])

        #expect(model.rangeMinMinutes == 5)
        #expect(model.rangeMaxMinutes == 10)
    }
}

// MARK: - Session clock

@MainActor
@Suite("Planned exposure — session clock")
struct PlannedExposureClockTests {

    /// Starts a session with a fixed 60-second target (1–1 minute range).
    private func startedModel(in context: ModelContext) throws -> PlannedExposureFlowViewModel {
        let model = filledModel()
        model.rangeMinMinutes = 1
        model.rangeMaxMinutes = 1
        try model.startSession(in: context, now: start)
        #expect(model.targetDuration == 60)
        return model
    }

    @Test("Five countdown ticks, then one distinct end signal")
    func countdownSequence() throws {
        let model = try startedModel(in: makeContext())

        #expect(model.dueSignal(now: start.addingTimeInterval(30)) == nil)
        #expect(model.dueSignal(now: start.addingTimeInterval(54.9)) == nil)

        for secondsLeft in stride(from: 5, through: 1, by: -1) {
            let now = start.addingTimeInterval(TimeInterval(60 - secondsLeft) + 0.2)
            #expect(model.dueSignal(now: now) == .countdownTick, "tick at T-\(secondsLeft)")
            #expect(model.dueSignal(now: now) == nil, "tick fires once")
        }

        #expect(model.dueSignal(now: start.addingTimeInterval(60)) == .sessionEnd)
        #expect(model.dueSignal(now: start.addingTimeInterval(61)) == nil, "end fires once")
    }

    @Test("Return from background produces one catch-up tick, not a burst")
    func catchUpAfterBackground() throws {
        let model = try startedModel(in: makeContext())

        // Jump straight into the countdown window.
        #expect(model.dueSignal(now: start.addingTimeInterval(58.5)) == .countdownTick)
        // T-5…T-2 are marked fired; only T-1 remains.
        #expect(model.dueSignal(now: start.addingTimeInterval(58.7)) == nil)
        #expect(model.dueSignal(now: start.addingTimeInterval(59.4)) == .countdownTick)
        #expect(model.dueSignal(now: start.addingTimeInterval(60.5)) == .sessionEnd)
    }

    @Test("Elapsed is wall-clock and formats as mm:ss")
    func elapsedFormatting() throws {
        let model = try startedModel(in: makeContext())
        #expect(model.elapsed(now: start.addingTimeInterval(83)) == 83)
        #expect(PlannedExposureFlowViewModel.formatElapsed(83) == "01:23")
        #expect(PlannedExposureFlowViewModel.formatElapsed(0) == "00:00")
        #expect(PlannedExposureFlowViewModel.formatElapsed(600) == "10:00")
    }

    @Test("Completed session records the planned target as the fact")
    func completeRecordsTarget() throws {
        let context = try makeContext()
        let model = try startedModel(in: context)

        model.completeSession(in: context, now: start.addingTimeInterval(60.4))

        #expect(model.stage == .after)
        #expect(model.entry?.actualDurationSeconds == 60)
    }

    @Test("Finish early records the elapsed fact, capped at the target")
    func finishEarlyRecordsElapsed() throws {
        let context = try makeContext()
        let model = try startedModel(in: context)

        model.finishEarly(in: context, now: start.addingTimeInterval(23.8))

        #expect(model.stage == .after)
        #expect(model.entry?.actualDurationSeconds == 23)
        let saved = try context.fetch(FetchDescriptor<ExposureLogEntry>())
        #expect(saved.first?.actualDurationSeconds == 23)
    }
}

// MARK: - "After" stage

@MainActor
@Suite("Planned exposure — after")
struct PlannedExposureAfterTests {

    private func modelAtAfterStage(in context: ModelContext) throws -> PlannedExposureFlowViewModel {
        let model = filledModel()
        model.configure(history: [])
        model.rangeMinMinutes = 1
        model.rangeMaxMinutes = 1
        try model.startSession(in: context, now: start)
        model.completeSession(in: context, now: start.addingTimeInterval(60))
        return model
    }

    @Test("Save requires outcome, situation, behavior and a safety answer")
    func afterValidation() throws {
        let context = try makeContext()
        let model = try modelAtAfterStage(in: context)

        // Pre-filled situation from the plan, everything else pending.
        #expect(!model.canSaveAfter)

        model.predictionOutcome = .didNotComeTrue
        #expect(!model.canSaveAfter)

        model.behavior = .stayed
        #expect(!model.canSaveAfter)

        model.toggleNothing()
        #expect(model.canSaveAfter)

        model.actualSituation = "   "
        #expect(!model.canSaveAfter)
    }

    @Test("Save writes the fact block and never touches the prediction")
    func saveWritesFactOnly() throws {
        let context = try makeContext()
        let model = try modelAtAfterStage(in: context)
        model.predictionOutcome = .partially
        model.actualSituation = "  Walked further than planned  "
        model.behavior = .wantedToLeaveButStayed
        model.toggleSafetyBehavior(String(localized: "Phone"))
        model.overallDifficulty = 8

        try model.saveAfter(in: context)

        let entry = try #require(try context.fetch(FetchDescriptor<ExposureLogEntry>()).first)
        #expect(entry.predictionOutcome == .partially)
        #expect(entry.situation == "Walked further than planned")
        #expect(entry.behavior == .wantedToLeaveButStayed)
        #expect(entry.safetyBehaviors == [String(localized: "Phone")])
        #expect(entry.anxiety == 8)
        // Prediction block intact (principle 1.6).
        #expect(entry.fearedOutcome == "I'll leave in two minutes")
        #expect(entry.confidence == .likely)
        #expect(entry.expectedAnxiety == PlannedExposureFlowViewModel.defaultIntensity)
    }

    @Test("Closing keeps the partial record without inventing facts")
    func partialSaveKeepsHonestNils()throws {
        let context = try makeContext()
        let model = try modelAtAfterStage(in: context)

        try model.savePartial(in: context)

        let entry = try #require(try context.fetch(FetchDescriptor<ExposureLogEntry>()).first)
        #expect(entry.predictionOutcomeRaw == nil)
        #expect(entry.behavior == nil)
        #expect(entry.anxiety == nil)
        #expect(entry.actualDurationSeconds == 60)
        #expect(entry.fearedOutcome == "I'll leave in two minutes")
    }

    @Test("Planned and situational entries share one table and one chip pool")
    func sharedTable() throws {
        let context = try makeContext()
        let model = try modelAtAfterStage(in: context)
        model.predictionOutcome = .cameTrue
        model.behavior = .stayed
        model.toggleNothing()
        try model.saveAfter(in: context)

        context.insert(ExposureLogEntry(
            createdAt: start.addingTimeInterval(3600), situation: "Metro", anxiety: 4,
            behavior: .leftEarly, safetyBehaviors: []
        ))
        try context.save()

        let all = try context.fetch(FetchDescriptor<ExposureLogEntry>())
        #expect(all.count == 2)
        let suggestions = SituationalExposureFormViewModel.situationSuggestions(from: all)
        #expect(suggestions == ["Metro", "Walk to the park"])
    }

    @Test("Recording the fact leaves the plan intact")
    func afterBlockDoesNotOverwriteThePlan() throws {
        let context = try makeContext()
        let model = try modelAtAfterStage(in: context)
        // Seeded from the prediction, then edited into what really happened.
        #expect(model.actualSituation == "I'll leave in two minutes")
        model.actualSituation = "Got tense around minute three but stayed"
        model.predictionOutcome = .didNotComeTrue
        model.behavior = .stayed
        model.toggleNothing()
        try model.saveAfter(in: context)

        let entry = try #require(try context.fetch(FetchDescriptor<ExposureLogEntry>()).first)
        #expect(entry.situation == "Got tense around minute three but stayed")
        #expect(entry.activity == "Walk to the park")
        #expect(entry.fearedOutcome == "I'll leave in two minutes")

        // The story of the session must not end up in the activity chips.
        let suggestions = SituationalExposureFormViewModel.situationSuggestions(from: [entry])
        #expect(suggestions == ["Walk to the park"])
    }
}
