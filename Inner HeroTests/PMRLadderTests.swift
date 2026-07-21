//
//  PMRLadderTests.swift
//  Inner HeroTests
//
//  Coverage for the PMR ladder (spec §5): when a step is suggested, what breaks
//  a run, the ladder edges, and the one medal in the app.
//

import Foundation
import Testing
@testable import Inner_Hero

// MARK: - Helpers

/// History is newest-first everywhere, as the rules expect.
private func outcomes(
    _ answers: [Bool?],
    step: PMRStep = .fourGroups,
    finishedEarly: Bool = false
) -> [PMRLadder.Outcome] {
    answers.map {
        PMRLadder.Outcome(step: step, didRelax: $0, didFinishEarly: finishedEarly)
    }
}

// MARK: - Step down

@Suite("PMR ladder: stepping down")
struct PMRLadderStepDownTests {

    @Test("Five relaxed sessions in a row offer the next step down")
    func fiveInARow() {
        let suggestion = PMRLadder.suggestion(
            history: outcomes([true, true, true, true, true]),
            currentStep: .fourGroups
        )
        #expect(suggestion == .stepDown(.fourGroupsRecall))
    }

    @Test("Four is not enough")
    func fourIsNotEnough() {
        let suggestion = PMRLadder.suggestion(
            history: outcomes([true, true, true, true]),
            currentStep: .fourGroups
        )
        #expect(suggestion == nil)
    }

    @Test("Nothing is offered at the bottom of the ladder")
    func bottomOfLadder() {
        let suggestion = PMRLadder.suggestion(
            history: outcomes([true, true, true, true, true], step: .cueControlled),
            currentStep: .cueControlled
        )
        #expect(suggestion == nil)
    }
}

// MARK: - Step up

@Suite("PMR ladder: stepping up")
struct PMRLadderStepUpTests {

    @Test("Two unrelaxed sessions in a row offer a step back up")
    func twoInARow() {
        let suggestion = PMRLadder.suggestion(
            history: outcomes([false, false]),
            currentStep: .fourGroups
        )
        #expect(suggestion == .stepUp(.sevenGroups))
    }

    @Test("One is not enough")
    func oneIsNotEnough() {
        let suggestion = PMRLadder.suggestion(
            history: outcomes([false]),
            currentStep: .fourGroups
        )
        #expect(suggestion == nil)
    }

    @Test("Nothing is offered at the top of the ladder")
    func topOfLadder() {
        let suggestion = PMRLadder.suggestion(
            history: outcomes([false, false], step: .sixteenGroups),
            currentStep: .sixteenGroups
        )
        #expect(suggestion == nil)
    }
}

// MARK: - What breaks a run

@Suite("PMR ladder: what breaks a run")
struct PMRLadderRunTests {

    @Test("Empty history suggests nothing")
    func emptyHistory() {
        #expect(PMRLadder.suggestion(history: [], currentStep: .fourGroups) == nil)
    }

    /// Unanswered is not a negative answer — it carries no information, so it is
    /// skipped rather than counted against the user.
    @Test("Unanswered sessions are skipped, not counted as failures")
    func unansweredIsSkipped() {
        let suggestion = PMRLadder.suggestion(
            history: outcomes([true, nil, true, true, nil, true, true]),
            currentStep: .fourGroups
        )
        #expect(suggestion == .stepDown(.fourGroupsRecall))
    }

    /// The spec counts "in a row on the current step", so a session on another
    /// step ends the run rather than being filtered out of it.
    @Test("A session on another step ends the run")
    func otherStepEndsTheRun() {
        let history =
            outcomes([true, true]) + outcomes([true], step: .sevenGroups) + outcomes([true, true])
        #expect(PMRLadder.suggestion(history: history, currentStep: .fourGroups) == nil)
    }

    @Test("A mixed run counts only the latest answers")
    func mixedRun() {
        let suggestion = PMRLadder.suggestion(
            history: outcomes([false, false, true, true, true, true, true]),
            currentStep: .fourGroups
        )
        #expect(suggestion == .stepUp(.sevenGroups))
    }
}

// MARK: - Edges

@Suite("PMR ladder: steps")
struct PMRLadderStepsTests {

    @Test("The ladder holds every step exactly once, hardest first")
    func ladderShape() {
        #expect(PMRLadder.steps.count == PMRStep.allCases.count)
        #expect(Set(PMRLadder.steps).count == PMRLadder.steps.count)
        #expect(PMRLadder.steps.first == .sixteenGroups)
        #expect(PMRLadder.steps.last == .cueControlled)
    }

    /// Descending the ladder means needing less of the script — if a rung ever
    /// takes longer than the one above it, the ladder is telling the user the
    /// opposite of the truth.
    @Test("Each step down is shorter than the one above it")
    func stepsGetShorter() {
        let durations = PMRLadder.steps.map(\.estimatedDuration)
        for (shorter, longer) in zip(durations.dropFirst(), durations) {
            #expect(shorter < longer)
        }
    }

    @Test("A first session starts at four groups, not at the top")
    func initialStep() {
        #expect(PMRLadder.initialStep == .fourGroups)
    }

    @Test("Walking down and back up returns to the same step")
    func walkIsSymmetric() {
        for step in PMRStep.allCases {
            if let down = PMRLadder.nextStepDown(from: step) {
                #expect(PMRLadder.nextStepUp(from: down) == step)
            }
        }
    }
}

// MARK: - Medal

@Suite("PMR: the one medal")
struct PMRMedalTests {

    @Test("A step worked end to end earns its medal")
    func workedStepEarnsMedal() {
        let medals = PMRLadder.earnedMedals(history: outcomes([true], step: .fourGroups))
        #expect(medals == [.fourGroups])
    }

    /// Leaving early is data, not failure (principle 1.5) — it earns nothing,
    /// but it is not held against the user either.
    @Test("A session that ended early earns nothing")
    func earlyExitEarnsNothing() {
        let medals = PMRLadder.earnedMedals(
            history: outcomes([true], step: .fourGroups, finishedEarly: true)
        )
        #expect(medals.isEmpty)
    }

    /// Spec §5: "Не отнимается при спуске."
    @Test("A medal is not taken away by later sessions on an easier step")
    func medalSurvivesRegression() {
        let history =
            outcomes([false, false], step: .sevenGroups) + outcomes([true], step: .fourGroups)
        #expect(PMRLadder.earnedMedals(history: history).contains(.fourGroups))
    }

    /// The medal is for having worked the step, not for having enjoyed it —
    /// tying it to `didRelax` would make an honest "no" cost the user something.
    @Test("The medal does not depend on the relaxation answer")
    func medalIgnoresDidRelax() {
        #expect(PMRLadder.earnedMedals(history: outcomes([false])) == [.fourGroups])
        #expect(PMRLadder.earnedMedals(history: outcomes([nil])) == [.fourGroups])
    }

    @Test("Nothing is earned in advance")
    func nothingEarnedInAdvance() {
        #expect(PMRLadder.earnedMedals(history: []).isEmpty)
        let medals = PMRLadder.earnedMedals(history: outcomes([true], step: .fourGroups))
        #expect(!medals.contains(.fourGroupsRecall))
        #expect(!medals.contains(.cueControlled))
    }
}
