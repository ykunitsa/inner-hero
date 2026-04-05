import Foundation
import SwiftData

/// Schema version 2.0.0 — adds BAActivity and BASession; deprecates ActivityList and BehavioralActivationSession.
/// When adding SchemaV3: add new enum, add to AppMigrationPlan.schemas, add MigrationStage if needed.
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
            ActivityList.self,
            BehavioralActivationSession.self,
            BAActivity.self,
            BASession.self,
            ExerciseAssignment.self,
            ExerciseCompletion.self,
            FavoriteExercise.self
        ]
    }
}
