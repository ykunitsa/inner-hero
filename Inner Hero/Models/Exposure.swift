//
//  Exposure.swift
//  Inner Hero
//
//  Created by Yauheni Kunitsa on 21.10.25.
//

import Foundation
import SwiftData

// MARK: - Step Model

@Model
final class Step {
    var text: String
    var hasTimer: Bool
    var timerDuration: Int // Длительность в секундах
    var order: Int // Порядковый номер шага
    
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
    var steps: [Step]
    var createdAt: Date
    
    // Один-ко-многим: одна экспозиция может иметь много результатов сеансов
    @Relationship(deleteRule: .cascade, inverse: \SessionResult.exposure)
    var sessionResults: [SessionResult]
    
    init(
        id: UUID = UUID(),
        title: String,
        exposureDescription: String,
        steps: [Step] = [],
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

