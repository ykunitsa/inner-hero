import Foundation
import SwiftData

/// The whole BA flow (spec §6): energy → one thing → (later) tail → after.
///
/// Unlike the other three exercises, this flow is **split across time**. The
/// first half ends when the user puts the phone down, and the second half starts
/// hours later from a row on Today. That is the exercise, not a limitation:
/// choosing and doing are deliberately separated so that the choice happens on a
/// day with enough energy to make it.
///
/// The clock is never read in here — every method that needs the time takes `now`
/// (CLAUDE.md).
@Observable
@MainActor
final class BAFlowViewModel {

    enum Stage {
        case energy
        case oneThing
        /// An open activity waiting to be answered. Reachable both as the second
        /// half of a fresh flow and as the entry point from Today.
        case tail
        case after
    }

    private(set) var stage: Stage = .energy

    // MARK: Before

    private(set) var energy: BAEnergy?
    /// Which shelf the card is drawn from. Follows the energy answer, and may be
    /// moved by the ladder — but only ever by an explicit tap (principle 1.8).
    private(set) var basket: BAEffort = .easy
    private(set) var candidate: BAActivity?
    var forecast: BAForecast?
    private(set) var suggestion: BALadder.Suggestion?

    // MARK: Tail / after

    private(set) var entry: BALogEntry?

    private(set) var pleasure = 5
    private(set) var mastery = 5
    /// Untouched sliders save nothing. A slider parked at its midpoint looks
    /// exactly like a deliberate "5", and writing that would be the same class of
    /// lie as a forecast filled in afterwards (principle 1.6).
    private(set) var pleasureAnswered = false
    private(set) var masteryAnswered = false
    var note = ""

    /// How the card is drawn from the pool. Injected so the randomness can be
    /// pinned in tests; the app always passes honest uniform choice, which the
    /// spec asks for by name.
    private let pick: ([BAActivity]) -> BAActivity?

    init(pick: @escaping ([BAActivity]) -> BAActivity? = { $0.randomElement() }) {
        self.pick = pick
    }

    // MARK: Setup

    /// - Parameters:
    ///   - openEntry: the one unanswered activity, if any.
    ///   - history: log entries **newest first**, for the ladder rule.
    func configure(openEntry: BALogEntry?, history: [BALogEntry]) {
        if let openEntry {
            // An open tail takes precedence over everything: asking "how much
            // energy?" while yesterday's commitment is still hanging would be the
            // app ignoring the thing it asked the user to do.
            entry = openEntry
            stage = .tail
        }
        self.history = history
    }

    private var history: [BALogEntry] = []

    // MARK: Energy

    /// The answer *is* the action — there is no confirm button (principle 1.2).
    func answerEnergy(_ energy: BAEnergy, activities: [BAActivity]) {
        self.energy = energy
        basket = energy.basket
        refreshSuggestion()
        shuffleCandidate(from: activities, allowRepeat: true)
        stage = .oneThing
    }

    /// Back to the question. A mis-tap on "Enough" otherwise leaves the user
    /// reshuffling the hard shelf with no way back to the one they meant.
    func returnToEnergy() {
        guard stage == .oneThing else { return }
        stage = .energy
        candidate = nil
        forecast = nil
    }

    private func refreshSuggestion() {
        suggestion = BALadder.suggestion(
            history: history.compactMap(BALadder.Outcome.init(entry:)),
            currentBasket: basket
        )
    }

    /// The rule proposes, the user disposes (principle 1.8) — only ever called
    /// from an explicit tap on the suggestion line. The honest energy answer is
    /// left untouched: what moves is the shelf, not the record of how the user
    /// said they felt.
    func applySuggestion(activities: [BAActivity]) {
        guard let suggestion else { return }
        basket = suggestion.basket
        self.suggestion = nil
        shuffleCandidate(from: activities, allowRepeat: true)
    }

    // MARK: One thing

    /// - Parameter allowRepeat: true when there is no card on screen yet. The
    ///   reshuffle excludes the current card, because a "Something else" button
    ///   that can hand back the same line reads as broken. With a single activity
    ///   in the basket there is nothing to exclude and the card simply stays.
    func shuffleCandidate(from activities: [BAActivity], allowRepeat: Bool = false) {
        let pool = activities.filter { $0.effort == basket }
        poolCount = pool.count
        guard !pool.isEmpty else {
            candidate = nil
            return
        }
        let current = candidate?.persistentModelID
        let choices = (allowRepeat || pool.count == 1)
            ? pool
            : pool.filter { $0.persistentModelID != current }
        candidate = pick(choices) ?? pool.first
    }

    var hasCandidate: Bool { candidate != nil }

    /// How many activities the current basket holds. Drives whether "Something
    /// else" is offered at all — with one activity there is nothing to shuffle to.
    private(set) var poolCount = 0

    var canShuffle: Bool { poolCount > 1 }

    /// Writes the commitment and returns the new tail so the caller can schedule
    /// its reminder. Inserted before anything happens in the world: a killed app
    /// must leave a truthful open activity rather than nothing (principle 1.5).
    @discardableResult
    func commit(in context: ModelContext, now: Date = Date()) throws -> BALogEntry? {
        guard stage == .oneThing, let candidate, let energy else { return nil }

        let newEntry = BALogEntry(
            createdAt: now,
            activityID: nil,
            activityTitle: candidate.title,
            effort: basket,
            energy: energy,
            forecast: forecast
        )
        context.insert(newEntry)
        try context.save()
        entry = newEntry
        return newEntry
    }

    // MARK: Tail

    /// Both answers are data (principle 1.5). "Couldn't" ends the flow right
    /// there — following it with rating sliders would be asking someone to score
    /// a thing that did not happen.
    func answer(_ outcome: BAOutcome, in context: ModelContext, now: Date = Date()) throws {
        guard let entry, entry.isOpen else { return }
        entry.outcomeRaw = outcome.rawValue
        entry.answeredAt = now
        try context.save()
        stage = outcome == .done ? .after : .tail
    }

    /// "Собирался вчера в 16:40" — when the commitment was made.
    ///
    /// Days are named, never counted. "3 days ago" would be a number measuring
    /// how long someone has not done a thing, which is a reproach dressed as
    /// information (codex §8); an older tail simply states its date.
    nonisolated static func plannedText(
        createdAt: Date,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> String {
        let time = createdAt.formatted(date: .omitted, time: .shortened)

        if calendar.isDate(createdAt, inSameDayAs: now) {
            return String(format: String(localized: "Planned today at %@"), time)
        }
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
           calendar.isDate(createdAt, inSameDayAs: yesterday) {
            return String(format: String(localized: "Planned yesterday at %@"), time)
        }
        let day = createdAt.formatted(.dateTime.day().month(.wide))
        return String(format: String(localized: "Planned on %1$@ at %2$@"), day, time)
    }

    // MARK: After

    func setPleasure(_ value: Int) {
        pleasure = value
        pleasureAnswered = true
    }

    func setMastery(_ value: Int) {
        mastery = value
        masteryAnswered = true
    }

    var trimmedNote: String {
        note.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Spec §6: the nudge to top up the store appears **only** at 6+. Below that
    /// it would read as "do more of this", which is advice (principle 1.1).
    var shouldSuggestRefill: Bool {
        let answered = [pleasureAnswered ? pleasure : nil, masteryAnswered ? mastery : nil]
        return answered.compactMap { $0 }.contains { $0 >= 6 }
    }

    /// The forecast next to what actually happened — shown only when there is
    /// something to compare, never as an empty placeholder.
    var forecastComparison: (forecast: BAForecast, rating: Int)? {
        guard let forecast = entry?.forecast, pleasureAnswered else { return nil }
        return (forecast, pleasure)
    }

    /// Closing without touching the sliders keeps the outcome already recorded —
    /// the entry stopped being open the moment "Did it" was tapped, so this saves
    /// detail, it does not decide anything.
    func saveAfter(in context: ModelContext) throws {
        guard let entry else { return }
        entry.pleasure = pleasureAnswered ? pleasure : nil
        entry.mastery = masteryAnswered ? mastery : nil
        entry.note = trimmedNote.isEmpty ? nil : trimmedNote
        try context.save()
    }
}
