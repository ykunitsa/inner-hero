import Foundation
import SwiftData

@Model
final class SessionResult {
    @Attribute(.unique) var id: UUID
    var startAt: Date
    var endAt: Date?
    var anxietyBefore: Int
    var anxietyAfter: Int?
    var notes: String
    
    // Step tracking
    var completedStepIndices: [Int] = []
    var stepTimings: [Int: TimeInterval] = [:]
    
    var exposure: Exposure?
    
    init(
        id: UUID = UUID(),
        exposure: Exposure? = nil,
        startAt: Date = Date(),
        endAt: Date? = nil,
        anxietyBefore: Int,
        anxietyAfter: Int? = nil,
        notes: String = "",
        completedStepIndices: [Int] = [],
        stepTimings: [Int: TimeInterval] = [:]
    ) {
        self.id = id
        self.exposure = exposure
        self.startAt = startAt
        self.endAt = endAt
        self.anxietyBefore = anxietyBefore
        self.anxietyAfter = anxietyAfter
        self.notes = notes
        self.completedStepIndices = completedStepIndices
        self.stepTimings = stepTimings
    }
    
    // MARK: - Helper Methods
    
    func isStepCompleted(_ stepIndex: Int) -> Bool {
        return completedStepIndices.contains(stepIndex)
    }
    
    func markStepCompleted(_ stepIndex: Int) {
        if !completedStepIndices.contains(stepIndex) {
            completedStepIndices.append(stepIndex)
            completedStepIndices.sort()
        }
    }
    
    func markStepIncomplete(_ stepIndex: Int) {
        completedStepIndices.removeAll { $0 == stepIndex }
    }
    
    func setStepTime(_ stepIndex: Int, time: TimeInterval) {
        stepTimings[stepIndex] = time
    }
    
    func getStepTime(_ stepIndex: Int) -> TimeInterval {
        return stepTimings[stepIndex] ?? 0
    }
    
    func getTotalStepsTime() -> TimeInterval {
        return stepTimings.values.reduce(0, +)
    }
}
