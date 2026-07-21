import Foundation

/// The ladder rule (spec §4): breathing is skill training, and the skill being
/// trained is *how fast* you can relax. Descending the ladder is the progress
/// measure — which is why the rule only ever **suggests** a step and never
/// changes the setting itself (principle 1.8).
///
/// Pure logic, no SwiftData: it works on `Outcome` values so the whole rule can
/// be tested without a container.
nonisolated enum BreathingLadder {

    /// Ladder steps in seconds: 15 → 10 → 7 → 5 → 3 → 2 → 1 → 0.5 min.
    /// Descending the array is progress.
    static let steps: [Int] = [900, 600, 420, 300, 180, 120, 60, 30]

    /// Where a first-ever session starts — the top of the ladder.
    static let initialDuration = 900

    /// Consecutive successes needed before offering a step down (spec §4).
    static let successesToStepDown = 5
    /// Consecutive failures before offering a step back up (spec §4).
    static let failuresToStepUp = 2

    /// The part of a logged session the rule actually looks at.
    struct Outcome: Equatable {
        let pattern: BreathingPattern
        let plannedDurationSeconds: Int
        let didRelax: Bool?

        init(pattern: BreathingPattern, plannedDurationSeconds: Int, didRelax: Bool?) {
            self.pattern = pattern
            self.plannedDurationSeconds = plannedDurationSeconds
            self.didRelax = didRelax
        }

        init?(entry: BreathingSessionEntry) {
            guard let pattern = entry.pattern else { return nil }
            self.pattern = pattern
            self.plannedDurationSeconds = entry.plannedDurationSeconds
            self.didRelax = entry.didRelax
        }
    }

    enum Suggestion: Equatable {
        case stepDown(seconds: Int)
        case stepUp(seconds: Int)

        var seconds: Int {
            switch self {
            case .stepDown(let seconds), .stepUp(let seconds): seconds
            }
        }
    }

    /// - Parameter history: sessions **newest first**.
    ///
    /// Counted separately per breathing pattern (spec §4) — the patterns are
    /// different skills and a streak on one says nothing about another.
    static func suggestion(
        history: [Outcome],
        pattern: BreathingPattern,
        currentDuration: Int
    ) -> Suggestion? {
        // A session at a different duration ends the streak: the spec counts
        // "in a row at the current duration", so the prefix stops there rather
        // than filtering those sessions out.
        let atCurrentDuration = history
            .filter { $0.pattern == pattern }
            .prefix { $0.plannedDurationSeconds == currentDuration }

        // Unanswered sessions carry no answer — which is not the same as a
        // negative one. They are skipped without breaking the run.
        let answers = atCurrentDuration.compactMap(\.didRelax)
        guard let latest = answers.first else { return nil }

        let run = answers.prefix { $0 == latest }.count

        if latest, run >= successesToStepDown {
            return nextStepDown(from: currentDuration).map(Suggestion.stepDown)
        }
        if !latest, run >= failuresToStepUp {
            return nextStepUp(from: currentDuration).map(Suggestion.stepUp)
        }
        return nil
    }

    /// Nil at the bottom of the ladder — there is nothing left to offer.
    static func nextStepDown(from duration: Int) -> Int? {
        guard let index = steps.firstIndex(of: duration), index + 1 < steps.count else {
            return nil
        }
        return steps[index + 1]
    }

    /// Nil at the top of the ladder.
    static func nextStepUp(from duration: Int) -> Int? {
        guard let index = steps.firstIndex(of: duration), index > 0 else { return nil }
        return steps[index - 1]
    }

    /// Ladder steps as minutes for display: "0,5", "1", "15". Whole numbers
    /// never carry a decimal point; the separator follows the locale, so the
    /// half-minute step reads "0,5" in Russian and "0.5" in English.
    static func minutesLabel(seconds: Int) -> String {
        (Double(seconds) / 60).formatted(.number.precision(.fractionLength(0...1)))
    }
}
