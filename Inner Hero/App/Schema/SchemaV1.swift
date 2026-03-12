import Foundation
import SwiftData

/// Schema version 1.0.0 — all models as initially shipped.
/// When adding SchemaV2: add new enum, add to AppMigrationPlan.schemas, add MigrationStage if needed.
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
            ActivityList.self,
            BehavioralActivationSession.self,
            ExerciseAssignment.self,
            ExerciseCompletion.self,
            FavoriteExercise.self
        ]
    }
}
