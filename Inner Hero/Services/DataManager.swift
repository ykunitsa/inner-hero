//
//  DataManager.swift
//  Inner Hero
//
//  Created by Yauheni Kunitsa on 21.10.25.
//

import Foundation
import SwiftData

/// Сервисный слой для работы с данными SwiftData
/// Предоставляет CRUD операции для Exposure и SessionResult
@Observable
final class DataManager {
    private let modelContext: ModelContext
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Exposure Operations
    
    /// Создать новую экспозицию
    /// - Parameters:
    ///   - title: Название экспозиции
    ///   - description: Описание экспозиции
    ///   - steps: Шаги выполнения (Step объекты)
    /// - Returns: Созданная экспозиция
    @discardableResult
    func createExposure(
        title: String,
        description: String,
        steps: [Step] = []
    ) throws -> Exposure {
        let exposure = Exposure(
            title: title,
            exposureDescription: description,
            steps: steps
        )
        
        modelContext.insert(exposure)
        try saveContext()
        return exposure
    }
    
    /// Получить все экспозиции
    /// - Parameter sortDescriptors: Дескрипторы сортировки
    /// - Returns: Массив экспозиций
    func fetchAllExposures(sortBy sortDescriptors: [SortDescriptor<Exposure>] = []) throws -> [Exposure] {
        let descriptor = FetchDescriptor<Exposure>(sortBy: sortDescriptors)
        return try modelContext.fetch(descriptor)
    }
    
    /// Получить экспозиции с фильтрацией
    /// - Parameters:
    ///   - predicate: Предикат для фильтрации
    ///   - sortDescriptors: Дескрипторы сортировки
    /// - Returns: Массив отфильтрованных экспозиций
    func fetchExposures(
        where predicate: Predicate<Exposure>?,
        sortBy sortDescriptors: [SortDescriptor<Exposure>] = []
    ) throws -> [Exposure] {
        var descriptor = FetchDescriptor<Exposure>(sortBy: sortDescriptors)
        descriptor.predicate = predicate
        return try modelContext.fetch(descriptor)
    }
    
    /// Получить экспозицию по ID
    /// - Parameter id: UUID экспозиции
    /// - Returns: Экспозиция или nil
    func fetchExposure(byId id: UUID) throws -> Exposure? {
        let predicate = #Predicate<Exposure> { exposure in
            exposure.id == id
        }
        var descriptor = FetchDescriptor<Exposure>(predicate: predicate)
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }
    
    /// Обновить экспозицию
    /// - Parameters:
    ///   - exposure: Экспозиция для обновления
    ///   - title: Новое название (опционально)
    ///   - description: Новое описание (опционально)
    ///   - steps: Новые шаги (опционально)
    func updateExposure(
        _ exposure: Exposure,
        title: String? = nil,
        description: String? = nil,
        steps: [Step]? = nil
    ) throws {
        if let title = title {
            exposure.title = title
        }
        if let description = description {
            exposure.exposureDescription = description
        }
        if let steps = steps {
            exposure.steps = steps
        }
        
        try saveContext()
    }
    
    /// Удалить экспозицию
    /// - Parameter exposure: Экспозиция для удаления
    func deleteExposure(_ exposure: Exposure) throws {
        modelContext.delete(exposure)
        try saveContext()
    }
    
    /// Удалить экспозицию по ID
    /// - Parameter id: UUID экспозиции
    func deleteExposure(byId id: UUID) throws {
        if let exposure = try fetchExposure(byId: id) {
            try deleteExposure(exposure)
        }
    }
    
    /// Удалить несколько экспозиций
    /// - Parameter exposures: Массив экспозиций для удаления
    func deleteExposures(_ exposures: [Exposure]) throws {
        for exposure in exposures {
            modelContext.delete(exposure)
        }
        try saveContext()
    }
    
    // MARK: - SessionResult Operations
    
    /// Создать новый результат сеанса
    /// - Parameters:
    ///   - exposure: Связанная экспозиция
    ///   - anxietyBefore: Уровень тревоги до сеанса
    ///   - notes: Заметки
    /// - Returns: Созданный результат сеанса
    @discardableResult
    func createSessionResult(
        for exposure: Exposure,
        anxietyBefore: Int,
        notes: String = ""
    ) throws -> SessionResult {
        let session = SessionResult(
            exposure: exposure,
            anxietyBefore: anxietyBefore,
            notes: notes
        )
        
        modelContext.insert(session)
        try saveContext()
        return session
    }
    
    /// Получить все результаты сеансов
    /// - Parameter sortDescriptors: Дескрипторы сортировки
    /// - Returns: Массив результатов сеансов
    func fetchAllSessionResults(sortBy sortDescriptors: [SortDescriptor<SessionResult>] = []) throws -> [SessionResult] {
        let descriptor = FetchDescriptor<SessionResult>(sortBy: sortDescriptors)
        return try modelContext.fetch(descriptor)
    }
    
    /// Получить результаты сеансов с фильтрацией
    /// - Parameters:
    ///   - predicate: Предикат для фильтрации
    ///   - sortDescriptors: Дескрипторы сортировки
    /// - Returns: Массив отфильтрованных результатов
    func fetchSessionResults(
        where predicate: Predicate<SessionResult>?,
        sortBy sortDescriptors: [SortDescriptor<SessionResult>] = []
    ) throws -> [SessionResult] {
        var descriptor = FetchDescriptor<SessionResult>(sortBy: sortDescriptors)
        descriptor.predicate = predicate
        return try modelContext.fetch(descriptor)
    }
    
    /// Получить результаты сеансов для конкретной экспозиции
    /// - Parameter exposure: Экспозиция
    /// - Returns: Массив результатов сеансов
    func fetchSessionResults(for exposure: Exposure) throws -> [SessionResult] {
        let exposureId = exposure.id
        let predicate = #Predicate<SessionResult> { session in
            session.exposure?.id == exposureId
        }
        let sortDescriptors = [SortDescriptor(\SessionResult.startAt, order: .reverse)]
        return try fetchSessionResults(where: predicate, sortBy: sortDescriptors)
    }
    
    /// Получить результат сеанса по ID
    /// - Parameter id: UUID результата сеанса
    /// - Returns: Результат сеанса или nil
    func fetchSessionResult(byId id: UUID) throws -> SessionResult? {
        let predicate = #Predicate<SessionResult> { session in
            session.id == id
        }
        var descriptor = FetchDescriptor<SessionResult>(predicate: predicate)
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }
    
    /// Обновить результат сеанса
    /// - Parameters:
    ///   - session: Результат сеанса для обновления
    ///   - endAt: Время окончания (опционально)
    ///   - anxietyAfter: Уровень тревоги после сеанса (опционально)
    ///   - notes: Заметки (опционально)
    func updateSessionResult(
        _ session: SessionResult,
        endAt: Date? = nil,
        anxietyAfter: Int? = nil,
        notes: String? = nil
    ) throws {
        if let endAt = endAt {
            session.endAt = endAt
        }
        if let anxietyAfter = anxietyAfter {
            session.anxietyAfter = anxietyAfter
        }
        if let notes = notes {
            session.notes = notes
        }
        
        try saveContext()
    }
    
    /// Завершить сеанс
    /// - Parameters:
    ///   - session: Результат сеанса для завершения
    ///   - anxietyAfter: Уровень тревоги после сеанса
    ///   - notes: Дополнительные заметки (опционально)
    func completeSession(
        _ session: SessionResult,
        anxietyAfter: Int,
        notes: String? = nil
    ) throws {
        session.endAt = Date()
        session.anxietyAfter = anxietyAfter
        if let notes = notes {
            session.notes = notes
        }
        try saveContext()
    }
    
    // MARK: - Step Tracking Operations
    
    /// Отметить шаг как выполненный
    /// - Parameters:
    ///   - session: Результат сеанса
    ///   - stepIndex: Индекс шага
    func markStepCompleted(_ session: SessionResult, stepIndex: Int) throws {
        session.markStepCompleted(stepIndex)
        try saveContext()
    }
    
    /// Отметить шаг как невыполненный
    /// - Parameters:
    ///   - session: Результат сеанса
    ///   - stepIndex: Индекс шага
    func markStepIncomplete(_ session: SessionResult, stepIndex: Int) throws {
        session.markStepIncomplete(stepIndex)
        try saveContext()
    }
    
    /// Сохранить время для шага
    /// - Parameters:
    ///   - session: Результат сеанса
    ///   - stepIndex: Индекс шага
    ///   - time: Затраченное время в секундах
    func setStepTime(_ session: SessionResult, stepIndex: Int, time: TimeInterval) throws {
        session.setStepTime(stepIndex, time: time)
        try saveContext()
    }
    
    /// Обновить прогресс сеанса (выполненные шаги и время)
    /// - Parameters:
    ///   - session: Результат сеанса
    ///   - completedSteps: Массив индексов выполненных шагов
    ///   - stepTimings: Словарь времени по шагам
    func updateSessionProgress(
        _ session: SessionResult,
        completedSteps: [Int],
        stepTimings: [Int: TimeInterval]
    ) throws {
        session.completedStepIndices = completedSteps
        session.stepTimings = stepTimings
        try saveContext()
    }
    
    /// Удалить результат сеанса
    /// - Parameter session: Результат сеанса для удаления
    func deleteSessionResult(_ session: SessionResult) throws {
        modelContext.delete(session)
        try saveContext()
    }
    
    /// Удалить результат сеанса по ID
    /// - Parameter id: UUID результата сеанса
    func deleteSessionResult(byId id: UUID) throws {
        if let session = try fetchSessionResult(byId: id) {
            try deleteSessionResult(session)
        }
    }
    
    /// Удалить несколько результатов сеансов
    /// - Parameter sessions: Массив результатов сеансов для удаления
    func deleteSessionResults(_ sessions: [SessionResult]) throws {
        for session in sessions {
            modelContext.delete(session)
        }
        try saveContext()
    }
    
    // MARK: - Analytics & Statistics
    
    /// Получить статистику по экспозиции
    /// - Parameter exposure: Экспозиция
    /// - Returns: Словарь со статистикой
    func getExposureStatistics(_ exposure: Exposure) throws -> [String: Any] {
        let sessions = try fetchSessionResults(for: exposure)
        let completedSessions = sessions.filter { $0.endAt != nil }
        
        var statistics: [String: Any] = [
            "totalSessions": sessions.count,
            "completedSessions": completedSessions.count
        ]
        
        if !completedSessions.isEmpty {
            let anxietyAfterValues = completedSessions.compactMap { $0.anxietyAfter }
            if !anxietyAfterValues.isEmpty {
                let averageAnxietyAfter = Double(anxietyAfterValues.reduce(0, +)) / Double(anxietyAfterValues.count)
                statistics["averageAnxietyAfter"] = averageAnxietyAfter
                
                let minAnxietyAfter = anxietyAfterValues.min() ?? 0
                let maxAnxietyAfter = anxietyAfterValues.max() ?? 0
                statistics["minAnxietyAfter"] = minAnxietyAfter
                statistics["maxAnxietyAfter"] = maxAnxietyAfter
            }
            
            let durations = completedSessions.compactMap { session -> TimeInterval? in
                guard let endAt = session.endAt else { return nil }
                return endAt.timeIntervalSince(session.startAt)
            }
            
            if !durations.isEmpty {
                let averageDuration = durations.reduce(0, +) / Double(durations.count)
                statistics["averageDurationSeconds"] = averageDuration
            }
        }
        
        return statistics
    }
    
    // MARK: - Batch Operations
    
    /// Удалить все данные (для тестирования)
    func deleteAllData() throws {
        try modelContext.delete(model: Exposure.self)
        try modelContext.delete(model: SessionResult.self)
        try saveContext()
    }
    
    // MARK: - Private Helpers
    
    private func saveContext() throws {
        do {
            try modelContext.save()
        } catch {
            print("Error saving context: \(error)")
            throw DataManagerError.saveFailed(error)
        }
    }
}

// MARK: - Error Handling

enum DataManagerError: LocalizedError {
    case saveFailed(Error)
    case fetchFailed(Error)
    case notFound
    
    var errorDescription: String? {
        switch self {
        case .saveFailed(let error):
            return "Не удалось сохранить данные: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "Не удалось загрузить данные: \(error.localizedDescription)"
        case .notFound:
            return "Данные не найдены"
        }
    }
}

