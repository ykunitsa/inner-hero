import Foundation
import CoreHaptics

/// Haptic guidance for the breathing session (plan §5).
///
/// The grammar, in one rule: **a ramp appears exactly where silence would be
/// ambiguous.**
///
/// | Pattern | Inhale | Hold | Exhale | Hold |
/// |---|---|---|---|---|
/// | Box     | ramp ↗ | silence | ramp ↘ (mirrored) | silence |
/// | 4-6     | ramp ↗ | —       | silence           | —       |
/// | Rhythmic| ramp ↗ | —       | silence           | —       |
///
/// Without holds, silence can only mean "exhale" — the Apple Watch Breathe
/// model is enough. With holds, silence would mean both exhale *and* hold, so
/// the exhale takes a ramp and silence is left to the holds alone. The exhale
/// ramp is **mirrored** (strong first, fading) — an identical ramp would make
/// inhale and exhale indistinguishable with your eyes closed. No taps at phase
/// boundaries anywhere.
///
/// > CoreHaptics does not run in the simulator. This is device-only.
nonisolated enum BreathingHaptics {

    // MARK: - The curve (pure)

    /// Where the ramp peaks inside the phase. Rising over the first 40% and
    /// decaying over the remaining 60% is what makes the end feel like it is
    /// slowing down rather than being cut off.
    private static let peak = 0.4

    /// Haptic intensity at `progress` (0…1) through `phase`.
    ///
    /// Pure — no engine, no clock. This is the part that gets tested; the
    /// engine below is a thin wrapper around it.
    static func intensity(
        pattern: BreathingPattern,
        phase: BreathPhase,
        progress: Double
    ) -> Float {
        switch phase {
        case .holdAfterInhale, .holdAfterExhale:
            return 0
        case .inhale:
            return ramp(progress)
        case .exhale:
            // Silent unless the pattern has holds to distinguish it from.
            guard pattern.hasHolds else { return 0 }
            return ramp(1 - progress)
        }
    }

    /// Rises fast to the peak, then decays smoothly to nothing.
    private static func ramp(_ progress: Double) -> Float {
        let p = min(max(progress, 0), 1)
        let value = p <= peak
            ? sin(p / peak * .pi / 2)
            : cos((p - peak) / (1 - peak) * .pi / 2)
        return Float(min(max(value, 0), 1))
    }

    /// The curve sampled into control points for one phase.
    static func curvePoints(
        pattern: BreathingPattern,
        phase: BreathPhase,
        duration: TimeInterval,
        sampleCount: Int = 16
    ) -> [(time: TimeInterval, value: Float)] {
        guard duration > 0, sampleCount > 1 else { return [] }
        return (0..<sampleCount).map { index in
            let progress = Double(index) / Double(sampleCount - 1)
            return (
                time: progress * duration,
                value: intensity(pattern: pattern, phase: phase, progress: progress)
            )
        }
    }

    /// Whether the phase produces any vibration at all — lets the engine skip
    /// building a pattern for a silent phase.
    static func isSilent(pattern: BreathingPattern, phase: BreathPhase) -> Bool {
        curvePoints(pattern: pattern, phase: phase, duration: 1).allSatisfy { $0.value == 0 }
    }
}

// MARK: - Engine

/// Thin CoreHaptics wrapper: one continuous event per phase, shaped by
/// `BreathingHaptics.curvePoints`.
///
/// Every failure path degrades to silence rather than throwing at the caller —
/// a breathing session must not be interrupted because the taptic engine was
/// busy.
@MainActor
final class BreathingHapticPlayer {
    private var engine: CHHapticEngine?
    private var isRunning = false

    var isSupported: Bool {
        CHHapticEngine.capabilitiesForHardware().supportsHaptics
    }

    func start() {
        guard isSupported, engine == nil else { return }
        do {
            let engine = try CHHapticEngine()
            // The system stops the engine on interruptions (a call, going to
            // the background). Bring it back rather than staying silent for the
            // rest of the session.
            engine.stoppedHandler = { [weak self] _ in
                Task { @MainActor in self?.isRunning = false }
            }
            engine.resetHandler = { [weak self] in
                Task { @MainActor in
                    self?.isRunning = false
                    self?.resume()
                }
            }
            try engine.start()
            self.engine = engine
            isRunning = true
        } catch {
            engine = nil
        }
    }

    func stop() {
        engine?.stop()
        engine = nil
        isRunning = false
    }

    private func resume() {
        guard let engine else { return }
        do {
            try engine.start()
            isRunning = true
        } catch {
            isRunning = false
        }
    }

    /// Plays the ramp for one phase. Call at the phase boundary.
    func play(phase: BreathPhase, pattern: BreathingPattern, duration: TimeInterval) {
        guard duration > 0, !BreathingHaptics.isSilent(pattern: pattern, phase: phase) else {
            return
        }
        guard let engine else { return }
        if !isRunning { resume() }

        let points = BreathingHaptics.curvePoints(
            pattern: pattern,
            phase: phase,
            duration: duration
        )
        guard !points.isEmpty else { return }

        do {
            let event = CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    // Intensity is driven by the curve below; this is its ceiling.
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 1),
                    // Deliberately dull: a sharp continuous buzz reads as an
                    // alert, and this is a breathing cue.
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.25),
                ],
                relativeTime: 0,
                duration: duration
            )
            let curve = CHHapticParameterCurve(
                parameterID: .hapticIntensityControl,
                controlPoints: points.map {
                    CHHapticParameterCurve.ControlPoint(relativeTime: $0.time, value: $0.value)
                },
                relativeTime: 0
            )
            let hapticPattern = try CHHapticPattern(events: [event], parameterCurves: [curve])
            let player = try engine.makePlayer(with: hapticPattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            // Silence for this phase; the next one tries again.
        }
    }
}
