import Foundation
import SwiftData

@Model
final class ExerciseCompletion {
    @Attribute(.unique) var id: UUID
    
    /// Uniqueness guard for (assignmentId, day).
    /// Format: "<assignmentUUID>|<startOfDayUnixSeconds>"
    @Attribute(.unique) var uniqueKey: String
    
    /// Start of day in the user's current calendar/timezone at the time of saving.
    var day: Date
    var createdAt: Date
    
    /// Links completion to a specific schedule item.
    var assignmentId: UUID
    
    // Snapshot fields for display resiliency (in case assignment changes/deletes).
    var exerciseType: ExerciseType
    var exposureId: UUID?
    var breathingPatternType: String?
    var relaxationType: String?
    var groundingType: String?
    var activityListId: UUID?
    
    init(
        id: UUID = UUID(),
        day: Date,
        createdAt: Date = Date(),
        assignment: ExerciseAssignment,
        calendar: Calendar = .current
    ) {
        let dayStart = calendar.startOfDay(for: day)
        
        self.id = id
        self.day = dayStart
        self.createdAt = createdAt
        
        self.assignmentId = assignment.id
        self.exerciseType = assignment.exerciseType
        self.exposureId = assignment.exposureId
        self.breathingPatternType = assignment.breathingPatternType
        self.relaxationType = assignment.relaxationType
        self.groundingType = assignment.groundingType
        self.activityListId = assignment.activityListId
        
        self.uniqueKey = "\(assignment.id.uuidString)|\(Int(dayStart.timeIntervalSince1970))"
    }
}


