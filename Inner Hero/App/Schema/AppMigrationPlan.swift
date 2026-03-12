import Foundation
import SwiftData

/// Migration plan for the app. Add new VersionedSchema types to `schemas` and
/// append to `stages` when custom migration logic is required (e.g. data transform).
enum AppMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self]
    }

    static var stages: [MigrationStage] {
        []
    }
}
