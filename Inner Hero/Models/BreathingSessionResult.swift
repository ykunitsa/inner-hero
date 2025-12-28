import Foundation
import SwiftData

// MARK: - BreathingPatternType Enum

enum BreathingPatternType: String, Codable {
    case box
    case fourSix
    case paced
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

