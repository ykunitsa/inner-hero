import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct DataSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    
    @State private var isExporting: Bool = false
    @State private var exportDocument: ExportJSONDocument?
    @State private var showingExporter: Bool = false
    
    @State private var showingResetConfirmation: Bool = false
    @State private var isResetting: Bool = false
    
    var body: some View {
        Form {
            Section {
                Button {
                    Task { await prepareExport() }
                } label: {
                    Label("Экспортировать данные (JSON)", systemImage: "square.and.arrow.up")
                }
                .disabled(isExporting || isResetting)
            } header: {
                Text("Экспорт")
            } footer: {
                Text("Файл содержит упражнения, расписания и результаты сессий.")
            }
            
            Section {
                Button(role: .destructive) {
                    showingResetConfirmation = true
                } label: {
                    Label("Сбросить все данные", systemImage: "trash")
                }
                .disabled(isExporting || isResetting)
            } header: {
                Text("Сброс")
            } footer: {
                Text("Удаляет все данные из приложения. Действие нельзя отменить.")
            }
        }
        .navigationTitle("Данные")
        .navigationBarTitleDisplayMode(.inline)
        .fileExporter(
            isPresented: $showingExporter,
            document: exportDocument,
            contentType: .json,
            defaultFilename: "inner-hero-export-\(dateStamp()).json"
        ) { result in
            switch result {
            case .success:
                break
            case .failure(let error):
                print("Ошибка экспорта файла: \(error)")
            }
        }
        .confirmationDialog(
            "Сбросить все данные?",
            isPresented: $showingResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("Сбросить", role: .destructive) {
                Task { await resetAllData() }
            }
            Button("Отмена", role: .cancel) { }
        } message: {
            Text("Это удалит все упражнения, расписания и результаты сессий.")
        }
        .overlay {
            if isExporting || isResetting {
                ProgressView()
            }
        }
    }
    
    @MainActor
    private func prepareExport() async {
        isExporting = true
        defer { isExporting = false }
        
        do {
            let payload = try buildExportPayload()
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(payload)
            exportDocument = ExportJSONDocument(data: data)
            showingExporter = true
        } catch {
            print("Ошибка подготовки экспорта: \(error)")
        }
    }
    
    @MainActor
    private func resetAllData() async {
        isResetting = true
        defer { isResetting = false }
        
        do {
            await NotificationManager.shared.removeAllNotifications()
            
            try deleteAll(ExposureSessionResult.self)
            try deleteAll(Exposure.self)
            try deleteAll(ExposureStep.self)
            
            try deleteAll(BreathingSessionResult.self)
            try deleteAll(RelaxationSessionResult.self)
            try deleteAll(GroundingSessionResult.self)
            
            try deleteAll(BehavioralActivationSession.self)
            try deleteAll(ActivityList.self)
            
            try deleteAll(ExerciseAssignment.self)
            try deleteAll(FavoriteExercise.self)
            
            try modelContext.save()
        } catch {
            print("Ошибка сброса данных: \(error)")
        }
    }
    
    @MainActor
    private func deleteAll<T: PersistentModel>(_ type: T.Type) throws {
        let items = try modelContext.fetch(FetchDescriptor<T>())
        for item in items {
            modelContext.delete(item)
        }
    }
    
    @MainActor
    private func buildExportPayload() throws -> ExportPayload {
        let exposures = try modelContext.fetch(FetchDescriptor<Exposure>())
        let exposureResults = try modelContext.fetch(FetchDescriptor<ExposureSessionResult>())
        let breathingResults = try modelContext.fetch(FetchDescriptor<BreathingSessionResult>())
        let relaxationResults = try modelContext.fetch(FetchDescriptor<RelaxationSessionResult>())
        let groundingResults = try modelContext.fetch(FetchDescriptor<GroundingSessionResult>())
        let activityLists = try modelContext.fetch(FetchDescriptor<ActivityList>())
        let behavioralSessions = try modelContext.fetch(FetchDescriptor<BehavioralActivationSession>())
        let assignments = try modelContext.fetch(FetchDescriptor<ExerciseAssignment>())
        let favorites = try modelContext.fetch(FetchDescriptor<FavoriteExercise>())
        
        return ExportPayload(
            exportedAt: Date(),
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
            buildNumber: Bundle.main.infoDictionary?["CFBundleVersion"] as? String,
            exposures: exposures.map(ExposureDTO.init),
            exposureSessionResults: exposureResults.map(ExposureSessionResultDTO.init),
            breathingSessionResults: breathingResults.map(BreathingSessionResultDTO.init),
            relaxationSessionResults: relaxationResults.map(RelaxationSessionResultDTO.init),
            groundingSessionResults: groundingResults.map(GroundingSessionResultDTO.init),
            activityLists: activityLists.map(ActivityListDTO.init),
            behavioralActivationSessions: behavioralSessions.map(BehavioralActivationSessionDTO.init),
            exerciseAssignments: assignments.map(ExerciseAssignmentDTO.init),
            favoriteExercises: favorites.map(FavoriteExerciseDTO.init)
        )
    }
    
    private func dateStamp() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}

// MARK: - Export DTOs

private struct ExportPayload: Codable {
    let exportedAt: Date
    let appVersion: String?
    let buildNumber: String?
    
    let exposures: [ExposureDTO]
    let exposureSessionResults: [ExposureSessionResultDTO]
    let breathingSessionResults: [BreathingSessionResultDTO]
    let relaxationSessionResults: [RelaxationSessionResultDTO]
    let groundingSessionResults: [GroundingSessionResultDTO]
    let activityLists: [ActivityListDTO]
    let behavioralActivationSessions: [BehavioralActivationSessionDTO]
    let exerciseAssignments: [ExerciseAssignmentDTO]
    let favoriteExercises: [FavoriteExerciseDTO]
}

private struct ExposureStepDTO: Codable {
    let text: String
    let hasTimer: Bool
    let timerDuration: Int
    let order: Int
    
    init(_ step: ExposureStep) {
        self.text = step.text
        self.hasTimer = step.hasTimer
        self.timerDuration = step.timerDuration
        self.order = step.order
    }
}

private struct ExposureDTO: Codable {
    let id: UUID
    let title: String
    let exposureDescription: String
    let steps: [ExposureStepDTO]
    let createdAt: Date
    let isPredefined: Bool
    
    init(_ exposure: Exposure) {
        self.id = exposure.id
        self.title = exposure.title
        self.exposureDescription = exposure.exposureDescription
        var stepDTOs: [ExposureStepDTO] = []
        stepDTOs.reserveCapacity(exposure.steps.count)
        for step in exposure.steps {
            stepDTOs.append(ExposureStepDTO(step))
        }
        self.steps = stepDTOs
        self.createdAt = exposure.createdAt
        self.isPredefined = exposure.isPredefined
    }
}

private struct StepTimingDTO: Codable {
    let stepIndex: Int
    let seconds: Double
}

private struct ExposureSessionResultDTO: Codable {
    let id: UUID
    let exposureId: UUID?
    let startAt: Date
    let endAt: Date?
    let anxietyBefore: Int
    let anxietyAfter: Int?
    let notes: String
    let completedStepIndices: [Int]
    let stepTimings: [StepTimingDTO]
    
    init(_ result: ExposureSessionResult) {
        self.id = result.id
        self.exposureId = result.exposure?.id
        self.startAt = result.startAt
        self.endAt = result.endAt
        self.anxietyBefore = result.anxietyBefore
        self.anxietyAfter = result.anxietyAfter
        self.notes = result.notes
        self.completedStepIndices = result.completedStepIndices
        self.stepTimings = result.stepTimings.map { StepTimingDTO(stepIndex: $0.key, seconds: $0.value) }
    }
}

private struct BreathingSessionResultDTO: Codable {
    let id: UUID
    let performedAt: Date
    let duration: Double
    let patternType: String
    
    init(_ result: BreathingSessionResult) {
        self.id = result.id
        self.performedAt = result.performedAt
        self.duration = result.duration
        self.patternType = result.patternType.rawValue
    }
}

private struct RelaxationSessionResultDTO: Codable {
    let id: UUID
    let performedAt: Date
    let duration: Double
    let type: String
    
    init(_ result: RelaxationSessionResult) {
        self.id = result.id
        self.performedAt = result.performedAt
        self.duration = result.duration
        self.type = result.type.rawValue
    }
}

private struct GroundingSessionResultDTO: Codable {
    let id: UUID
    let performedAt: Date
    let duration: Double
    let type: String
    
    init(_ result: GroundingSessionResult) {
        self.id = result.id
        self.performedAt = result.performedAt
        self.duration = result.duration
        self.type = result.type.rawValue
    }
}

private struct ActivityListDTO: Codable {
    let id: UUID
    let title: String
    let activities: [String]
    let isPredefined: Bool
    
    init(_ list: ActivityList) {
        self.id = list.id
        self.title = list.title
        self.activities = list.activities
        self.isPredefined = list.isPredefined
    }
}

private struct BehavioralActivationSessionDTO: Codable {
    let id: UUID
    let startedAt: Date
    let completedAt: Date?
    let selectedActivity: String
    let pleasureRating: Int?
    
    init(_ session: BehavioralActivationSession) {
        self.id = session.id
        self.startedAt = session.startedAt
        self.completedAt = session.completedAt
        self.selectedActivity = session.selectedActivity
        self.pleasureRating = session.pleasureRating
    }
}

private struct ExerciseAssignmentDTO: Codable {
    let id: UUID
    let exerciseType: String
    let daysOfWeek: [Int]
    let time: Date
    let isActive: Bool
    let createdAt: Date
    let exposureId: UUID?
    let breathingPatternType: String?
    let relaxationType: String?
    let groundingType: String?
    let activityListId: UUID?
    let notificationId: String?
    
    init(_ assignment: ExerciseAssignment) {
        self.id = assignment.id
        self.exerciseType = assignment.exerciseType.rawValue
        self.daysOfWeek = assignment.daysOfWeek
        self.time = assignment.time
        self.isActive = assignment.isActive
        self.createdAt = assignment.createdAt
        self.exposureId = assignment.exposureId
        self.breathingPatternType = assignment.breathingPatternType
        self.relaxationType = assignment.relaxationType
        self.groundingType = assignment.groundingType
        self.activityListId = assignment.activityListId
        self.notificationId = assignment.notificationId
    }
}

private struct FavoriteExerciseDTO: Codable {
    let id: UUID
    let exerciseType: String
    let exerciseId: UUID?
    let exerciseIdentifier: String?
    let createdAt: Date
    
    init(_ favorite: FavoriteExercise) {
        self.id = favorite.id
        self.exerciseType = favorite.exerciseType.rawValue
        self.exerciseId = favorite.exerciseId
        self.exerciseIdentifier = favorite.exerciseIdentifier
        self.createdAt = favorite.createdAt
    }
}

#Preview {
    NavigationStack {
        DataSettingsView()
    }
    .modelContainer(for: [
        Exposure.self,
        ExposureStep.self,
        ExposureSessionResult.self,
        BreathingSessionResult.self,
        RelaxationSessionResult.self,
        GroundingSessionResult.self,
        ActivityList.self,
        BehavioralActivationSession.self,
        ExerciseAssignment.self,
        FavoriteExercise.self
    ], inMemory: true)
}


