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
    
    func fetchAllExposures(sortBy sortDescriptors: [SortDescriptor<Exposure>] = []) throws -> [Exposure] {
        let descriptor = FetchDescriptor<Exposure>(sortBy: sortDescriptors)
        return try modelContext.fetch(descriptor)
    }
    
    func deleteExposure(_ exposure: Exposure) throws {
        modelContext.delete(exposure)
        try saveContext()
    }
    
    // MARK: - SessionResult Operations
    
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
    
    func fetchAllSessionResults(sortBy sortDescriptors: [SortDescriptor<SessionResult>] = []) throws -> [SessionResult] {
        let descriptor = FetchDescriptor<SessionResult>(sortBy: sortDescriptors)
        return try modelContext.fetch(descriptor)
    }
    
    func fetchSessionResults(for exposure: Exposure, sortBy sortDescriptors: [SortDescriptor<SessionResult>] = []) throws -> [SessionResult] {
        let defaultSort = [SortDescriptor<SessionResult>(\.startAt, order: .reverse)]
        let allResults = try fetchAllSessionResults(sortBy: sortDescriptors.isEmpty ? defaultSort : sortDescriptors)
        return allResults.filter { $0.exposure?.id == exposure.id }
    }
    
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
    
    func deleteSessionResult(_ session: SessionResult) throws {
        modelContext.delete(session)
        try saveContext()
    }
    
    // MARK: - Batch Operations
    
    func deleteAllData() throws {
        try modelContext.delete(model: Exposure.self)
        try modelContext.delete(model: SessionResult.self)
        try saveContext()
    }
    
    // MARK: - Private Helpers
    
    private func saveContext() throws {
        try modelContext.save()
    }
}
