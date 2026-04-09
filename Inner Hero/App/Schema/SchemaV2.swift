import Foundation
import SwiftData

/// Schema version 2.0.0 — Behavioral Activation rewrite.
/// Changes from V1:
///   - Added: ActivationCategory, ActivationTask, ActivationSession
///   - Removed: ActivityList, BehavioralActivationSession
///   - ExerciseAssignment: activityListId renamed to activityId
enum SchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            ExposureStep.self,
            Exposure.self,
            ExposureSessionResult.self,
            BreathingSessionResult.self,
            RelaxationSessionResult.self,
            GroundingSessionResult.self,
            ActivationCategory.self,
            ActivationTask.self,
            ActivationSession.self,
            ExerciseAssignment.self,
            ExerciseCompletion.self,
            FavoriteExercise.self,
        ]
    }
}
