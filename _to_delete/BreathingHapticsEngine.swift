import CoreHaptics
import Foundation

/// Dedicated haptics engine for breathing sessions:
/// - Boundary markers at phase start
/// - Soft pulses inside inhale/exhale with different frequencies
final class BreathingHapticsEngine {
    private var engine: CHHapticEngine?
    private var player: CHHapticPatternPlayer?

    private var supportsHaptics: Bool {
        CHHapticEngine.capabilitiesForHardware().supportsHaptics
    }

    func start() {
        guard supportsHaptics else { return }
        if engine != nil { return }

        do {
            let newEngine = try CHHapticEngine()
            newEngine.isAutoShutdownEnabled = true
            newEngine.stoppedHandler = { [weak self] _ in
                self?.engine = nil
                self?.player = nil
            }
            newEngine.resetHandler = { [weak self] in
                guard let self else { return }
                do { try self.engine?.start() } catch { /* no-op */ }
            }
            try newEngine.start()
            engine = newEngine
        } catch {
            engine = nil
        }
    }

    func stop() {
        do {
            try player?.stop(atTime: 0)
        } catch { /* no-op */ }
        player = nil

        engine?.stop(completionHandler: nil)
        engine = nil
    }

    func handlePhaseChange(
        to phase: BreathingController.BreathPhase,
        duration: TimeInterval
    ) {
        guard supportsHaptics else { return }
        start()
        guard let engine else { return }

        // Cancel previous phase pattern immediately.
        do { try player?.stop(atTime: 0) } catch { /* no-op */ }
        player = nil

        let clampedDuration = max(0, duration)
        let pulses: [CHHapticEvent] = makePhasePulses(phase: phase, duration: clampedDuration)
        let boundary: [CHHapticEvent] = makeBoundaryMarker(phase: phase)
        let events = boundary + pulses

        guard !events.isEmpty else { return }

        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let newPlayer = try engine.makePlayer(with: pattern)
            try newPlayer.start(atTime: 0)
            player = newPlayer
        } catch {
            player = nil
        }
    }

    private func makeBoundaryMarker(phase: BreathingController.BreathPhase) -> [CHHapticEvent] {
        // Distinct “feel” per phase start:
        // - inhale: single stronger tick
        // - exhale: double tick
        // - hold/rest: gentle tick
        switch phase {
        case .inhale:
            return [transient(at: 0.0, intensity: 0.85, sharpness: 0.55)]
        case .exhale:
            return [
                transient(at: 0.0, intensity: 0.75, sharpness: 0.65),
                transient(at: 0.12, intensity: 0.65, sharpness: 0.55)
            ]
        case .hold:
            return [transient(at: 0.0, intensity: 0.35, sharpness: 0.35)]
        case .rest:
            return [transient(at: 0.0, intensity: 0.30, sharpness: 0.25)]
        }
    }

    private func makePhasePulses(
        phase: BreathingController.BreathPhase,
        duration: TimeInterval
    ) -> [CHHapticEvent] {
        guard duration > 0 else { return [] }

        // Only pulse inside inhale/exhale.
        let interval: TimeInterval? = switch phase {
        case .inhale:
            0.55
        case .exhale:
            0.35
        case .hold, .rest:
            nil
        }

        guard let interval else { return [] }

        // Slight delay so boundary tick reads clearly.
        let startTime: TimeInterval = 0.16
        guard duration > startTime + 0.05 else { return [] }

        let count = Int(((duration - startTime) / interval).rounded(.down)) + 1
        guard count > 0 else { return [] }

        return (0..<count).map { i in
            let t = startTime + (TimeInterval(i) * interval)
            let (intensity, sharpness): (Float, Float) = switch phase {
            case .inhale:
                (0.32, 0.18)
            case .exhale:
                (0.40, 0.22)
            case .hold, .rest:
                (0.0, 0.0) // unreachable
            }
            return transient(at: t, intensity: intensity, sharpness: sharpness)
        }
    }

    private func transient(at time: TimeInterval, intensity: Float, sharpness: Float) -> CHHapticEvent {
        CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
            ],
            relativeTime: time
        )
    }
}


