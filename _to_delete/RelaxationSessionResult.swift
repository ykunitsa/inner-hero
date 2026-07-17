import Foundation
import SwiftData

// Storage contract: rawValues are persisted in SwiftData. NEVER rename rawValue strings — only add new cases.
enum RelaxationType: String, Codable {
    case fullBody = "fullBody"
    case short = "short"
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

