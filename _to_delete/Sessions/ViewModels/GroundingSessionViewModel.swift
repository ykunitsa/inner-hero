import Foundation
import SwiftData

@Observable
@MainActor
final class GroundingSessionViewModel {
    var sessionStartTime: Date = Date()
    var isCompleted: Bool = false

    /// Creates GroundingSessionResult and optionally marks assignment completed.
    func saveSession(
        type: GroundingType,
        duration: TimeInterval,
        assignment: ExerciseAssignment?,
        context: ModelContext
    ) throws {
        let result = GroundingSessionResult(
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
