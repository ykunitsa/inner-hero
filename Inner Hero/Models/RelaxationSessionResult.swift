import Foundation
import SwiftData

// MARK: - RelaxationType Enum

enum RelaxationType: String, Codable {
    case fullBody
    case short
}

// MARK: - RelaxationSessionResult Model

@Model
final class RelaxationSessionResult {
    @Attribute(.unique) var id: UUID
    var performedAt: Date
    var duration: TimeInterval
    var type: RelaxationType
    
    init(
        id: UUID = UUID(),
        performedAt: Date = Date(),
        duration: TimeInterval,
        type: RelaxationType
    ) {
        self.id = id
        self.performedAt = performedAt
        self.duration = duration
        self.type = type
    }
}

