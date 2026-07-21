//
//  BreathingLadderTests.swift
//  Inner HeroTests
//
//  Coverage for the ladder rule (spec §4): when a step down or up is offered,
//  what breaks a streak, and what the ladder edges do.
//

import Foundation
import Testing
@testable import Inner_Hero

// MARK: - Helpers

/// History is newest-first everywhere, as the rule expects.
private func outcomes(
    _ answers: [Bool?],
    pattern: BreathingPattern = .box,
    duration: Int = 600
) -> [BreathingLadder.Outcome] {
    answers.map {
        BreathingLadder.Outcome(
            pattern: pattern,
            plannedDurationSeconds: duration,
            didRelax: $0
        )
    }
}

// MARK: - Step down

@Suite("Ladder: stepping down")
struct BreathingLadderStepDownTests {

    @Test("Five relaxed sessions in a row offer the next step down")
    func fiveInARow() {
        let suggestion = BreathingLadder.suggestion(
            history: outcomes([true, true, true, true, true]),
            pattern: .box,
            currentDuration: 600
        )
        #expect(suggestion == .stepDown(seconds: 420))
    }

    @Test("Four is not enough")
    func fourIsNotEnough() {
        let suggestion = BreathingLadder.suggestion(
            history: outcomes([true, true, true, true]),
            pattern: .box,
            currentDuration: 600
        )
        #expect(suggestion == nil)
    }

    @Test("A longer streak keeps offering the same step")
    func sixStillOffers() {
        let suggestion = BreathingLadder.suggestion(
            history: outcomes([true, true, true, true, true, true]),
            pattern: .box,
            currentDuration: 600
        )
        #expect(suggestion == .stepDown(seconds: 420))
    }

    @Test("A failure inside the run resets it")
    func failureBreaksTheRun() {
        let suggestion = BreathingLadder.suggestion(
            history: outcomes([true, true, false, true, true, true]),
            pattern: .box,
            currentDuration: 600
        )
        #expect(suggestion == nil)
    }

    @Test("Nothing to offer at the bottom of the ladder")
    func bottomOfLadder() {
        let suggestion = BreathingLadder.suggestion(
            history: outcomes([true, true, true, true, true], duration: 30),
            pattern: .box,
            currentDuration: 30
        )
        #expect(suggestion == nil)
    }
}

// MARK: - Step up

@Suite("Ladder: stepping up")
struct BreathingLadderStepUpTests {

    @Test("Two failures in a row offer a step back up")
    func twoFailures() {
        let suggestion = BreathingLadder.suggestion(
            history: outcomes([false, false]),
            pattern: .box,
            currentDuration: 600
        )
        #expect(suggestion == .stepUp(seconds: 900))
    }

    @Test("One failure is not enough")
    func oneFailure() {
        let suggestion = BreathingLadder.suggestion(
            history: outcomes([false, true, true]),
            pattern: .box,
            currentDuration: 600
        )
        #expect(suggestion == nil)
    }

    @Test("Nothing to offer at the top of the ladder")
    func topOfLadder() {
        let suggestion = BreathingLadder.suggestion(
            history: outcomes([false, false], duration: 900),
            pattern: .box,
            currentDuration: 900
        )
        #expect(suggestion == nil)
    }
}

// MARK: - What breaks a streak

@Suite("Ladder: streak boundaries")
struct BreathingLadderStreakTests {

    @Test("Sessions of another breathing type don't count")
    func otherPatternIgnored() {
        var history = outcomes([true, true], pattern: .box)
        history += outcomes([true, true, true, true, true], pattern: .fourSix)
        let suggestion = BreathingLadder.suggestion(
            history: history,
            pattern: .box,
            currentDuration: 600
        )
        #expect(suggestion == nil)
    }

    @Test("A streak on one type is invisible to another")
    func streakIsPerPattern() {
        var history = outcomes([true, true, true, true, true], pattern: .fourSix)
        history += outcomes([true, true, true, true, true], pattern: .box)
        let suggestion = BreathingLadder.suggestion(
            history: history,
            pattern: .fourSix,
            currentDuration: 600
        )
        #expect(suggestion == .stepDown(seconds: 420))
    }

    @Test("A session at another duration ends the streak")
    func otherDurationBreaksTheStreak() {
        var history = outcomes([true, true], duration: 600)
        history += outcomes([true], duration: 900)
        history += outcomes([true, true, true], duration: 600)
        let suggestion = BreathingLadder.suggestion(
            history: history,
            pattern: .box,
            currentDuration: 600
        )
        #expect(suggestion == nil)
    }

    @Test("Unanswered sessions are skipped and don't break a streak")
    func unansweredIsSkipped() {
        let suggestion = BreathingLadder.suggestion(
            history: outcomes([true, nil, true, true, nil, true, true]),
            pattern: .box,
            currentDuration: 600
        )
        #expect(suggestion == .stepDown(seconds: 420))
    }

    @Test("A history of only unanswered sessions suggests nothing")
    func onlyUnanswered() {
        let suggestion = BreathingLadder.suggestion(
            history: outcomes([nil, nil, nil, nil, nil]),
            pattern: .box,
            currentDuration: 600
        )
        #expect(suggestion == nil)
    }

    @Test("Empty history suggests nothing")
    func emptyHistory() {
        let suggestion = BreathingLadder.suggestion(
            history: [],
            pattern: .box,
            currentDuration: 900
        )
        #expect(suggestion == nil)
    }
}

// MARK: - Ladder shape

@Suite("Ladder: steps")
struct BreathingLadderStepsTests {

    @Test("The ladder runs 15 down to half a minute, descending")
    func stepsDescend() {
        #expect(BreathingLadder.steps == [900, 600, 420, 300, 180, 120, 60, 30])
        #expect(BreathingLadder.initialDuration == BreathingLadder.steps.first)
    }

    @Test("Neighbours resolve, edges return nil")
    func neighbours() {
        #expect(BreathingLadder.nextStepDown(from: 900) == 600)
        #expect(BreathingLadder.nextStepUp(from: 600) == 900)
        #expect(BreathingLadder.nextStepDown(from: 30) == nil)
        #expect(BreathingLadder.nextStepUp(from: 900) == nil)
    }

    @Test("A duration that isn't on the ladder resolves to nothing")
    func offLadder() {
        #expect(BreathingLadder.nextStepDown(from: 777) == nil)
        #expect(BreathingLadder.nextStepUp(from: 777) == nil)
    }
}
