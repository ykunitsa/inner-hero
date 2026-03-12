import Foundation
import SwiftData

/// Stateless helper for idempotent session completion: creates at most one `ExerciseCompletion`
/// per (assignment, day) per day.
///
/// **What it does:** Marks a scheduled assignment as completed for the given day by creating
/// an `ExerciseCompletion` record when one does not already exist for that assignment and day.
///
/// **Why idempotent:** Uses `ExerciseCompletion.uniqueKey` (format: `"<assignmentUUID>|<startOfDayUnixSeconds>"`).
/// If a completion with that key already exists (e.g. user finished the session twice, or multiple
/// code paths call completion), the method does not create a duplicate and returns `nil`.
///
/// **Usage:** Call from any view or flow that "completes" a session (exposure, breathing, relaxation,
/// grounding, behavioral activation). Pass the current `assignment.id` and `modelContext` from
/// the environment. Optionally use the returned `ExerciseCompletion?` (e.g. for analytics);
/// the result can be discarded.
struct SessionCompletionService {

    /// Idempotently marks the given assignment as completed for today.
    /// - Parameters:
    ///   - assignmentId: ID of the `ExerciseAssignment` to mark completed.
    ///   - context: SwiftData `ModelContext` (e.g. from `@Environment(\.modelContext)`).
    ///   - day: Day to use for "today" (defaults to `Date()`).
    ///   - calendar: Calendar for start-of-day (defaults to `.current`).
    /// - Returns: The newly created `ExerciseCompletion`, or `nil` if a completion for this
    ///   assignment and day already exists (idempotent no-op).
    /// - Throws: If the assignment is not found, or SwiftData fetch/save fails.
    @discardableResult
    static func markCompletedIfNeeded(
        assignmentId: UUID,
        context: ModelContext,
        day: Date = Date(),
        calendar: Calendar = .current
    ) throws -> ExerciseCompletion? {
        let assignmentDescriptor = FetchDescriptor<ExerciseAssignment>(
            predicate: #Predicate<ExerciseAssignment> { $0.id == assignmentId }
        )
        guard let assignment = try context.fetch(assignmentDescriptor).first else {
            throw SessionCompletionError.assignmentNotFound(assignmentId)
        }

        let dayStart = calendar.startOfDay(for: day)
        let uniqueKey = "\(assignment.id.uuidString)|\(Int(dayStart.timeIntervalSince1970))"

        let completionDescriptor = FetchDescriptor<ExerciseCompletion>(
            predicate: #Predicate<ExerciseCompletion> { $0.uniqueKey == uniqueKey }
        )

        if try context.fetch(completionDescriptor).first != nil {
            return nil
        }

        let completion = ExerciseCompletion(day: dayStart, assignment: assignment, calendar: calendar)
        context.insert(completion)
        try context.save()
        return completion
    }
}

enum SessionCompletionError: Error {
    case assignmentNotFound(UUID)
}
