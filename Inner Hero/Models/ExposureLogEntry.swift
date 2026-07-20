import Foundation
import SwiftData

// MARK: - Exposure Behavior

/// The behavior column of an exposure entry (spec §3): a fact, kept independent
/// from the anxiety intensity column so the two can diverge in the data.
enum ExposureBehavior: String, CaseIterable {
    // Persisted rawValues — never rename (CLAUDE.md).
    case stayed
    case wantedToLeaveButStayed
    case leftEarly

    var title: String {
        switch self {
        case .stayed: String(localized: "Stayed until the end")
        case .wantedToLeaveButStayed: String(localized: "Wanted to leave, but stayed")
        case .leftEarly: String(localized: "Left early")
        }
    }
}

// MARK: - Prediction Confidence

/// How sure the user is that the feared outcome will happen (spec §3, planned
/// "before" block). Words, not percentages — percentages are false precision.
enum PredictionConfidence: String, CaseIterable {
    // Persisted rawValues — never rename (CLAUDE.md).
    case certain
    case likely
    case fiftyFifty
    case unlikely

    var title: String {
        switch self {
        case .certain: String(localized: "Definitely")
        case .likely: String(localized: "Probably")
        case .fiftyFifty: String(localized: "Fifty-fifty")
        case .unlikely: String(localized: "Unlikely")
        }
    }
}

// MARK: - Prediction Outcome

/// Whether the prediction came true (spec §3, planned "after" screen).
enum PredictionOutcome: String, CaseIterable {
    // Persisted rawValues — never rename (CLAUDE.md).
    case cameTrue
    case partially
    case didNotComeTrue

    var title: String {
        switch self {
        case .cameTrue: String(localized: "Yes")
        case .partially: String(localized: "Partially")
        case .didNotComeTrue: String(localized: "No")
        }
    }
}

// MARK: - Exposure Log Entry

/// One exposure record (spec §3). Situational and planned sessions share this
/// table: prediction columns simply stay empty on situational entries — no
/// `isPlanned` flag (derived: a prediction exists ⇔ the session was planned).
///
/// A planned entry is inserted at "Start" with the prediction block only —
/// that is principle 1.6 made physical (predictions are stored before the
/// session) and principle 1.5's safety net (killing the app mid-session
/// leaves a truthful partial record, not lost data). The "after" screen
/// fills in the fact columns.
@Model
final class ExposureLogEntry {
    var createdAt: Date
    var situation: String
    /// Anxiety intensity 0–10 (situational) / overall difficulty (planned).
    /// Intensity only — no tolerability semantics. Nil while a planned
    /// session has not reached its "after" screen.
    var anxiety: Int?
    /// Nil while a planned session has not reached its "after" screen.
    var behaviorRaw: String?
    /// Safety behaviors as free-form chip texts; empty array = "nothing".
    var safetyBehaviors: [String]
    var note: String?

    // Prediction block (planned sessions only, written at "Start").
    var fearedOutcome: String?
    var confidenceRaw: String?
    var expectedAnxiety: Int?
    var plannedMinSeconds: Int?
    var plannedMaxSeconds: Int?
    /// The hidden random end moment — part of the plan, so part of the data.
    var targetDurationSeconds: Int?

    // Fact block of a planned session.
    var actualDurationSeconds: Int?
    var predictionOutcomeRaw: String?

    /// Situational entry — everything is known at once.
    init(
        createdAt: Date,
        situation: String,
        anxiety: Int,
        behavior: ExposureBehavior,
        safetyBehaviors: [String],
        note: String? = nil
    ) {
        self.createdAt = createdAt
        self.situation = situation
        self.anxiety = anxiety
        self.behaviorRaw = behavior.rawValue
        self.safetyBehaviors = safetyBehaviors
        self.note = note
    }

    /// Planned entry at "Start": prediction block only, fact columns empty.
    init(
        plannedAt: Date,
        activity: String,
        fearedOutcome: String,
        confidence: PredictionConfidence,
        expectedAnxiety: Int,
        plannedMinSeconds: Int,
        plannedMaxSeconds: Int,
        targetDurationSeconds: Int
    ) {
        self.createdAt = plannedAt
        self.situation = activity
        self.safetyBehaviors = []
        self.fearedOutcome = fearedOutcome
        self.confidenceRaw = confidence.rawValue
        self.expectedAnxiety = expectedAnxiety
        self.plannedMinSeconds = plannedMinSeconds
        self.plannedMaxSeconds = plannedMaxSeconds
        self.targetDurationSeconds = targetDurationSeconds
    }

    var behavior: ExposureBehavior? {
        behaviorRaw.flatMap(ExposureBehavior.init(rawValue:))
    }

    var confidence: PredictionConfidence? {
        confidenceRaw.flatMap(PredictionConfidence.init(rawValue:))
    }

    var predictionOutcome: PredictionOutcome? {
        predictionOutcomeRaw.flatMap(PredictionOutcome.init(rawValue:))
    }

    /// Derived, never stored (spec §3: no `is_planned` with branches).
    var isPlanned: Bool {
        confidenceRaw != nil
    }
}
