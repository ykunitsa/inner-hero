import Foundation
import SwiftData

// Storage contract: rawValues are persisted in SwiftData. NEVER rename rawValue strings — only add new cases.
enum BreathingPatternType: String, Codable {
    case box = "box"
    case fourSix = "fourSix"
    case paced = "paced"
}

// MARK: - BreathingSessionResult Model

@Model
final class BreathingSessionResult {
    @Attribute(.unique) var id: UUID
    var performedAt: Date
    var duration: TimeInterval
    var patternType: BreathingPatternType
    
    init(
        id: UUID = UUID(),
        performedAt: Date = Date(),
        duration: TimeInterval,
        patternType: BreathingPatternType
    ) {
        self.id = id
        self.performedAt = performedAt
        self.duration = duration
        self.patternType = patternType
    }
}

