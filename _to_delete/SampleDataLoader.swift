import Foundation
import SwiftData

struct SampleDataLoader {
    static func loadPredefinedExposures(into modelContext: ModelContext) throws {
        for exposureData in PredefinedExposures.all {
            let steps = exposureData.steps.enumerated().map { index, text in
                ExposureStep(text: text, hasTimer: false, timerDuration: 0, order: index)
            }

            let exposure = Exposure(
                title: exposureData.title,
                exposureDescription: exposureData.description,
                predefinedKey: exposureData.key.rawValue,
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
        let sampleNotes = [
            String(localized: "sample.session.note1"),
            String(localized: "sample.session.note2"),
            String(localized: "sample.session.note3"),
            String(localized: "sample.session.note4"),
            String(localized: "sample.session.note5")
        ]
        
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
                
                let notes = sampleNotes.randomElement() ?? ""
                
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

    static func loadPresetActivationData(into modelContext: ModelContext) throws {
        let existingCategories = try modelContext.fetch(FetchDescriptor<ActivationCategory>())
        guard existingCategories.isEmpty else { return }

        for category in PresetActivationData.categories {
            modelContext.insert(category)
        }
        for task in PresetActivationData.tasks {
            modelContext.insert(task)
        }
        try modelContext.save()
    }
}
