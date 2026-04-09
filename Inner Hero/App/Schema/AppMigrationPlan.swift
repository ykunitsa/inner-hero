import Foundation
import SwiftData

/// Migration plan for the app. Add new VersionedSchema types to `schemas` and
/// append to `stages` when custom migration logic is required (e.g. data transform).
enum AppMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV2.self]
    }

    static var stages: [MigrationStage] {
        [migrateV1toV2]
    }

    // MARK: - V1 → V2

    /// Removes legacy BA data and seeds new ActivationCategory / ActivationTask records.
    static let migrateV1toV2 = MigrationStage.custom(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self,
        willMigrate: { context in
            // 1. Delete all BA ExerciseAssignment records.
            //    Their activityId (formerly activityListId) points to now-deleted ActivityListV1
            //    UUIDs which will never match any ActivationTask → orphaned records.
            let baAssignments = try context.fetch(FetchDescriptor<ExerciseAssignment>())
                .filter { $0.exerciseType == .behavioralActivation }
            let baAssignmentIds = Set(baAssignments.map(\.id))
            for assignment in baAssignments { context.delete(assignment) }

            // 2. Delete ExerciseCompletion records linked to those assignments.
            //    Also catch any remaining BA completions by exerciseType snapshot
            //    to cover any edge-case orphans.
            let allCompletions = try context.fetch(FetchDescriptor<ExerciseCompletion>())
            for completion in allCompletions
            where baAssignmentIds.contains(completion.assignmentId)
               || completion.exerciseType == .behavioralActivation {
                context.delete(completion)
            }

            // 3. Delete legacy BA models.
            let lists = try context.fetch(FetchDescriptor<ActivityListV1>())
            for item in lists { context.delete(item) }

            let sessions = try context.fetch(FetchDescriptor<BehavioralActivationSessionV1>())
            for item in sessions { context.delete(item) }

            // 4. Remove BA favorites — exerciseId pointed to ActivityListV1, now stale.
            let favorites = try context.fetch(FetchDescriptor<FavoriteExercise>())
            for fav in favorites where fav.exerciseType == .behavioralActivation {
                context.delete(fav)
            }

            try context.save()
        },
        didMigrate: { context in
            // Seed preset categories and tasks into the new schema.
            for category in PresetActivationData.categories {
                context.insert(category)
            }
            for task in PresetActivationData.tasks {
                context.insert(task)
            }
            try context.save()
        }
    )
}
