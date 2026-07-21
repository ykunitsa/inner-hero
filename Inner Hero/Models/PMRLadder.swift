import Foundation

/// The PMR ladder (spec §5): progress is measured by needing *less* of the
/// script, not by more minutes logged.
///
/// Two things the spec is explicit about and this type must not quietly break:
/// steps are **never blocked** ("переход обсуди с терапевтом"), and the rule
/// only ever **suggests** — it never changes the setting itself (principle 1.8).
///
/// Pure logic, no SwiftData: it works on `Outcome` values so the whole rule can
/// be tested without a container.
nonisolated enum PMRLadder {

    /// Ladder rungs, hardest first. Descending the array is progress.
    static let steps: [PMRStep] = [
        .sixteenGroups,
        .sevenGroups,
        .fourGroups,
        .fourGroupsRecall,
        .cueControlled,
    ]

    /// Where a first-ever session starts — deliberately **not** the top of the
    /// ladder. §11.4 says to start at four groups, and twenty-five minutes as a
    /// first experience of the exercise is a reliable way to lose the user
    /// before they find out what it does.
    static let initialStep: PMRStep = .fourGroups

    /// Consecutive successes before offering the next step down.
    static let successesToStepDown = 5
    /// Consecutive failures before offering a step back up.
    static let failuresToStepUp = 2

    /// The part of a logged session the rules actually look at.
    struct Outcome: Equatable {
        let step: PMRStep
        let didRelax: Bool?
        /// Whether the session stopped before the script ended. A session killed
        /// with the app counts as early — nothing says it was seen through.
        let didFinishEarly: Bool

        init(step: PMRStep, didRelax: Bool?, didFinishEarly: Bool) {
            self.step = step
            self.didRelax = didRelax
            self.didFinishEarly = didFinishEarly
        }

        init?(entry: PMRSessionEntry) {
            guard let step = entry.step else { return nil }
            self.step = step
            self.didRelax = entry.didRelax
            if let actual = entry.actualDurationSeconds {
                // Two seconds of slack: the session ends on a polled clock, so a
                // script that ran to its last word can land a hair under plan.
                self.didFinishEarly = actual + 2 < entry.plannedDurationSeconds
            } else {
                self.didFinishEarly = true
            }
        }
    }

    enum Suggestion: Equatable {
        case stepDown(PMRStep)
        case stepUp(PMRStep)

        var step: PMRStep {
            switch self {
            case .stepDown(let step), .stepUp(let step): step
            }
        }
    }

    /// - Parameter history: sessions **newest first**.
    static func suggestion(history: [Outcome], currentStep: PMRStep) -> Suggestion? {
        // A session on a different step ends the run: the spec counts "in a row
        // on the current step", so the prefix stops there rather than filtering
        // the other sessions out.
        let atCurrentStep = history.prefix { $0.step == currentStep }

        // Unanswered sessions carry no answer — which is not the same as a
        // negative one. They are skipped without breaking the run.
        let answers = atCurrentStep.compactMap(\.didRelax)
        guard let latest = answers.first else { return nil }

        let run = answers.prefix { $0 == latest }.count

        if latest, run >= successesToStepDown {
            return nextStepDown(from: currentStep).map(Suggestion.stepDown)
        }
        if !latest, run >= failuresToStepUp {
            return nextStepUp(from: currentStep).map(Suggestion.stepUp)
        }
        return nil
    }

    /// Nil at the bottom of the ladder — there is nothing left to offer.
    static func nextStepDown(from step: PMRStep) -> PMRStep? {
        guard let index = steps.firstIndex(of: step), index + 1 < steps.count else {
            return nil
        }
        return steps[index + 1]
    }

    /// Nil at the top of the ladder.
    static func nextStepUp(from step: PMRStep) -> PMRStep? {
        guard let index = steps.firstIndex(of: step), index > 0 else { return nil }
        return steps[index - 1]
    }

    /// The one medal in the app (spec §5): a step is earned once it has been
    /// worked through at least once, end to end.
    ///
    /// Two properties the spec asks for, both falling out of the shape of this
    /// function rather than needing to be maintained: it is **never taken away**
    /// (the set only grows as history grows), and it is **not announced in
    /// advance** (there is nothing here about steps not yet reached).
    ///
    /// Sessions that ended early do not earn it — but they are not punished
    /// either: they simply say nothing, exactly like an unanswered `didRelax`.
    ///
    /// No display surface yet. The medal's home is a line in History (spec §5),
    /// and History is rebuilt in §11.6.
    static func earnedMedals(history: [Outcome]) -> Set<PMRStep> {
        Set(history.filter { !$0.didFinishEarly }.map(\.step))
    }

    /// A step's estimated length as minutes for display: "4", "12", "0,5".
    /// Whole numbers never carry a decimal point; the separator follows the
    /// locale, so a half minute reads "0,5" in Russian and "0.5" in English.
    static func minutesLabel(duration: TimeInterval) -> String {
        (duration / 60).formatted(.number.precision(.fractionLength(0...1)))
    }
}
