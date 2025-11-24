//
//  SampleDataLoader.swift
//  Inner Hero
//
//  Sample data loader for testing and demo purposes
//

import Foundation
import SwiftData

/// Загрузчик тестовых данных для приложения
struct SampleDataLoader {
    
    // MARK: - Sample Data Structure
    
    private struct SampleExposureData: Codable {
        let title: String
        let description: String
        let steps: [String]
    }
    
    private struct SampleData: Codable {
        let exposures: [SampleExposureData]
    }
    
    // MARK: - Loading Methods
    
    /// Загрузить примеры экспозиций из JSON файла
    /// - Parameters:
    ///   - modelContext: Контекст модели SwiftData
    ///   - fileName: Имя JSON файла (по умолчанию "SampleData")
    /// - Throws: Ошибка при загрузке или парсинге данных
    static func loadSampleExposures(
        into modelContext: ModelContext,
        from fileName: String = "SampleData"
    ) throws {
        // Загрузить JSON из бандла
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json") else {
            throw SampleDataError.fileNotFound
        }
        
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let sampleData = try decoder.decode(SampleData.self, from: data)
        
        // Создать экспозиции
        for exposureData in sampleData.exposures {
            // Конвертируем строковые шаги в Step объекты
            let steps = exposureData.steps.enumerated().map { index, text in
                Step(text: text, hasTimer: false, timerDuration: 0, order: index)
            }
            
            let exposure = Exposure(
                title: exposureData.title,
                exposureDescription: exposureData.description,
                steps: steps
            )
            modelContext.insert(exposure)
        }
        
        try modelContext.save()
    }
    
    /// Создать программные примеры экспозиций (без JSON)
    /// - Parameter modelContext: Контекст модели SwiftData
    /// - Throws: Ошибка при сохранении
    static func loadHardcodedSampleExposures(into modelContext: ModelContext) throws {
        // Вспомогательная функция для создания Step объектов
        func createSteps(from texts: [String]) -> [Step] {
            texts.enumerated().map { index, text in
                Step(text: text, hasTimer: false, timerDuration: 0, order: index)
            }
        }
        
        let samples = [
            Exposure(
                title: "Публичное выступление",
                exposureDescription: "Выступление перед небольшой группой людей с коротким рассказом о себе",
                steps: createSteps(from: [
                    "Подготовить короткий рассказ о себе (2-3 минуты)",
                    "Найти группу из 5-10 человек (друзья, коллеги)",
                    "Встать перед группой и представиться",
                    "Рассказать о своих увлечениях",
                    "Ответить на 2-3 вопроса от аудитории"
                ])
            ),
            Exposure(
                title: "Поездка в лифте",
                exposureDescription: "Самостоятельная поездка в лифте в многоэтажном здании",
                steps: createSteps(from: [
                    "Подойти к лифту в торговом центре или офисном здании",
                    "Нажать кнопку вызова лифта",
                    "Войти в лифт и нажать кнопку 5-го этажа",
                    "Постоять в лифте с закрытыми дверями",
                    "Выйти на нужном этаже",
                    "Повторить спуск обратно"
                ])
            ),
            Exposure(
                title: "Знакомство в кафе",
                exposureDescription: "Начать разговор с незнакомым человеком в общественном месте",
                steps: createSteps(from: [
                    "Прийти в кафе или коворкинг",
                    "Выбрать человека, который не занят",
                    "Подойти с улыбкой",
                    "Начать с простого вопроса (например, о Wi-Fi)",
                    "Если человек открыт к общению, представиться",
                    "Поддержать короткий диалог 2-3 минуты",
                    "Вежливо завершить разговор"
                ])
            )
        ]
        
        for exposure in samples {
            modelContext.insert(exposure)
        }
        
        try modelContext.save()
    }
    
    /// Создать примеры сеансов для существующих экспозиций (для тестирования)
    /// - Parameters:
    ///   - exposures: Массив экспозиций, для которых создать сеансы
    ///   - modelContext: Контекст модели SwiftData
    /// - Throws: Ошибка при сохранении
    static func loadSampleSessions(
        for exposures: [Exposure],
        into modelContext: ModelContext
    ) throws {
        let calendar = Calendar.current
        let now = Date()
        
        for exposure in exposures {
            // Создать 3-5 сеансов для каждой экспозиции
            let sessionCount = Int.random(in: 3...5)
            
            for i in 0..<sessionCount {
                // Создать сеансы за последние 2 недели
                let daysAgo = Double(sessionCount - i) * 2.0
                guard let startDate = calendar.date(byAdding: .day, value: -Int(daysAgo), to: now) else {
                    continue
                }
                
                let anxietyBefore = Int.random(in: 6...10)
                let anxietyAfter = max(1, anxietyBefore - Int.random(in: 2...4))
                
                let duration = TimeInterval(Int.random(in: 10...30) * 60) // 10-30 минут
                let endDate = startDate.addingTimeInterval(duration)
                
                let notes = [
                    "Сначала было тяжело, но постепенно стало легче",
                    "Использовал дыхательные техники",
                    "Удалось справиться с тревогой",
                    "Было проще, чем ожидал",
                    "Потребовалось больше времени, чем планировал"
                ].randomElement() ?? ""
                
                let session = SessionResult(
                    exposure: exposure,
                    startAt: startDate,
                    endAt: endDate,
                    anxietyBefore: anxietyBefore,
                    anxietyAfter: anxietyAfter,
                    notes: notes
                )
                
                modelContext.insert(session)
            }
        }
        
        try modelContext.save()
    }
    
    /// Проверить, есть ли уже данные в базе
    /// - Parameter modelContext: Контекст модели SwiftData
    /// - Returns: true, если база данных пустая
    static func isDatabaseEmpty(_ modelContext: ModelContext) throws -> Bool {
        let descriptor = FetchDescriptor<Exposure>()
        let exposures = try modelContext.fetch(descriptor)
        return exposures.isEmpty
    }
}

// MARK: - Errors

enum SampleDataError: LocalizedError {
    case fileNotFound
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "Файл с тестовыми данными не найден"
        case .invalidData:
            return "Неверный формат данных"
        }
    }
}

