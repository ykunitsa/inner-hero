import Foundation
import SwiftData

@Observable
@MainActor
final class BreathingSessionViewModel {
    var sessionStartTime: Date = Date()
    var isCompleted: Bool = false

    /// Creates BreathingSessionResult and optionally marks assignment completed.
    func saveSession(
        patternType: BreathingPatternType,
        duration: TimeInterval,
        assignment: ExerciseAssignment?,
        context: ModelContext
    ) throws {
        let result = BreathingSessionResult(
            duration: duration,
            patternType: patternType
        )
        context.insert(result)
        try context.save()
        if let assignment {
            try SessionCompletionService.markCompletedIfNeeded(assignmentId: assignment.id, context: context)
        }
        isCompleted = true
    }
}
