//
//  BreathingPhaseTests.swift
//  Inner HeroTests
//
//  Coverage for the phase engine (spec §4) and the haptic curve (plan §5).
//  Both are pure functions of elapsed time — no clock, no engine.
//

import Foundation
import Testing
@testable import Inner_Hero

// MARK: - Phase engine

@Suite("Breathing phases")
struct BreathingPhaseEngineTests {

    @Test("Box breathing walks four phases of four seconds")
    func boxCycle() {
        let pattern = BreathingPattern.box
        #expect(pattern.cycleDuration == 16)
        #expect(pattern.phase(at: 0).phase == .inhale)
        #expect(pattern.phase(at: 3.9).phase == .inhale)
        #expect(pattern.phase(at: 4).phase == .holdAfterInhale)
        #expect(pattern.phase(at: 8).phase == .exhale)
        #expect(pattern.phase(at: 12).phase == .holdAfterExhale)
        #expect(pattern.phase(at: 15.9).phase == .holdAfterExhale)
    }

    @Test("4-6 has no holds and a six-second exhale")
    func fourSixCycle() {
        let pattern = BreathingPattern.fourSix
        #expect(pattern.cycleDuration == 10)
        #expect(pattern.hasHolds == false)
        #expect(pattern.phase(at: 0).phase == .inhale)
        #expect(pattern.phase(at: 4).phase == .exhale)
        #expect(pattern.phase(at: 9.9).phase == .exhale)
    }

    @Test("Rhythmic is an even four-four cycle")
    func rhythmicCycle() {
        let pattern = BreathingPattern.rhythmic
        #expect(pattern.cycleDuration == 8)
        #expect(pattern.hasHolds == false)
        #expect(pattern.phase(at: 0).phase == .inhale)
        #expect(pattern.phase(at: 4).phase == .exhale)
    }

    @Test("The cycle repeats")
    func cycleRepeats() {
        let pattern = BreathingPattern.box
        for offset in stride(from: 0.0, to: 16.0, by: 0.5) {
            #expect(pattern.phase(at: offset).phase == pattern.phase(at: offset + 16).phase)
            #expect(
                abs(pattern.phase(at: offset).progress - pattern.phase(at: offset + 16).progress)
                    < 0.0001
            )
        }
    }

    @Test("Progress runs 0 to 1 inside a phase and resets at the boundary")
    func progressWithinPhase() {
        let pattern = BreathingPattern.box
        #expect(pattern.phase(at: 0).progress == 0)
        #expect(abs(pattern.phase(at: 2).progress - 0.5) < 0.0001)
        #expect(pattern.phase(at: 4).progress == 0)
        #expect(abs(pattern.phase(at: 6).progress - 0.5) < 0.0001)
    }

    @Test("Progress increases monotonically inside a phase")
    func progressIsMonotonic() {
        let pattern = BreathingPattern.fourSix
        var previous = -1.0
        for offset in stride(from: 4.0, to: 10.0, by: 0.25) {
            let progress = pattern.phase(at: offset).progress
            #expect(progress > previous)
            previous = progress
        }
    }

    @Test("Negative and zero elapsed both sit at the start of the inhale")
    func beforeStart() {
        let pattern = BreathingPattern.box
        #expect(pattern.phase(at: -5).phase == .inhale)
        #expect(pattern.phase(at: -5).progress == 0)
        #expect(pattern.phase(at: 0).phase == .inhale)
    }

    @Test("Persisted rawValues are unchanged")
    func rawValues() {
        #expect(BreathingPattern.box.rawValue == "box")
        #expect(BreathingPattern.fourSix.rawValue == "fourSix")
        #expect(BreathingPattern.rhythmic.rawValue == "rhythmic")
    }
}

// MARK: - Haptic curve

@Suite("Breathing haptics")
struct BreathingHapticCurveTests {

    @Test("The inhale ramp rises fast and fades to nothing")
    func inhaleRamp() {
        let start = BreathingHaptics.intensity(pattern: .box, phase: .inhale, progress: 0)
        let peak = BreathingHaptics.intensity(pattern: .box, phase: .inhale, progress: 0.4)
        let end = BreathingHaptics.intensity(pattern: .box, phase: .inhale, progress: 1)

        #expect(start == 0)
        #expect(peak > 0.99)
        #expect(end < 0.01)
        // Rises faster than it falls: a quarter in is already stronger than a
        // quarter from the end.
        let early = BreathingHaptics.intensity(pattern: .box, phase: .inhale, progress: 0.25)
        let late = BreathingHaptics.intensity(pattern: .box, phase: .inhale, progress: 0.75)
        #expect(early > late)
    }

    @Test("The inhale ramp is monotonic on each side of the peak")
    func inhaleRampShape() {
        var previous: Float = -1
        for step in stride(from: 0.0, through: 0.4, by: 0.05) {
            let value = BreathingHaptics.intensity(pattern: .box, phase: .inhale, progress: step)
            #expect(value >= previous)
            previous = value
        }
        previous = 2
        for step in stride(from: 0.4, through: 1.0, by: 0.05) {
            let value = BreathingHaptics.intensity(pattern: .box, phase: .inhale, progress: step)
            #expect(value <= previous)
            previous = value
        }
    }

    @Test("The box exhale is the inhale mirrored")
    func exhaleIsMirrored() {
        for step in stride(from: 0.0, through: 1.0, by: 0.1) {
            let inhale = BreathingHaptics.intensity(pattern: .box, phase: .inhale, progress: step)
            let exhale = BreathingHaptics.intensity(pattern: .box, phase: .exhale, progress: 1 - step)
            #expect(abs(inhale - exhale) < 0.0001)
        }
        // Starts strong, ends weak — the opposite of the inhale, or the two
        // would be indistinguishable by feel.
        let exhaleStart = BreathingHaptics.intensity(pattern: .box, phase: .exhale, progress: 0)
        let exhaleEnd = BreathingHaptics.intensity(pattern: .box, phase: .exhale, progress: 1)
        #expect(exhaleStart < 0.01)
        #expect(exhaleEnd == 0)
        #expect(BreathingHaptics.intensity(pattern: .box, phase: .exhale, progress: 0.6) > 0.99)
    }

    @Test("Holds are silent")
    func holdsAreSilent() {
        for step in stride(from: 0.0, through: 1.0, by: 0.1) {
            #expect(
                BreathingHaptics.intensity(pattern: .box, phase: .holdAfterInhale, progress: step) == 0
            )
            #expect(
                BreathingHaptics.intensity(pattern: .box, phase: .holdAfterExhale, progress: step) == 0
            )
        }
    }

    @Test("Patterns without holds keep the exhale silent")
    func exhaleSilentWithoutHolds() {
        for pattern in [BreathingPattern.fourSix, .rhythmic] {
            #expect(BreathingHaptics.isSilent(pattern: pattern, phase: .exhale))
            #expect(BreathingHaptics.isSilent(pattern: pattern, phase: .inhale) == false)
            for step in stride(from: 0.0, through: 1.0, by: 0.1) {
                #expect(
                    BreathingHaptics.intensity(pattern: pattern, phase: .exhale, progress: step) == 0
                )
            }
        }
    }

    @Test("Box breathing is silent only on the holds")
    func boxSilence() {
        #expect(BreathingHaptics.isSilent(pattern: .box, phase: .inhale) == false)
        #expect(BreathingHaptics.isSilent(pattern: .box, phase: .exhale) == false)
        #expect(BreathingHaptics.isSilent(pattern: .box, phase: .holdAfterInhale))
        #expect(BreathingHaptics.isSilent(pattern: .box, phase: .holdAfterExhale))
    }

    @Test("Control points span the phase and stay in range")
    func curvePoints() {
        let points = BreathingHaptics.curvePoints(pattern: .box, phase: .inhale, duration: 4)
        #expect(points.count == 16)
        #expect(points.first?.time == 0)
        #expect(points.last?.time == 4)
        #expect(points.allSatisfy { $0.value >= 0 && $0.value <= 1 })
        // Times increase, as CoreHaptics requires of a parameter curve.
        #expect(zip(points, points.dropFirst()).allSatisfy { $0.time < $1.time })
    }

    @Test("A zero-length phase produces no control points")
    func zeroDuration() {
        #expect(BreathingHaptics.curvePoints(pattern: .box, phase: .inhale, duration: 0).isEmpty)
    }
}
