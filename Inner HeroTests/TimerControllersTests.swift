//
//  TimerControllersTests.swift
//  Inner HeroTests
//
//  Pure-logic coverage for BreathingController.BreathPhase durations and
//  phase transitions — the parts that don't depend on wall-clock ticking.
//

import Foundation
import Testing
@testable import Inner_Hero

@Suite("BreathingController.BreathPhase")
struct BreathPhaseTests {

    typealias Phase = BreathingController.BreathPhase

    // MARK: - Durations

    @Test("Box pattern uses 4s for every phase")
    func boxDurations() {
        for phase: Phase in [.inhale, .hold, .exhale, .rest] {
            #expect(phase.duration(for: .box) == 4.0)
        }
    }

    @Test(
        "4-6 pattern: 4s inhale, 6s exhale, no holds",
        arguments: zip(
            [Phase.inhale, .exhale, .hold, .rest],
            [4.0, 6.0, 0.0, 0.0]
        )
    )
    func fourSixDurations(phase: Phase, expected: TimeInterval) {
        #expect(phase.duration(for: .fourSix) == expected)
    }

    @Test(
        "Paced pattern: 5s inhale/exhale with 1s holds",
        arguments: zip(
            [Phase.inhale, .hold, .exhale, .rest],
            [5.0, 1.0, 5.0, 1.0]
        )
    )
    func pacedDurations(phase: Phase, expected: TimeInterval) {
        #expect(phase.duration(for: .paced) == expected)
    }

    // MARK: - Transitions

    @Test("Box cycles inhale → hold → exhale → rest → inhale")
    func boxTransitions() {
        #expect(Phase.inhale.next(for: .box) == .hold)
        #expect(Phase.hold.next(for: .box) == .exhale)
        #expect(Phase.exhale.next(for: .box) == .rest)
        #expect(Phase.rest.next(for: .box) == .inhale)
    }

    @Test("4-6 cycles inhale → exhale → inhale")
    func fourSixTransitions() {
        #expect(Phase.inhale.next(for: .fourSix) == .exhale)
        #expect(Phase.exhale.next(for: .fourSix) == .inhale)
        // Zero-duration phases route back to inhale.
        #expect(Phase.hold.next(for: .fourSix) == .inhale)
        #expect(Phase.rest.next(for: .fourSix) == .inhale)
    }

    @Test("Paced cycles inhale → hold → exhale → rest → inhale")
    func pacedTransitions() {
        #expect(Phase.inhale.next(for: .paced) == .hold)
        #expect(Phase.hold.next(for: .paced) == .exhale)
        #expect(Phase.exhale.next(for: .paced) == .rest)
        #expect(Phase.rest.next(for: .paced) == .inhale)
    }
}
