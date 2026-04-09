import Foundation
import SwiftData

// MARK: - V1-only models (removed in SchemaV2)
// These types exist solely so SchemaV1 can reference them during migration.
// Do NOT use ActivityListV1 or BehavioralActivationSessionV1 anywhere outside this file.

@Model
final class ActivityListV1 {
    @Attribute(.unique) var id: UUID
    var title: String
    var predefinedKey: String?
    var activities: [String]
    var isPredefined: Bool

    init(id: UUID = UUID(), title: String, predefinedKey: String? = nil, activities: [String] = [], isPredefined: Bool = false) {
        self.id = id; self.title = title; self.predefinedKey = predefinedKey; self.activities = activities; self.isPredefined = isPredefined
    }
}

@Model
final class BehavioralActivationSessionV1 {
    @Attribute(.unique) var id: UUID
    var startedAt: Date
    var completedAt: Date?
    var selectedActivity: String
    var pleasureRating: Int?

    init(id: UUID = UUID(), startedAt: Date = Date(), completedAt: Date? = nil, selectedActivity: String, pleasureRating: Int? = nil) {
        self.id = id; self.startedAt = startedAt; self.completedAt = completedAt; self.selectedActivity = selectedActivity; self.pleasureRating = pleasureRating
    }
}

// MARK: - SchemaV1

/// Schema version 1.0.0 — all models as initially shipped.
enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            ExposureStep.self,
            Exposure.self,
            ExposureSessionResult.self,
            BreathingSessionResult.self,
            RelaxationSessionResult.self,
            GroundingSessionResult.self,
            ActivityListV1.self,
            BehavioralActivationSessionV1.self,
            ExerciseAssignment.self,
            ExerciseCompletion.self,
            FavoriteExercise.self,
        ]
    }
}
