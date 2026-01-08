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
        let sampleData = try loadSampleData(from: fileName)
        
        for exposureData in sampleData.exposures {
            let steps = exposureData.steps.enumerated().map { index, text in
                ExposureStep(text: text, hasTimer: false, timerDuration: 0, order: index)
            }
            
            let exposure = Exposure(
                title: exposureData.title,
                exposureDescription: exposureData.description,
                steps: steps,
                isPredefined: true
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
                title: "Утренняя рутина",
                activities: [
                    "Разминка 20–30 минут",
                    "Принять душ",
                    "Полезный завтрак",
                    "Просмотреть цели на день",
                    "Медитация 10 минут"
                ]
            ),
            (
                title: "Забота о себе",
                activities: [
                    "Принять расслабляющую ванну",
                    "Почитать для удовольствия",
                    "Послушать любимую музыку",
                    "Заняться хобби",
                    "Позвонить другу или близкому",
                    "Прогулка на природе"
                ]
            ),
            (
                title: "Социальные контакты",
                activities: [
                    "Встретиться с другом за кофе",
                    "Посетить мероприятие",
                    "Присоединиться к клубу или группе",
                    "Волонтёрство",
                    "Написать/позвонить новому знакомому",
                    "Провести время с семьёй"
                ]
            ),
            (
                title: "Полезные дела",
                activities: [
                    "Завершить рабочую задачу",
                    "Навести порядок дома",
                    "Изучить что-то новое",
                    "Продвинуть личный проект",
                    "Спланировать неделю",
                    "Сделать накопившиеся дела"
                ]
            ),
            (
                title: "Физическая активность",
                activities: [
                    "Пробежка или бег трусцой",
                    "Йога или растяжка",
                    "Тренировка в зале",
                    "Поиграть в спорт",
                    "Поплавать",
                    "Танцевальная тренировка",
                    "Поход/пешая прогулка"
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

    /// Updates previously inserted predefined activation lists that were created in English.
    /// Safe to call repeatedly; it only updates lists that match known old titles.
    static func backfillPredefinedActivationListsIfNeeded(into modelContext: ModelContext) throws {
        let oldTitleToNew: [String: (title: String, activities: [String])] = [
            "Morning Routine": (
                title: "Утренняя рутина",
                activities: [
                    "Разминка 20–30 минут",
                    "Принять душ",
                    "Полезный завтрак",
                    "Просмотреть цели на день",
                    "Медитация 10 минут"
                ]
            ),
            "Self-Care Activities": (
                title: "Забота о себе",
                activities: [
                    "Принять расслабляющую ванну",
                    "Почитать для удовольствия",
                    "Послушать любимую музыку",
                    "Заняться хобби",
                    "Позвонить другу или близкому",
                    "Прогулка на природе"
                ]
            ),
            "Social Connections": (
                title: "Социальные контакты",
                activities: [
                    "Встретиться с другом за кофе",
                    "Посетить мероприятие",
                    "Присоединиться к клубу или группе",
                    "Волонтёрство",
                    "Написать/позвонить новому знакомому",
                    "Провести время с семьёй"
                ]
            ),
            "Productive Tasks": (
                title: "Полезные дела",
                activities: [
                    "Завершить рабочую задачу",
                    "Навести порядок дома",
                    "Изучить что-то новое",
                    "Продвинуть личный проект",
                    "Спланировать неделю",
                    "Сделать накопившиеся дела"
                ]
            ),
            "Physical Activities": (
                title: "Физическая активность",
                activities: [
                    "Пробежка или бег трусцой",
                    "Йога или растяжка",
                    "Тренировка в зале",
                    "Поиграть в спорт",
                    "Поплавать",
                    "Танцевальная тренировка",
                    "Поход/пешая прогулка"
                ]
            )
        ]
        
        let lists = try modelContext.fetch(FetchDescriptor<ActivityList>())
        var didUpdate = false
        
        for list in lists where list.isPredefined {
            guard let replacement = oldTitleToNew[list.title] else { continue }
            list.title = replacement.title
            list.activities = replacement.activities
            didUpdate = true
        }
        
        if didUpdate {
            try modelContext.save()
        }
    }
    
    // MARK: - Predefined Exposure Helpers
    
    static func exposureKey(title: String, description: String) -> String {
        "\(title)|\(description)"
    }
    
    static func sampleExposureKeys(from fileName: String = "SampleData") throws -> Set<String> {
        let sampleData = try loadSampleData(from: fileName)
        return Set(sampleData.exposures.map { exposureKey(title: $0.title, description: $0.description) })
    }
    
    private static func loadSampleData(from fileName: String) throws -> SampleData {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json") else {
            throw SampleDataError.fileNotFound
        }
        
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        return try decoder.decode(SampleData.self, from: data)
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
