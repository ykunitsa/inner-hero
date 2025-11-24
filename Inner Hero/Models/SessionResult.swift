//
//  SessionResult.swift
//  Inner Hero
//
//  Created by Yauheni Kunitsa on 21.10.25.
//

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
    var completedStepIndices: [Int] = [] // Индексы выполненных шагов
    var stepTimings: [Int: TimeInterval] = [:] // Время, проведённое на каждом шаге (индекс -> секунды)
    
    // Связь многие-к-одному: много результатов сеансов связаны с одной экспозицией
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
    
    /// Проверить, выполнен ли шаг
    func isStepCompleted(_ stepIndex: Int) -> Bool {
        return completedStepIndices.contains(stepIndex)
    }
    
    /// Отметить шаг как выполненный
    func markStepCompleted(_ stepIndex: Int) {
        if !completedStepIndices.contains(stepIndex) {
            completedStepIndices.append(stepIndex)
            completedStepIndices.sort()
        }
    }
    
    /// Отметить шаг как невыполненный
    func markStepIncomplete(_ stepIndex: Int) {
        completedStepIndices.removeAll { $0 == stepIndex }
    }
    
    /// Сохранить время для шага
    func setStepTime(_ stepIndex: Int, time: TimeInterval) {
        stepTimings[stepIndex] = time
    }
    
    /// Получить время для шага
    func getStepTime(_ stepIndex: Int) -> TimeInterval {
        return stepTimings[stepIndex] ?? 0
    }
    
    /// Получить общее время всех шагов
    func getTotalStepsTime() -> TimeInterval {
        return stepTimings.values.reduce(0, +)
    }
}

