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

// MARK: - Exposure Log Entry

/// One exposure record (spec §3). Situational and planned sessions share this
/// table: prediction columns arrive with the planned flow (§11.2) and simply
/// stay empty on situational entries — no `isPlanned` flag.
@Model
final class ExposureLogEntry {
    var createdAt: Date
    var situation: String
    /// Anxiety intensity 0–10. Intensity only — no tolerability semantics.
    var anxiety: Int
    var behaviorRaw: String
    /// Safety behaviors as free-form chip texts; empty array = "nothing".
    var safetyBehaviors: [String]
    var note: String?

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

    var behavior: ExposureBehavior? {
        ExposureBehavior(rawValue: behaviorRaw)
    }
}
