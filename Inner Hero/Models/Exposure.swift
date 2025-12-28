import Foundation
import SwiftData

// MARK: - ExposureStep Model

@Model
final class ExposureStep {
    var text: String
    var hasTimer: Bool
    var timerDuration: Int
    var order: Int
    
    init(text: String, hasTimer: Bool = false, timerDuration: Int = 300, order: Int = 0) {
        self.text = text
        self.hasTimer = hasTimer
        self.timerDuration = timerDuration
        self.order = order
    }
}

// MARK: - Exposure Model

@Model
final class Exposure {
    @Attribute(.unique) var id: UUID
    var title: String
    var exposureDescription: String
    var steps: [ExposureStep]
    var createdAt: Date
    
    @Relationship(deleteRule: .cascade, inverse: \ExposureSessionResult.exposure)
    var sessionResults: [ExposureSessionResult]
    
    var assignment: ExerciseAssignment?
    
    init(
        id: UUID = UUID(),
        title: String,
        exposureDescription: String,
        steps: [ExposureStep] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.exposureDescription = exposureDescription
        self.steps = steps
        self.createdAt = createdAt
        self.sessionResults = []
    }
}
