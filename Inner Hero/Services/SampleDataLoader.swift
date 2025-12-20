import Foundation
import SwiftData

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
    
    static func loadSampleExposures(
        into modelContext: ModelContext,
        from fileName: String = "SampleData"
    ) throws {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json") else {
            throw SampleDataError.fileNotFound
        }
        
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let sampleData = try decoder.decode(SampleData.self, from: data)
        
        for exposureData in sampleData.exposures {
            let steps = exposureData.steps.enumerated().map { index, text in
                ExposureStep(text: text, hasTimer: false, timerDuration: 0, order: index)
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
    
    static func loadSampleSessions(
        for exposures: [Exposure],
        into modelContext: ModelContext
    ) throws {
        let calendar = Calendar.current
        let now = Date()
        
        for exposure in exposures {
            let sessionCount = Int.random(in: 3...5)
            
            for i in 0..<sessionCount {
                let daysAgo = Double(sessionCount - i) * 2.0
                guard let startDate = calendar.date(byAdding: .day, value: -Int(daysAgo), to: now) else {
                    continue
                }
                
                let anxietyBefore = Int.random(in: 6...10)
                let anxietyAfter = max(1, anxietyBefore - Int.random(in: 2...4))
                
                let duration = TimeInterval(Int.random(in: 10...30) * 60)
                let endDate = startDate.addingTimeInterval(duration)
                
                let notes = [
                    "Сначала было тяжело, но постепенно стало легче",
                    "Использовал дыхательные техники",
                    "Удалось справиться с тревогой",
                    "Было проще, чем ожидал",
                    "Потребовалось больше времени, чем планировал"
                ].randomElement() ?? ""
                
                let session = ExposureSessionResult(
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
