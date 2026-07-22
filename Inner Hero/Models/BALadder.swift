import Foundation

/// The BA ladder (spec §6): five "did it" in a row in a basket offers the next
/// one up, two "couldn't" in a row offers a step back down.
///
/// The one thing this ladder does **not** have is medals. The spec says so in the
/// heading — "Лестница BA (без медалей!)" — and the reason is structural rather
/// than stylistic: PMR earns a medal for needing *less* of the script, while BA
/// has no such endpoint. A medal for "did a hard thing" would turn the effort
/// baskets into a scoreboard, and the person who can only reach the easy shelf
/// this month would be reading their own failure off it.
///
/// Like `PMRLadder`: pure logic, no SwiftData, and it only ever **suggests**
/// (principle 1.8).
nonisolated enum BALadder {

    /// Rungs, easiest first. Ascending the array is a harder ask, not a better
    /// person.
    static let baskets: [BAEffort] = [.easy, .medium, .hard]

    /// Consecutive successes before offering the next basket up.
    static let successesToStepUp = 5
    /// Consecutive failures before offering a step down.
    static let failuresToStepDown = 2

    /// The part of a logged activity the rule actually looks at.
    struct Outcome: Equatable {
        let effort: BAEffort
        /// Nil while the activity is still open. Nil is *no answer*, which is not
        /// the same as "couldn't".
        let outcome: BAOutcome?

        init(effort: BAEffort, outcome: BAOutcome?) {
            self.effort = effort
            self.outcome = outcome
        }

        init?(entry: BALogEntry) {
            guard let effort = entry.effort else { return nil }
            self.effort = effort
            self.outcome = entry.outcome
        }
    }

    enum Suggestion: Equatable {
        case stepUp(BAEffort)
        case stepDown(BAEffort)

        var basket: BAEffort {
            switch self {
            case .stepUp(let basket), .stepDown(let basket): basket
            }
        }
    }

    /// - Parameter history: entries **newest first**.
    static func suggestion(history: [Outcome], currentBasket: BAEffort) -> Suggestion? {
        // An activity from a different basket ends the run: the spec counts "in a
        // row" within one basket, so the prefix stops rather than filtering the
        // others out. Five easy wins interrupted by a failed hard one is not a
        // five-run, and pretending otherwise would push the user up a ladder they
        // just fell off.
        let inBasket = history.prefix { $0.effort == currentBasket }

        // Open activities carry no answer yet. They are skipped without breaking
        // the run — an unanswered tail should not silently reset progress.
        let answers = inBasket.compactMap(\.outcome)
        guard let latest = answers.first else { return nil }

        let run = answers.prefix { $0 == latest }.count

        if latest == .done, run >= successesToStepUp {
            return nextUp(from: currentBasket).map(Suggestion.stepUp)
        }
        if latest == .couldNot, run >= failuresToStepDown {
            return nextDown(from: currentBasket).map(Suggestion.stepDown)
        }
        return nil
    }

    /// Nil at the top of the ladder — there is nothing harder to offer.
    static func nextUp(from basket: BAEffort) -> BAEffort? {
        guard let index = baskets.firstIndex(of: basket), index + 1 < baskets.count else {
            return nil
        }
        return baskets[index + 1]
    }

    /// Nil at the bottom. Two failures on the easy shelf produce no suggestion at
    /// all, which is deliberate: the app has nothing useful to say there, and
    /// saying something anyway would be advice (principle 1.1).
    static func nextDown(from basket: BAEffort) -> BAEffort? {
        guard let index = baskets.firstIndex(of: basket), index > 0 else { return nil }
        return baskets[index - 1]
    }
}
