import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct DataSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(NotificationManager.self) private var notificationManager

    @State private var isExporting = false
    @State private var exportDocument: ExportJSONDocument?
    @State private var showingExporter = false
    @State private var showingResetConfirmation = false
    @State private var isResetting = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {

                // Export section
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    SectionLabel(text: String(localized: "Export"))

                    Button {
                        Task { await prepareExport() }
                    } label: {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "square.and.arrow.up.fill")
                                .font(.system(size: IconSize.glyph, weight: .medium))
                                .foregroundStyle(AppColors.primary)
                                .iconContainer(
                                    size: IconSize.card,
                                    backgroundColor: AppColors.primary.opacity(Opacity.softBackground),
                                    cornerRadius: CornerRadius.sm
                                )
                                .accessibilityHidden(true)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(String(localized: "Export data (JSON)"))
                                    .appFont(.bodyMedium)
                                    .foregroundStyle(TextColors.primary)
                                Text(String(localized: "Exercises, schedules, and session results"))
                                    .appFont(.small)
                                    .foregroundStyle(TextColors.secondary)
                            }

                            Spacer()

                            if isExporting {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(AppColors.gray400)
                            }
                        }
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xs)
                        .cardStyle(cornerRadius: CornerRadius.lg, padding: 0)
                    }
                    .buttonStyle(.plain)
                    .disabled(isExporting || isResetting)
                }

                // Reset section
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    SectionLabel(text: String(localized: "Danger zone"))

                    Button {
                        showingResetConfirmation = true
                    } label: {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "trash.fill")
                                .font(.system(size: IconSize.glyph, weight: .medium))
                                .foregroundStyle(AppColors.State.error)
                                .iconContainer(
                                    size: IconSize.card,
                                    backgroundColor: AppColors.State.error.opacity(Opacity.softBackground),
                                    cornerRadius: CornerRadius.sm
                                )
                                .accessibilityHidden(true)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(String(localized: "Reset all data"))
                                    .appFont(.bodyMedium)
                                    .foregroundStyle(AppColors.State.error)
                                Text(String(localized: "Removes all data permanently"))
                                    .appFont(.small)
                                    .foregroundStyle(TextColors.secondary)
                            }

                            Spacer()

                            if isResetting {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xs)
                        .cardStyle(cornerRadius: CornerRadius.lg, padding: 0)
                    }
                    .buttonStyle(.plain)
                    .disabled(isExporting || isResetting)

                    Text(String(localized: "This will delete all exercises, schedules, and session results. This action cannot be undone."))
                        .appFont(.small)
                        .foregroundStyle(TextColors.secondary)
                        .padding(.horizontal, Spacing.xxs)
                }
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.xxl)
        }
        .homeBackground()
        .navigationTitle(String(localized: "Data"))
        .navigationBarTitleDisplayMode(.large)
        .fileExporter(
            isPresented: $showingExporter,
            document: exportDocument,
            contentType: .json,
            defaultFilename: "inner-hero-export-\(dateStamp()).json"
        ) { result in
            if case .failure(let error) = result {
                #if DEBUG
                print("Export error: \(error)")
                #endif
            }
        }
        .confirmationDialog(
            String(localized: "Reset all data?"),
            isPresented: $showingResetConfirmation,
            titleVisibility: .visible
        ) {
            Button(String(localized: "Reset"), role: .destructive) {
                Task { await resetAllData() }
            }
            Button(String(localized: "Cancel"), role: .cancel) { }
        } message: {
            Text(String(localized: "This will delete all exercises, schedules, and session results."))
        }
    }

    // MARK: - Actions (unchanged from original)

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
            #if DEBUG
            print("Export error: \(error)")
            #endif
        }
    }

    @MainActor
    private func resetAllData() async {
        isResetting = true
        defer { isResetting = false }
        do {
            await notificationManager.removeAllNotifications()
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
            #if DEBUG
            print("Reset error: \(error)")
            #endif
        }
    }

    @MainActor
    private func deleteAll<T: PersistentModel>(_ type: T.Type) throws {
        let items = try modelContext.fetch(FetchDescriptor<T>())
        for item in items { modelContext.delete(item) }
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
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }
}

// MARK: - Export DTOs (unchanged)

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
    let text: String; let hasTimer: Bool; let timerDuration: Int; let order: Int
    init(_ s: ExposureStep) { text = s.text; hasTimer = s.hasTimer; timerDuration = s.timerDuration; order = s.order }
}
private struct ExposureDTO: Codable {
    let id: UUID; let title: String; let exposureDescription: String
    let steps: [ExposureStepDTO]; let createdAt: Date; let isPredefined: Bool
    init(_ e: Exposure) {
        id = e.id; title = e.title; exposureDescription = e.exposureDescription
        steps = e.steps.map(ExposureStepDTO.init); createdAt = e.createdAt; isPredefined = e.isPredefined
    }
}
private struct StepTimingDTO: Codable { let stepIndex: Int; let seconds: Double }
private struct ExposureSessionResultDTO: Codable {
    let id: UUID; let exposureId: UUID?; let startAt: Date; let endAt: Date?
    let anxietyBefore: Int; let anxietyAfter: Int?; let notes: String
    let completedStepIndices: [Int]; let stepTimings: [StepTimingDTO]
    init(_ r: ExposureSessionResult) {
        id = r.id; exposureId = r.exposure?.id; startAt = r.startAt; endAt = r.endAt
        anxietyBefore = r.anxietyBefore; anxietyAfter = r.anxietyAfter; notes = r.notes
        completedStepIndices = r.completedStepIndices
        stepTimings = r.stepTimings.map { StepTimingDTO(stepIndex: $0.key, seconds: $0.value) }
    }
}
private struct BreathingSessionResultDTO: Codable {
    let id: UUID; let performedAt: Date; let duration: Double; let patternType: String
    init(_ r: BreathingSessionResult) { id = r.id; performedAt = r.performedAt; duration = r.duration; patternType = r.patternType.rawValue }
}
private struct RelaxationSessionResultDTO: Codable {
    let id: UUID; let performedAt: Date; let duration: Double; let type: String
    init(_ r: RelaxationSessionResult) { id = r.id; performedAt = r.performedAt; duration = r.duration; type = r.type.rawValue }
}
private struct GroundingSessionResultDTO: Codable {
    let id: UUID; let performedAt: Date; let duration: Double; let type: String
    init(_ r: GroundingSessionResult) { id = r.id; performedAt = r.performedAt; duration = r.duration; type = r.type.rawValue }
}
private struct ActivityListDTO: Codable {
    let id: UUID; let title: String; let activities: [String]; let isPredefined: Bool
    init(_ l: ActivityList) { id = l.id; title = l.title; activities = l.activities; isPredefined = l.isPredefined }
}
private struct BehavioralActivationSessionDTO: Codable {
    let id: UUID; let startedAt: Date; let completedAt: Date?
    let selectedActivity: String; let pleasureRating: Int?
    init(_ s: BehavioralActivationSession) {
        id = s.id; startedAt = s.startedAt; completedAt = s.completedAt
        selectedActivity = s.selectedActivity; pleasureRating = s.pleasureRating
    }
}
private struct ExerciseAssignmentDTO: Codable {
    let id: UUID; let exerciseType: String; let daysOfWeek: [Int]; let time: Date
    let isActive: Bool; let createdAt: Date; let exposureId: UUID?
    let breathingPatternType: String?; let relaxationType: String?
    let groundingType: String?; let activityListId: UUID?; let notificationId: String?
    init(_ a: ExerciseAssignment) {
        id = a.id; exerciseType = a.exerciseType.rawValue; daysOfWeek = a.daysOfWeek
        time = a.time; isActive = a.isActive; createdAt = a.createdAt
        exposureId = a.exposureId; breathingPatternType = a.breathingPatternType
        relaxationType = a.relaxationType; groundingType = a.groundingType
        activityListId = a.activityListId; notificationId = a.notificationId
    }
}
private struct FavoriteExerciseDTO: Codable {
    let id: UUID; let exerciseType: String; let exerciseId: UUID?
    let exerciseIdentifier: String?; let createdAt: Date
    init(_ f: FavoriteExercise) {
        id = f.id; exerciseType = f.exerciseType.rawValue; exerciseId = f.exerciseId
        exerciseIdentifier = f.exerciseIdentifier; createdAt = f.createdAt
    }
}

#Preview {
    NavigationStack {
        DataSettingsView()
            .environment(NotificationManager())
    }
    .modelContainer(for: [
        Exposure.self, ExposureStep.self, ExposureSessionResult.self,
        BreathingSessionResult.self, RelaxationSessionResult.self,
        GroundingSessionResult.self, ActivityList.self,
        BehavioralActivationSession.self, ExerciseAssignment.self,
        FavoriteExercise.self
    ], inMemory: true)
}
