import Foundation
import Observation
import SwiftData

// MARK: - Feed item

/// One line of the session feed (spec §2.3.4). An enum in the presentation
/// layer rather than a protocol the models conform to: §1.10 forbids a shared
/// exercise template, and the previous version died of exactly that protocol.
///
/// The medal case is not a log entry at all — it is derived from PMR history
/// (spec §5) and joins the feed on the day it was earned.
nonisolated enum HistoryItem: Identifiable {
    case exposure(id: String, date: Date, title: String, detail: String, isSituational: Bool)
    case breathing(id: String, date: Date, title: String, detail: String)
    case pmr(id: String, date: Date, title: String, detail: String)
    case activation(id: String, date: Date, title: String, detail: String)
    case medal(id: String, date: Date, title: String, detail: String)

    var id: String {
        switch self {
        case .exposure(let id, _, _, _, _),
             .breathing(let id, _, _, _),
             .pmr(let id, _, _, _),
             .activation(let id, _, _, _),
             .medal(let id, _, _, _):
            id
        }
    }

    var date: Date {
        switch self {
        case .exposure(_, let date, _, _, _),
             .breathing(_, let date, _, _),
             .pmr(_, let date, _, _),
             .activation(_, let date, _, _),
             .medal(_, let date, _, _):
            date
        }
    }

    var title: String {
        switch self {
        case .exposure(_, _, let title, _, _),
             .breathing(_, _, let title, _),
             .pmr(_, _, let title, _),
             .activation(_, _, let title, _),
             .medal(_, _, let title, _):
            title
        }
    }

    var detail: String {
        switch self {
        case .exposure(_, _, _, let detail, _),
             .breathing(_, _, _, let detail),
             .pmr(_, _, _, let detail),
             .activation(_, _, _, let detail),
             .medal(_, _, _, let detail):
            detail
        }
    }

    /// Spec §2.3.4: situational exposures are marked. Nothing else is.
    var isSituational: Bool {
        if case .exposure(_, _, _, _, let isSituational) = self { return isSituational }
        return false
    }
}

/// A day's worth of feed items.
nonisolated struct HistoryDay: Identifiable {
    let id: Date
    let items: [HistoryItem]
}

// MARK: - Ladder positions

/// One row of the opening block: an exercise and where it currently stands.
/// Exercises with no sessions are absent — a zero is not a state, it is the
/// absence of data (codex §4).
nonisolated struct LadderPosition: Identifiable {
    let id: String
    let exercise: String
    let position: String
}

// MARK: - Exposure statistics

/// The three fractions of spec §2.3.3. Each is nil when its denominator is
/// empty, so the row disappears instead of showing "0 of 0".
nonisolated struct ExposureStats {
    let stayed: (done: Int, total: Int)?
    let predictionsMissed: (done: Int, total: Int)?
    let withoutSafetyBehaviors: (done: Int, total: Int)?

    var isEmpty: Bool {
        stayed == nil && predictionsMissed == nil && withoutSafetyBehaviors == nil
    }
}

// MARK: - Active rule

/// The rule that fired, if any (spec §2.3.2). Carries which exercise it belongs
/// to so the tap can open that flow with the value already applied — History has
/// no session of its own to apply it to (plan `11.6-shell.md` §2, decision 8).
nonisolated struct ActiveRule {
    enum Exercise {
        case breathing
        case relaxation
    }

    let exercise: Exercise
    let text: String
    let direction: LadderRuleRow.Direction
}

// MARK: - View model

/// Logic of the History tab (spec §2.3). Everything is derived from the logs on
/// the fly — no denormalised counters, which would be a second truth to keep in
/// sync (plan `11.6-shell.md` §2, decision 3).
///
/// Time is injected, so grouping by day can be tested without waiting for
/// midnight.
@Observable @MainActor
final class HistoryViewModel {

    private let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    // MARK: Ladder positions

    func ladderPositions(
        breathing: [BreathingSessionEntry],
        pmr: [PMRSessionEntry],
        activation: [BALogEntry]
    ) -> [LadderPosition] {
        var positions: [LadderPosition] = []

        // Same source of truth as the launcher subtitles (§11.6a): if these two
        // ever disagree, one of them is lying about the same data.
        if let last = pmr.max(by: { $0.createdAt < $1.createdAt }), let step = last.step {
            positions.append(
                LadderPosition(
                    id: "pmr",
                    exercise: String(localized: "Relaxation"),
                    position: step.title
                )
            )
        }

        if let last = breathing.max(by: { $0.createdAt < $1.createdAt }) {
            let minutes = String(
                format: String(localized: "%@ min"),
                BreathingLadder.minutesLabel(seconds: last.plannedDurationSeconds)
            )
            let position = last.pattern.map {
                String(format: String(localized: "%1$@ · %2$@"), $0.title, minutes)
            } ?? minutes
            positions.append(
                LadderPosition(
                    id: "breathing",
                    exercise: String(localized: "Breathing"),
                    position: position
                )
            )
        }

        if let last = activation.max(by: { $0.createdAt < $1.createdAt }), let effort = last.effort {
            positions.append(
                LadderPosition(
                    id: "activation",
                    exercise: String(localized: "Behavioral Activation"),
                    position: effort.title
                )
            )
        }

        // Exposures are deliberately absent: §3 gives them two independent
        // columns, not a ladder.
        return positions
    }

    // MARK: Active rule

    func activeRule(
        breathing: [BreathingSessionEntry],
        pmr: [PMRSessionEntry]
    ) -> ActiveRule? {
        let pmrHistory = pmr
            .sorted { $0.createdAt > $1.createdAt }
            .compactMap(PMRLadder.Outcome.init(entry:))
        if let current = pmrHistory.first?.step,
           let suggestion = PMRLadder.suggestion(history: pmrHistory, currentStep: current) {
            return ActiveRule(
                exercise: .relaxation,
                text: Self.pmrRuleText(suggestion),
                direction: suggestion.isStepDown ? .down : .up
            )
        }

        let breathingSessions = breathing.sorted { $0.createdAt > $1.createdAt }
        if let last = breathingSessions.first, let pattern = last.pattern {
            let history = breathingSessions.compactMap(BreathingLadder.Outcome.init(entry:))
            if let suggestion = BreathingLadder.suggestion(
                history: history,
                pattern: pattern,
                currentDuration: last.plannedDurationSeconds
            ) {
                return ActiveRule(
                    exercise: .breathing,
                    text: Self.breathingRuleText(suggestion),
                    direction: suggestion.isStepDown ? .down : .up
                )
            }
        }

        // At most one rule at a time. Two accent cards would be two primary
        // actions on a screen whose job is reading (codex §1); PMR goes first
        // because it is the longer exercise and its steps move more slowly.
        return nil
    }

    // MARK: Exposure statistics

    /// Spec §2.3.3. The window matches the launcher subtitle
    /// (`ExerciseStatus.ratioWindow`) on purpose: a tile saying "6 of 7" beside
    /// a History block saying "41 of 55" would look like one of them is broken.
    func exposureStats(_ entries: [ExposureLogEntry]) -> ExposureStats {
        let recent = entries
            .sorted { $0.createdAt > $1.createdAt }
            .prefix(ExerciseStatus.ratioWindow)

        let judged = recent.filter { $0.behavior != nil }
        let stayed = judged.isEmpty
            ? nil
            : (done: judged.filter { $0.behavior != .leftEarly }.count, total: judged.count)

        // Only planned sessions carry a prediction — a situational entry has no
        // "before", so counting it here would invent data (§1.6, §2.3.3).
        let predicted = recent.filter { $0.isPlanned && $0.predictionOutcome != nil }
        let missed = predicted.isEmpty
            ? nil
            : (
                done: predicted.filter { $0.predictionOutcome == .didNotComeTrue }.count,
                total: predicted.count
            )

        let clean = judged.isEmpty
            ? nil
            : (done: judged.filter { $0.safetyBehaviors.isEmpty }.count, total: judged.count)

        return ExposureStats(
            stayed: stayed,
            predictionsMissed: missed,
            withoutSafetyBehaviors: clean
        )
    }

    // MARK: Feed

    func feed(
        exposures: [ExposureLogEntry],
        breathing: [BreathingSessionEntry],
        pmr: [PMRSessionEntry],
        activation: [BALogEntry]
    ) -> [HistoryDay] {
        var items: [HistoryItem] = []

        for entry in exposures {
            items.append(
                .exposure(
                    id: "exposure-\(entry.persistentModelID.hashValue)",
                    date: entry.createdAt,
                    title: String(localized: "Exposure"),
                    detail: Self.exposureDetail(entry),
                    isSituational: !entry.isPlanned
                )
            )
        }

        for entry in breathing {
            items.append(
                .breathing(
                    id: "breathing-\(entry.persistentModelID.hashValue)",
                    date: entry.createdAt,
                    title: String(localized: "Breathing"),
                    detail: Self.breathingDetail(entry)
                )
            )
        }

        for entry in pmr {
            items.append(
                .pmr(
                    id: "pmr-\(entry.persistentModelID.hashValue)",
                    date: entry.createdAt,
                    title: String(localized: "Relaxation"),
                    detail: Self.pmrDetail(entry)
                )
            )
        }

        for entry in activation {
            items.append(
                .activation(
                    id: "ba-\(entry.persistentModelID.hashValue)",
                    date: entry.createdAt,
                    title: String(localized: "Behavioral Activation"),
                    detail: Self.activationDetail(entry)
                )
            )
        }

        items.append(contentsOf: medals(pmr: pmr))

        return group(items)
    }

    /// Spec §5: the medal's only surface is a line in the feed.
    ///
    /// `PMRLadder.earnedMedals` returns a set with no dates, so the day is
    /// recovered here — the first session on that step that was seen through.
    /// Nothing is stored: the medal is as derived as the ladder itself, which is
    /// what makes it impossible to lose (§5: "не отнимается при спуске").
    private func medals(pmr: [PMRSessionEntry]) -> [HistoryItem] {
        let byDate = pmr.sorted { $0.createdAt < $1.createdAt }
        let earned = PMRLadder.earnedMedals(
            history: byDate.compactMap(PMRLadder.Outcome.init(entry:))
        )

        return earned.compactMap { step in
            guard let first = byDate.first(where: { entry in
                entry.step == step
                    && PMRLadder.Outcome(entry: entry)?.didFinishEarly == false
            }) else { return nil }

            return .medal(
                id: "medal-\(step.rawValue)",
                date: first.createdAt,
                title: String(localized: "Relaxation"),
                detail: String(format: String(localized: "%@ learned"), step.title)
            )
        }
    }

    private func group(_ items: [HistoryItem]) -> [HistoryDay] {
        let byDay = Dictionary(grouping: items) { calendar.startOfDay(for: $0.date) }
        return byDay
            .map { day, items in
                HistoryDay(id: day, items: items.sorted { $0.date > $1.date })
            }
            .sorted { $0.id > $1.id }
    }

    // MARK: Detail copy

    /// Spec §1.5 shows up here: a session that ended early is stated as a fact,
    /// never hidden and never softened.
    private static func exposureDetail(_ entry: ExposureLogEntry) -> String {
        var parts: [String] = []
        if let anxiety = entry.anxiety {
            parts.append(String(format: String(localized: "anxiety %d"), anxiety))
        }
        if let behavior = entry.behavior {
            parts.append(behavior.title.lowercased())
        }
        return parts.joined(separator: " · ")
    }

    private static func breathingDetail(_ entry: BreathingSessionEntry) -> String {
        var parts: [String] = []
        if let pattern = entry.pattern {
            parts.append(pattern.title)
        }
        parts.append(
            String(
                format: String(localized: "%@ min"),
                BreathingLadder.minutesLabel(seconds: entry.plannedDurationSeconds)
            )
        )
        if let didRelax = entry.didRelax {
            parts.append(
                didRelax
                    ? String(localized: "relaxed in time")
                    : String(localized: "didn't relax in time")
            )
        }
        return parts.joined(separator: " · ")
    }

    private static func pmrDetail(_ entry: PMRSessionEntry) -> String {
        var parts: [String] = []
        if let step = entry.step {
            parts.append(step.title)
        }
        if let didRelax = entry.didRelax {
            parts.append(
                didRelax
                    ? String(localized: "relaxed in time")
                    : String(localized: "didn't relax in time")
            )
        }
        return parts.joined(separator: " · ")
    }

    private static func activationDetail(_ entry: BALogEntry) -> String {
        var parts = [entry.activityTitle]
        switch entry.outcome {
        case .done: parts.append(String(localized: "did it"))
        case .couldNot: parts.append(String(localized: "couldn't"))
        case nil: parts.append(String(localized: "still open"))
        }
        return parts.joined(separator: " · ")
    }

    private static func breathingRuleText(_ suggestion: BreathingLadder.Suggestion) -> String {
        let minutes = BreathingLadder.minutesLabel(seconds: suggestion.seconds)
        switch suggestion {
        case .stepDown:
            return String(
                format: String(localized: "Five in a row you relaxed in time. Try %@ min?"),
                minutes
            )
        case .stepUp:
            return String(
                format: String(localized: "Twice in a row you didn't relax in time. Back to %@ min?"),
                minutes
            )
        }
    }

    private static func pmrRuleText(_ suggestion: PMRLadder.Suggestion) -> String {
        switch suggestion {
        case .stepDown(let step):
            return String(
                format: String(localized: "Five in a row you managed to relax. Try %@?"),
                step.title
            )
        case .stepUp(let step):
            return String(
                format: String(localized: "Twice in a row you didn't. Back to %@?"),
                step.title
            )
        }
    }
}

// MARK: - Suggestion direction

extension BreathingLadder.Suggestion {
    var isStepDown: Bool {
        if case .stepDown = self { return true }
        return false
    }
}

extension PMRLadder.Suggestion {
    var isStepDown: Bool {
        if case .stepDown = self { return true }
        return false
    }
}
