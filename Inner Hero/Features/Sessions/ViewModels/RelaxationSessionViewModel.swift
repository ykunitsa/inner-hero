import Foundation
import SwiftData

@Observable
@MainActor
final class RelaxationSessionViewModel {
    var sessionStartTime: Date = Date()
    var isCompleted: Bool = false

    /// Creates RelaxationSessionResult and optionally marks assignment completed.
    func saveSession(
        type: RelaxationType,
        duration: TimeInterval,
        assignment: ExerciseAssignment?,
        context: ModelContext
    ) throws {
        let result = RelaxationSessionResult(
            duration: duration,
            type: type
        )
        context.insert(result)
        try context.save()
        if let assignment {
            try SessionCompletionService.markCompletedIfNeeded(assignmentId: assignment.id, context: context)
        }
        isCompleted = true
    }
}
