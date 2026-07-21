import Foundation

// MARK: - Delivery

/// How a line should be read aloud.
///
/// Metadata about the *line*, not about the synthesizer: it says "this is a
/// settling line, read it slowly and low", which is as true for a recorded voice
/// actor as for TTS. That is why it lives on the cue rather than inside
/// `SystemPMRVoice` — when the spec's static audio files replace the prototype
/// (§5), this is the direction that goes to whoever records them.
nonisolated enum PMRDelivery: String, CaseIterable {
    /// Framing the session — the slowest and lowest register.
    case settling
    /// "Tense your arms" — something to do now, so a touch more energy.
    case instruction
    /// The release phase, which is the skill being trained. Slow and low.
    case releasing
}

// MARK: - Cue

/// One instruction in a PMR script: what the voice says, what the screen shows,
/// and how long it lasts.
///
/// The screen and the voice are fed from the same value on purpose. A session
/// where the dimmed screen said "Tense your torso" while the voice had already
/// moved on would be worse than a screen showing nothing at all.
nonisolated struct PMRCue: Equatable {
    let phase: PMRPhase
    /// Nil for `intro`/`outro` and for the whole cue-controlled step, which has
    /// no muscle groups.
    let group: PMRMuscleGroup?
    /// What the voice speaks. Empty means silence — see `pause`.
    let spoken: String
    /// The line the screen shows, dimmed or awake: "Tense your torso".
    let headline: String
    /// The second line when the screen is awake: "pull your shoulder blades
    /// together, tighten your stomach".
    let detail: String?
    let duration: TimeInterval
    /// How this line should be read aloud.
    var delivery: PMRDelivery = .instruction

    /// The pause phase is the only silent one, and it is silent by construction
    /// rather than by a flag that could drift out of sync with `spoken`.
    var isSilent: Bool { spoken.isEmpty }
}

// MARK: - Script

/// Turns a ladder step into the sequence of cues that *is* the exercise
/// (spec §5).
///
/// Pure: no clock, no SwiftData, no audio. The whole exercise can be inspected
/// and tested as data before a single word is spoken.
nonisolated enum PMRScript {

    /// The canonical timings from spec §5, kept as parameters rather than magic
    /// numbers so they can be tuned after hearing them on a device — the plan
    /// names the pause as the first candidate (plan §2, decision 2).
    struct Timings: Equatable {
        var tense: TimeInterval
        var release: TimeInterval
        var pause: TimeInterval
        var intro: TimeInterval
        var outro: TimeInterval
        /// Tension–release repetitions per muscle group.
        ///
        /// Two, not one. The spec's own duration table (16 groups ≈ 25 min) only
        /// works out at two cycles: at one it lands near 15 min, ~40% short. Two
        /// cycles per group is also what Bernstein & Borkovec use for initial
        /// training. Recorded as an inference from the spec's arithmetic, not
        /// something the spec states — see the plan's open questions.
        var tensionCycles: Int
        /// Repetitions of the cue word on the cue-controlled step.
        var cueRepetitions: Int

        static let canonical = Timings(
            tense: 6,
            release: 38,
            pause: 12,
            intro: 20,
            outro: 20,
            tensionCycles: 2,
            cueRepetitions: 5
        )
    }

    /// The full sequence for a step, in order.
    static func cues(for step: PMRStep, timings: Timings = .canonical) -> [PMRCue] {
        guard step != .cueControlled else { return cueControlledCues(timings: timings) }

        var cues: [PMRCue] = [introCue(timings: timings)]
        let groups = step.groups

        for (index, group) in groups.enumerated() {
            if step.usesTension {
                for cycle in 0..<max(1, timings.tensionCycles) {
                    cues.append(tenseCue(group: group, timings: timings))
                    cues.append(releaseCue(group: group, cycle: cycle, timings: timings))
                }
            } else {
                cues.append(recallCue(group: group, timings: timings))
            }

            // No trailing pause after the last group: the outro is the seam
            // there, and a pause before it would just be dead air.
            if index < groups.count - 1 {
                cues.append(pauseCue(after: group, step: step, timings: timings))
            }
        }

        cues.append(outroCue(timings: timings))
        return cues
    }

    static func totalDuration(for step: PMRStep, timings: Timings = .canonical) -> TimeInterval {
        cues(for: step, timings: timings).reduce(0) { $0 + $1.duration }
    }

    // MARK: Cue builders

    private static func introCue(timings: Timings) -> PMRCue {
        PMRCue(
            phase: .intro,
            group: nil,
            spoken: String(
                localized: "Find a quiet place and settle in. Close your eyes when you're ready. We'll start in a moment."
            ),
            headline: String(localized: "Get comfortable"),
            detail: String(localized: "Close your eyes when you're ready"),
            duration: timings.intro,
            delivery: .settling
        )
    }

    private static func tenseCue(group: PMRMuscleGroup, timings: Timings) -> PMRCue {
        PMRCue(
            phase: .tense,
            group: group,
            spoken: String(
                format: String(localized: "Tense your %1$@ — %2$@. Hold it."),
                group.accusative,
                group.tensingCue
            ),
            headline: String(format: String(localized: "Tense your %@"), group.accusative),
            detail: group.tensingCue,
            duration: timings.tense,
            delivery: .instruction
        )
    }

    private static func releaseCue(
        group: PMRMuscleGroup,
        cycle: Int,
        timings: Timings
    ) -> PMRCue {
        // The second cycle does not repeat the first one's words: hearing the
        // identical sentence twice reads as the recording having looped.
        let spoken = cycle == 0
            ? String(localized: "And release. Let the tension go, and notice how different it feels.")
            : String(localized: "And release again. Let the tension drain a little further.")

        return PMRCue(
            phase: .release,
            group: group,
            spoken: spoken,
            headline: String(format: String(localized: "Release your %@"), group.accusative),
            detail: String(localized: "notice the difference"),
            duration: timings.release,
            delivery: .releasing
        )
    }

    /// The recall step releases without tensing first — that is the skill it
    /// trains, so the wording never implies a tension that did not happen.
    private static func recallCue(group: PMRMuscleGroup, timings: Timings) -> PMRCue {
        PMRCue(
            phase: .release,
            group: group,
            // Phrased so the group stays the object of "let go" rather than
            // sitting after a preposition: Russian would need a third case form
            // for "tension in your arms", and two is already the cost of doing
            // this honestly.
            spoken: String(
                format: String(
                    localized: "Let your %@ go — notice any tension that's left, and let it drain away."
                ),
                group.accusative
            ),
            headline: String(format: String(localized: "Let your %@ go"), group.accusative),
            detail: String(localized: "notice any tension, and let it go"),
            duration: timings.release,
            delivery: .releasing
        )
    }

    /// Silent by construction. The headline repeats the group that was just
    /// released so a screen woken during the pause still says where the session
    /// is, rather than going blank for twelve seconds.
    private static func pauseCue(
        after group: PMRMuscleGroup,
        step: PMRStep,
        timings: Timings
    ) -> PMRCue {
        PMRCue(
            phase: .pause,
            group: group,
            spoken: "",
            headline: step.usesTension
                ? String(format: String(localized: "Release your %@"), group.accusative)
                : String(format: String(localized: "Let your %@ go"), group.accusative),
            detail: nil,
            duration: timings.pause,
            delivery: .releasing
        )
    }

    private static func outroCue(timings: Timings) -> PMRCue {
        PMRCue(
            phase: .outro,
            group: nil,
            spoken: String(
                localized: "That's the end of the practice. Rest here for a moment, and come back when you're ready."
            ),
            headline: String(localized: "Rest here a moment"),
            detail: nil,
            duration: timings.outro,
            delivery: .settling
        )
    }

    // MARK: Cue-controlled step

    /// Spec §5: the last rung meets breathing — a single word on the exhale, no
    /// muscle groups at all. Structurally a different sequence, which is why it
    /// is built here rather than bent into the group loop.
    private static func cueControlledCues(timings: Timings) -> [PMRCue] {
        var cues: [PMRCue] = [
            PMRCue(
                phase: .intro,
                group: nil,
                spoken: String(
                    localized: "Breathe evenly. On each exhale, say one word to yourself: relax."
                ),
                headline: String(localized: "Breathe evenly"),
                detail: String(localized: "one word on each exhale"),
                duration: timings.intro,
                delivery: .settling
            )
        ]

        for _ in 0..<max(1, timings.cueRepetitions) {
            cues.append(
                PMRCue(
                    phase: .release,
                    group: nil,
                    spoken: String(localized: "Relax."),
                    headline: String(localized: "Relax"),
                    detail: String(localized: "on the exhale"),
                    duration: timings.release / 5,
                    delivery: .releasing
                )
            )
        }

        cues.append(outroCue(timings: timings))
        return cues
    }
}
