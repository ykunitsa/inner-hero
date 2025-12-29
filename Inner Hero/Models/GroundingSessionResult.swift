import Foundation
import SwiftData

// MARK: - GroundingSessionResult

@Model
final class GroundingSessionResult {
    @Attribute(.unique) var id: UUID
    var performedAt: Date
    var duration: TimeInterval
    var type: GroundingType
    
    init(
        id: UUID = UUID(),
        performedAt: Date = Date(),
        duration: TimeInterval,
        type: GroundingType
    ) {
        self.id = id
        self.performedAt = performedAt
        self.duration = duration
        self.type = type
    }
}


