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
    
    static func loadPredefinedActivationLists(into modelContext: ModelContext) throws {
        let predefinedLists: [(title: String, activities: [String])] = [
            (
                title: "Morning Routine",
                activities: [
                    "Exercise for 20-30 minutes",
                    "Take a shower",
                    "Eat a healthy breakfast",
                    "Review daily goals",
                    "Meditate for 10 minutes"
                ]
            ),
            (
                title: "Self-Care Activities",
                activities: [
                    "Take a relaxing bath",
                    "Read a book for pleasure",
                    "Listen to favorite music",
                    "Practice a hobby",
                    "Call a friend or family member",
                    "Go for a walk in nature"
                ]
            ),
            (
                title: "Social Connections",
                activities: [
                    "Meet a friend for coffee",
                    "Attend a social event",
                    "Join a club or group",
                    "Volunteer in community",
                    "Reach out to someone new",
                    "Spend time with family"
                ]
            ),
            (
                title: "Productive Tasks",
                activities: [
                    "Complete a work task",
                    "Organize living space",
                    "Learn something new",
                    "Work on a personal project",
                    "Plan the week ahead",
                    "Handle pending errands"
                ]
            ),
            (
                title: "Physical Activities",
                activities: [
                    "Go for a run or jog",
                    "Try yoga or stretching",
                    "Go to the gym",
                    "Play a sport",
                    "Go swimming",
                    "Take a dance class",
                    "Go hiking"
                ]
            )
        ]
        
        for list in predefinedLists {
            let activationList = ActivityList(
                title: list.title,
                activities: list.activities,
                isPredefined: true
            )
            modelContext.insert(activationList)
        }
        
        try modelContext.save()
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
