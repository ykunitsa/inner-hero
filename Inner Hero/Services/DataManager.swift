import Foundation
import SwiftData

@Observable
final class DataManager {
    private let modelContext: ModelContext
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Exposure Operations
    
    @discardableResult
    func createExposure(
        title: String,
        description: String,
        steps: [ExposureStep] = []
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
    
    func fetchAllExposures(sortBy sortDescriptors: [SortDescriptor<Exposure>] = []) throws -> [Exposure] {
        let descriptor = FetchDescriptor<Exposure>(sortBy: sortDescriptors)
        return try modelContext.fetch(descriptor)
    }
    
    func deleteExposure(_ exposure: Exposure) throws {
        modelContext.delete(exposure)
        try saveContext()
    }
    
    // MARK: - ExposureSessionResult Operations
    
    @discardableResult
    func createSessionResult(
        for exposure: Exposure,
        anxietyBefore: Int,
        notes: String = ""
    ) throws -> ExposureSessionResult {
        let session = ExposureSessionResult(
            exposure: exposure,
            anxietyBefore: anxietyBefore,
            notes: notes
        )
        
        modelContext.insert(session)
        try saveContext()
        return session
    }
    
    func fetchAllSessionResults(sortBy sortDescriptors: [SortDescriptor<ExposureSessionResult>] = []) throws -> [ExposureSessionResult] {
        let descriptor = FetchDescriptor<ExposureSessionResult>(sortBy: sortDescriptors)
        return try modelContext.fetch(descriptor)
    }
    
    func fetchSessionResults(for exposure: Exposure, sortBy sortDescriptors: [SortDescriptor<ExposureSessionResult>] = []) throws -> [ExposureSessionResult] {
        let defaultSort = [SortDescriptor<ExposureSessionResult>(\.startAt, order: .reverse)]
        let allResults = try fetchAllSessionResults(sortBy: sortDescriptors.isEmpty ? defaultSort : sortDescriptors)
        return allResults.filter { $0.exposure?.id == exposure.id }
    }
    
    func completeSession(
        _ session: ExposureSessionResult,
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
    
    func deleteSessionResult(_ session: ExposureSessionResult) throws {
        modelContext.delete(session)
        try saveContext()
    }
    
    // MARK: - Batch Operations
    
    func deleteAllData() throws {
        try modelContext.delete(model: Exposure.self)
        try modelContext.delete(model: ExposureSessionResult.self)
        try saveContext()
    }
    
    // MARK: - Analytics Operations
    
    func getAverageAnxietyBefore(for exposure: Exposure, in period: TimePeriod) throws -> Double? {
        let sessions = try fetchSessionResults(for: exposure)
        let completedSessions = filterSessionsByPeriod(sessions, period: period)
            .filter { $0.endAt != nil }
        
        guard !completedSessions.isEmpty else { return nil }
        
        let sum = completedSessions.reduce(0) { $0 + $1.anxietyBefore }
        return Double(sum) / Double(completedSessions.count)
    }
    
    func getAverageAnxietyAfter(for exposure: Exposure, in period: TimePeriod) throws -> Double? {
        let sessions = try fetchSessionResults(for: exposure)
        let completedSessions = filterSessionsByPeriod(sessions, period: period)
            .filter { $0.endAt != nil && $0.anxietyAfter != nil }
        
        guard !completedSessions.isEmpty else { return nil }
        
        let sum = completedSessions.compactMap { $0.anxietyAfter }.reduce(0, +)
        return Double(sum) / Double(completedSessions.count)
    }
    
    func getTrendDirection(for exposure: Exposure, in period: TimePeriod) throws -> ChartStatistics.TrendDirection {
        guard let avgBefore = try getAverageAnxietyBefore(for: exposure, in: period),
              let avgAfter = try getAverageAnxietyAfter(for: exposure, in: period) else {
            return .stable
        }
        
        let change = avgAfter - avgBefore
        
        if change < -0.5 {
            return .improving
        } else if change > 0.5 {
            return .worsening
        } else {
            return .stable
        }
    }
    
    private func filterSessionsByPeriod(_ sessions: [ExposureSessionResult], period: TimePeriod) -> [ExposureSessionResult] {
        let cutoffDate = Calendar.current.date(
            byAdding: .day,
            value: -period.daysCount,
            to: Date()
        ) ?? Date()
        
        return sessions.filter { $0.startAt >= cutoffDate }
    }
    
    // MARK: - Private Helpers
    
    private func saveContext() throws {
        try modelContext.save()
    }
}
