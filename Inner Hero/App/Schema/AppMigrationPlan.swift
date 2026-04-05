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

    /// Lightweight migration: adds BAActivity and BASession tables; no data transformation needed.
    static let migrateV1toV2 = MigrationStage.lightweight(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self
    )
}
