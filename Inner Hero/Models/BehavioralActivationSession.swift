import Foundation
import SwiftData

// MARK: - BehavioralActivationSession Model

@Model
final class BehavioralActivationSession {
    @Attribute(.unique) var id: UUID
    var startedAt: Date
    var completedAt: Date?
    var selectedActivity: String
    var pleasureRating: Int?
    
    init(
        id: UUID = UUID(),
        startedAt: Date = Date(),
        completedAt: Date? = nil,
        selectedActivity: String,
        pleasureRating: Int? = nil
    ) {
        self.id = id
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.selectedActivity = selectedActivity
        self.pleasureRating = pleasureRating
    }
}

