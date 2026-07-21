import Foundation
import SwiftData

// MARK: - Breath Phase

/// One phase of a breathing cycle. Lives in the model layer, not in the design
/// system: the phase is what the exercise *is*, and both the circle and the
/// haptic engine are driven by it.
///
/// The two holds are separate cases rather than one `hold` because they sit at
/// opposite ends of the scale — after the inhale the shape stays expanded,
/// after the exhale it stays contracted. Collapsing them would make the circle
/// jump between the two.
nonisolated enum BreathPhase: String, CaseIterable {
    case inhale
    case holdAfterInhale
    case exhale
    case holdAfterExhale

    /// One-word command shown under the circle.
    var title: String {
        switch self {
        case .inhale: String(localized: "Inhale")
        case .exhale: String(localized: "Exhale")
        case .holdAfterInhale, .holdAfterExhale: String(localized: "Hold")
        }
    }

    var isHold: Bool {
        self == .holdAfterInhale || self == .holdAfterExhale
    }
}

// MARK: - Breathing Pattern

/// The three breathing types offered by spec §4.
///
/// `rhythmic` is 4-4: the spec names the type without spelling it out, and this
/// is the reading that makes the three patterns actually differ from one
/// another — with holds / with a longer exhale / even (plan §2, decision 1).
nonisolated enum BreathingPattern: String, CaseIterable {
    // Persisted rawValues — never rename (CLAUDE.md).
    case box
    case fourSix
    case rhythmic

    var title: String {
        switch self {
        case .box: String(localized: "Box breathing")
        case .fourSix: String(localized: "4-6")
        case .rhythmic: String(localized: "Rhythmic")
        }
    }

    /// The pattern spelled out as counts — a fact, no interpretation.
    var formula: String {
        switch self {
        case .box: String(localized: "4-4-4-4 · inhale, hold, exhale, hold")
        case .fourSix: String(localized: "Inhale 4, exhale 6")
        case .rhythmic: String(localized: "Inhale 4, exhale 4")
        }
    }

    /// What the pattern *is* and how demanding it is — never what it gives you
    /// or when to use it. That line would be a recommendation (principle 1.1)
    /// and marketing on the user's own path (1.3).
    var summary: String {
        switch self {
        case .box:
            String(localized: "Equal phases with holds. Demands the most attention")
        case .fourSix:
            String(localized: "The exhale is longer than the inhale")
        case .rhythmic:
            String(localized: "An even cycle, no holds. Easiest not to lose track")
        }
    }

    /// Chosen for **legibility, not semantics**: three unmistakably different
    /// silhouettes at tile size. Only `square` actually names its pattern (box
    /// breathing is called after the shape); the down-arrow and the wave are
    /// mnemonics at best.
    ///
    /// That is a deliberate trade — the earlier square/rectangle/circle set
    /// encoded the patterns honestly but differed only by proportion, which is
    /// invisible at 22pt with a thin stroke. **The meaning is carried by the
    /// formula line** (`formula`) next to the glyph, so don't drop that line
    /// from a layout and leave the icon to explain itself.
    var icon: String {
        switch self {
        case .box: "square"
        case .fourSix: "arrow.down.to.line"
        case .rhythmic: "waveform"
        }
    }

    /// Phase durations in seconds, in cycle order. A zero means the phase is
    /// absent from this pattern.
    var phaseDurations: [(phase: BreathPhase, seconds: TimeInterval)] {
        switch self {
        case .box:
            [(.inhale, 4), (.holdAfterInhale, 4), (.exhale, 4), (.holdAfterExhale, 4)]
        case .fourSix:
            [(.inhale, 4), (.exhale, 6)]
        case .rhythmic:
            [(.inhale, 4), (.exhale, 4)]
        }
    }

    var hasHolds: Bool {
        phaseDurations.contains { $0.phase.isHold }
    }

    var cycleDuration: TimeInterval {
        phaseDurations.reduce(0) { $0 + $1.seconds }
    }

    /// Which phase the breath is in `elapsed` seconds into the session, and how
    /// far through that phase it is (0…1).
    ///
    /// A pure function of elapsed time — the clock is never read in here
    /// (CLAUDE.md), which is what makes the whole engine testable at arbitrary
    /// offsets.
    func phase(at elapsed: TimeInterval) -> (phase: BreathPhase, progress: Double) {
        let steps = phaseDurations
        guard let first = steps.first else { return (.inhale, 0) }
        guard elapsed > 0 else { return (first.phase, 0) }

        var remainder = elapsed.truncatingRemainder(dividingBy: cycleDuration)
        for step in steps {
            if remainder < step.seconds {
                return (step.phase, remainder / step.seconds)
            }
            remainder -= step.seconds
        }
        // Floating-point landing exactly on the cycle boundary.
        return (first.phase, 0)
    }
}

// MARK: - Breathing Session Entry

/// One breathing session (spec §4).
///
/// Inserted at "Start" with the plan only, exactly like a planned exposure:
/// killing the app mid-session must leave a truthful partial record rather than
/// nothing at all (principle 1.5). `actualDurationSeconds` is written when the
/// session ends, `didRelax` and `note` on the "after" screen.
@Model
final class BreathingSessionEntry {
    var createdAt: Date
    var patternRaw: String
    /// The ladder step chosen on the "before" screen.
    var plannedDurationSeconds: Int
    /// Nil while the session has been started and not finished.
    var actualDurationSeconds: Int?
    /// Nil while the "after" screen has not been answered. Nil is *no answer*,
    /// not a negative one — the ladder rule skips these without breaking a
    /// streak.
    var didRelax: Bool?
    /// Whether the user actually used the pause button. Going to the background
    /// does not set this: that would be putting words in their mouth (plan §2,
    /// decision 11).
    var wasPaused: Bool
    var note: String?

    init(
        createdAt: Date,
        pattern: BreathingPattern,
        plannedDurationSeconds: Int
    ) {
        self.createdAt = createdAt
        self.patternRaw = pattern.rawValue
        self.plannedDurationSeconds = plannedDurationSeconds
        self.wasPaused = false
    }

    var pattern: BreathingPattern? {
        BreathingPattern(rawValue: patternRaw)
    }
}
