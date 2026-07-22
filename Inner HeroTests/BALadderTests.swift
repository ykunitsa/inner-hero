//
//  BALadderTests.swift
//  Inner HeroTests
//
//  Coverage for the BA ladder (spec §6): when a basket is suggested, what breaks
//  a run, and the ladder edges.
//

import Foundation
import Testing
@testable import Inner_Hero

// MARK: - Helpers

/// History is newest-first everywhere, as the rules expect.
private func outcomes(
    _ answers: [BAOutcome?],
    effort: BAEffort = .easy
) -> [BALadder.Outcome] {
    answers.map { BALadder.Outcome(effort: effort, outcome: $0) }
}

// MARK: - Step up

@Suite("BA ladder: stepping up")
struct BALadderStepUpTests {

    @Test("Five done in a row offer the next basket up")
    func fiveInARow() {
        let suggestion = BALadder.suggestion(
            history: outcomes([.done, .done, .done, .done, .done]),
            currentBasket: .easy
        )
        #expect(suggestion == .stepUp(.medium))
    }

    @Test("Four is not enough")
    func fourIsNotEnough() {
        let suggestion = BALadder.suggestion(
            history: outcomes([.done, .done, .done, .done]),
            currentBasket: .easy
        )
        #expect(suggestion == nil)
    }

    @Test("A failure inside the run resets it")
    func failureBreaksTheRun() {
        let suggestion = BALadder.suggestion(
            history: outcomes([.done, .done, .couldNot, .done, .done, .done]),
            currentBasket: .easy
        )
        #expect(suggestion == nil)
    }

    @Test("At the top of the ladder there is nothing to offer")
    func topOfLadder() {
        let suggestion = BALadder.suggestion(
            history: outcomes([.done, .done, .done, .done, .done], effort: .hard),
            currentBasket: .hard
        )
        #expect(suggestion == nil)
    }
}

// MARK: - Step down

@Suite("BA ladder: stepping down")
struct BALadderStepDownTests {

    @Test("Two failures in a row offer a step down")
    func twoInARow() {
        let suggestion = BALadder.suggestion(
            history: outcomes([.couldNot, .couldNot], effort: .medium),
            currentBasket: .medium
        )
        #expect(suggestion == .stepDown(.easy))
    }

    @Test("One failure is not enough")
    func oneIsNotEnough() {
        let suggestion = BALadder.suggestion(
            history: outcomes([.couldNot, .done], effort: .medium),
            currentBasket: .medium
        )
        #expect(suggestion == nil)
    }

    @Test("At the bottom of the ladder the rule stays silent")
    func bottomOfLadder() {
        // Two failures on the easy shelf produce nothing rather than something
        // consoling: the app has no useful move here, and inventing one would be
        // advice (principle 1.1).
        let suggestion = BALadder.suggestion(
            history: outcomes([.couldNot, .couldNot]),
            currentBasket: .easy
        )
        #expect(suggestion == nil)
    }
}

// MARK: - What breaks a run

@Suite("BA ladder: runs")
struct BALadderRunTests {

    @Test("An activity from another basket ends the run")
    func otherBasketEndsTheRun() {
        // Newest first: four easy successes, then a success on medium. The run on
        // easy is four, not five — the medium entry stops the prefix.
        var history = outcomes([.done, .done, .done, .done])
        history.append(BALadder.Outcome(effort: .medium, outcome: .done))
        history.append(contentsOf: outcomes([.done, .done]))

        #expect(BALadder.suggestion(history: history, currentBasket: .easy) == nil)
    }

    @Test("Open activities are skipped without breaking the run")
    func openEntriesAreSkipped() {
        // An unanswered tail carries no answer, which is not the same as a
        // failure — it must not silently reset progress.
        let suggestion = BALadder.suggestion(
            history: outcomes([nil, .done, .done, nil, .done, .done, .done]),
            currentBasket: .easy
        )
        #expect(suggestion == .stepUp(.medium))
    }

    @Test("No history means no suggestion")
    func emptyHistory() {
        #expect(BALadder.suggestion(history: [], currentBasket: .easy) == nil)
    }

    @Test("Only open activities means no suggestion")
    func onlyOpenEntries() {
        #expect(BALadder.suggestion(history: outcomes([nil, nil]), currentBasket: .easy) == nil)
    }
}

// MARK: - Ladder shape

@Suite("BA ladder: shape")
struct BALadderShapeTests {

    @Test("Baskets run easiest first")
    func order() {
        #expect(BALadder.baskets == [.easy, .medium, .hard])
        #expect(BAEffort.easy < BAEffort.medium)
        #expect(BAEffort.medium < BAEffort.hard)
    }

    @Test("Energy maps onto baskets one to one")
    func energyMapping() {
        #expect(BAEnergy.almostNone.basket == .easy)
        #expect(BAEnergy.little.basket == .medium)
        #expect(BAEnergy.enough.basket == .hard)
    }

    @Test("Harder baskets wait longer before the reminder")
    func reminderDelays() {
        #expect(BAEffort.easy.reminderDelay < BAEffort.medium.reminderDelay)
        #expect(BAEffort.medium.reminderDelay < BAEffort.hard.reminderDelay)
    }
}
