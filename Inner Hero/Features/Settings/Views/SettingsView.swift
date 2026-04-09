import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    @Binding var path: NavigationPath

    @Environment(\.modelContext) private var modelContext
    @Environment(NotificationManager.self) private var notificationManager

    @State private var isExporting = false
    @State private var exportDocument: ExportJSONDocument?
    @State private var showingExporter = false
    @State private var showingResetConfirmation = false
    @State private var isResetting = false

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: Spacing.lg) {

                    // App card
                    appCard

                    // Preferences
                    settingsSection(title: String(localized: "Preferences")) {
                        navRow(
                            icon: "paintbrush.fill",
                            iconColor: AppColors.accent,
                            title: String(localized: "Appearance"),
                            route: AppRoute.settingsAppearance
                        )
                        rowDivider
                        navRow(
                            icon: "lock.shield.fill",
                            iconColor: AppColors.positive,
                            title: String(localized: "Privacy"),
                            route: AppRoute.settingsPrivacy
                        )
                    }

                    // Data — inline actions, no sub-screen
                    settingsSection(title: String(localized: "Data")) {
                        actionRow(
                            icon: "square.and.arrow.up.fill",
                            iconColor: AppColors.primary,
                            title: String(localized: "Export data"),
                            subtitle: String(localized: "Save as JSON"),
                            isLoading: isExporting
                        ) {
                            Task { await prepareExport() }
                        }
                        rowDivider
                        actionRow(
                            icon: "trash.fill",
                            iconColor: AppColors.State.error,
                            title: String(localized: "Reset all data"),
                            subtitle: String(localized: "Delete everything permanently"),
                            isDestructive: true,
                            isLoading: isResetting
                        ) {
                            showingResetConfirmation = true
                        }
                    }

                    // About — inline, no sub-screen
                    settingsSection(title: String(localized: "About")) {
                        // Version row (non-tappable)
                        infoRow(
                            icon: "info.circle.fill",
                            iconColor: AppColors.gray400,
                            title: String(localized: "Version"),
                            value: "\(appVersion) (\(buildNumber))"
                        )
                        rowDivider
                        // Contact support — opens mail
                        let email = "coder.ekunitsa@gmail.com"
                        if let mailURL = URL(string: "mailto:\(email)") {
                            linkRow(
                                icon: "envelope.fill",
                                iconColor: AppColors.accent,
                                title: String(localized: "Contact support"),
                                subtitle: email,
                                url: mailURL
                            )
                        }
                    }
                }
                .padding(.horizontal, Spacing.sm)
                .padding(.top, Spacing.md)
                .padding(.bottom, Spacing.xxl)
            }
            .homeBackground()
            .navigationTitle(String(localized: "Profile"))
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: AppRoute.self) { route in
                AppRouteView(route: route)
            }
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
    }

    // MARK: - App Card

    private var appCard: some View {
        HStack(spacing: Spacing.sm) {
            RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [AppColors.primary, AppColors.primary.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: IconSize.hero, height: IconSize.hero)
                .overlay {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text("Inner Hero")
                    .appFont(.h3)
                    .foregroundStyle(TextColors.primary)
                Text("v\(appVersion) (\(buildNumber))")
                    .appFont(.small)
                    .foregroundStyle(TextColors.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .cardStyle(cornerRadius: CornerRadius.lg, padding: 0)
    }

    // MARK: - Section builder

    private func settingsSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            SectionLabel(text: title)
            VStack(spacing: 0) {
                content()
            }
            .cardStyle(cornerRadius: CornerRadius.lg, padding: 0)
        }
    }

    private var rowDivider: some View {
        Divider()
            .padding(.leading, Spacing.sm + IconSize.card + Spacing.xs)
    }

    // MARK: - Row types

    /// NavigationLink row — full row is tappable
    private func navRow(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String? = nil,
        route: AppRoute
    ) -> some View {
        NavigationLink(value: route) {
            rowContent(icon: icon, iconColor: iconColor, title: title,
                       subtitle: subtitle, trailing: .chevron)
        }
        .buttonStyle(.plain)
    }

    /// Button row — for actions like export / reset
    private func actionRow(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String? = nil,
        isDestructive: Bool = false,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            rowContent(
                icon: icon,
                iconColor: isDestructive ? AppColors.State.error : iconColor,
                title: title,
                subtitle: subtitle,
                isDestructive: isDestructive,
                trailing: isLoading ? .spinner : .none
            )
        }
        .buttonStyle(.plain)
        .disabled(isLoading || isResetting || isExporting)
    }

    /// Link row — opens URL
    private func linkRow(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String? = nil,
        url: URL
    ) -> some View {
        Link(destination: url) {
            rowContent(icon: icon, iconColor: iconColor, title: title,
                       subtitle: subtitle, trailing: .external)
        }
        .buttonStyle(.plain)
    }

    /// Static info row — not tappable
    private func infoRow(
        icon: String,
        iconColor: Color,
        title: String,
        value: String
    ) -> some View {
        rowContent(icon: icon, iconColor: iconColor, title: title,
                   trailing: .value(value))
    }

    // MARK: - Shared row content

    private enum RowTrailing {
        case chevron
        case external
        case spinner
        case value(String)
        case none
    }

    private func rowContent(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String? = nil,
        isDestructive: Bool = false,
        trailing: RowTrailing = .chevron
    ) -> some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: IconSize.glyph - 1, weight: .medium))
                .foregroundStyle(iconColor)
                .iconContainer(
                    size: IconSize.card,
                    backgroundColor: iconColor.opacity(Opacity.softBackground),
                    cornerRadius: CornerRadius.sm
                )
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .appFont(.bodyMedium)
                    .foregroundStyle(isDestructive ? AppColors.State.error : TextColors.primary)
                if let subtitle {
                    Text(subtitle)
                        .appFont(.small)
                        .foregroundStyle(TextColors.secondary)
                }
            }

            Spacer(minLength: 0)

            switch trailing {
            case .chevron:
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppColors.gray400)
            case .external:
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppColors.gray400)
            case .spinner:
                ProgressView()
                    .scaleEffect(0.8)
            case .value(let text):
                Text(text)
                    .appFont(.small)
                    .foregroundStyle(TextColors.secondary)
                    .monospacedDigit()
            case .none:
                EmptyView()
            }
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }

    // MARK: - Data actions

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
            try deleteAll(ActivationSession.self)
            try deleteAll(ActivationTask.self)
            try deleteAll(ActivationCategory.self)
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

    private func buildExportPayload() throws -> ExportPayload {
        let exposures = try modelContext.fetch(FetchDescriptor<Exposure>())
        let exposureResults = try modelContext.fetch(FetchDescriptor<ExposureSessionResult>())
        let breathingResults = try modelContext.fetch(FetchDescriptor<BreathingSessionResult>())
        let relaxationResults = try modelContext.fetch(FetchDescriptor<RelaxationSessionResult>())
        let groundingResults = try modelContext.fetch(FetchDescriptor<GroundingSessionResult>())
        let activationCategories = try modelContext.fetch(FetchDescriptor<ActivationCategory>())
        let activationTasks = try modelContext.fetch(FetchDescriptor<ActivationTask>())
        let activationSessions = try modelContext.fetch(FetchDescriptor<ActivationSession>())
        let assignments = try modelContext.fetch(FetchDescriptor<ExerciseAssignment>())
        let favorites = try modelContext.fetch(FetchDescriptor<FavoriteExercise>())

        return ExportPayload(
            exportedAt: Date(),
            appVersion: appVersion,
            buildNumber: buildNumber,
            exposures: exposures.map(ExposureDTO.init),
            exposureSessionResults: exposureResults.map(ExposureSessionResultDTO.init),
            breathingSessionResults: breathingResults.map(BreathingSessionResultDTO.init),
            relaxationSessionResults: relaxationResults.map(RelaxationSessionResultDTO.init),
            groundingSessionResults: groundingResults.map(GroundingSessionResultDTO.init),
            activationCategories: activationCategories.map(ActivationCategoryDTO.init),
            activationTasks: activationTasks.map(ActivationTaskDTO.init),
            activationSessions: activationSessions.map(ActivationSessionDTO.init),
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

// MARK: - Export DTOs

private struct ExportPayload: Codable {
    let exportedAt: Date; let appVersion: String?; let buildNumber: String?
    let exposures: [ExposureDTO]; let exposureSessionResults: [ExposureSessionResultDTO]
    let breathingSessionResults: [BreathingSessionResultDTO]
    let relaxationSessionResults: [RelaxationSessionResultDTO]
    let groundingSessionResults: [GroundingSessionResultDTO]
    let activationCategories: [ActivationCategoryDTO]
    let activationTasks: [ActivationTaskDTO]
    let activationSessions: [ActivationSessionDTO]
    let exerciseAssignments: [ExerciseAssignmentDTO]; let favoriteExercises: [FavoriteExerciseDTO]
}
private struct ExposureStepDTO: Codable {
    let text: String; let hasTimer: Bool; let timerDuration: Int; let order: Int
    init(_ s: ExposureStep) { text=s.text; hasTimer=s.hasTimer; timerDuration=s.timerDuration; order=s.order }
}
private struct ExposureDTO: Codable {
    let id: UUID; let title: String; let exposureDescription: String
    let steps: [ExposureStepDTO]; let createdAt: Date; let isPredefined: Bool
    init(_ e: Exposure) { id=e.id; title=e.title; exposureDescription=e.exposureDescription; steps=e.steps.map(ExposureStepDTO.init); createdAt=e.createdAt; isPredefined=e.isPredefined }
}
private struct StepTimingDTO: Codable { let stepIndex: Int; let seconds: Double }
private struct ExposureSessionResultDTO: Codable {
    let id: UUID; let exposureId: UUID?; let startAt: Date; let endAt: Date?
    let anxietyBefore: Int; let anxietyAfter: Int?; let notes: String
    let completedStepIndices: [Int]; let stepTimings: [StepTimingDTO]
    init(_ r: ExposureSessionResult) { id=r.id; exposureId=r.exposure?.id; startAt=r.startAt; endAt=r.endAt; anxietyBefore=r.anxietyBefore; anxietyAfter=r.anxietyAfter; notes=r.notes; completedStepIndices=r.completedStepIndices; stepTimings=r.stepTimings.map{StepTimingDTO(stepIndex:$0.key,seconds:$0.value)} }
}
private struct BreathingSessionResultDTO: Codable {
    let id: UUID; let performedAt: Date; let duration: Double; let patternType: String
    init(_ r: BreathingSessionResult) { id=r.id; performedAt=r.performedAt; duration=r.duration; patternType=r.patternType.rawValue }
}
private struct RelaxationSessionResultDTO: Codable {
    let id: UUID; let performedAt: Date; let duration: Double; let type: String
    init(_ r: RelaxationSessionResult) { id=r.id; performedAt=r.performedAt; duration=r.duration; type=r.type.rawValue }
}
private struct GroundingSessionResultDTO: Codable {
    let id: UUID; let performedAt: Date; let duration: Double; let type: String
    init(_ r: GroundingSessionResult) { id=r.id; performedAt=r.performedAt; duration=r.duration; type=r.type.rawValue }
}
private struct ActivationCategoryDTO: Codable {
    let id: UUID; let predefinedKey: String?; let title: String; let sfSymbol: String
    let colorHex: String; let sortOrder: Int; let isPreset: Bool; let createdAt: Date
    init(_ c: ActivationCategory) { id=c.id; predefinedKey=c.predefinedKey; title=c.title; sfSymbol=c.sfSymbol; colorHex=c.colorHex; sortOrder=c.sortOrder; isPreset=c.isPreset; createdAt=c.createdAt }
}
private struct ActivationTaskDTO: Codable {
    let id: UUID; let categoryId: UUID; let predefinedKey: String?; let title: String
    let hint: String?; let pleasureTag: Bool; let masteryTag: Bool; let effortLevel: String
    let suggestedMinutes: Int?; let sfSymbol: String; let isPreset: Bool
    let isHiddenByUser: Bool; let sortOrder: Int; let createdAt: Date
    init(_ t: ActivationTask) { id=t.id; categoryId=t.categoryId; predefinedKey=t.predefinedKey; title=t.title; hint=t.hint; pleasureTag=t.pleasureTag; masteryTag=t.masteryTag; effortLevel=t.effortLevelRaw; suggestedMinutes=t.suggestedMinutes; sfSymbol=t.sfSymbol; isPreset=t.isPreset; isHiddenByUser=t.isHiddenByUser; sortOrder=t.sortOrder; createdAt=t.createdAt }
}
private struct ActivationSessionDTO: Codable {
    let id: UUID; let activityId: UUID; let assignmentId: UUID?; let statusRaw: String
    let moodBefore: Int?; let moodAfter: Int?; let moodDelta: Int?
    let barrierNote: String?; let reflectionNote: String?
    let plannedFor: Date?; let startedAt: Date?; let completedAt: Date?
    let actualMinutes: Int?; let createdAt: Date
    init(_ s: ActivationSession) { id=s.id; activityId=s.activityId; assignmentId=s.assignmentId; statusRaw=s.statusRaw; moodBefore=s.moodBefore; moodAfter=s.moodAfter; moodDelta=s.moodDelta; barrierNote=s.barrierNote; reflectionNote=s.reflectionNote; plannedFor=s.plannedFor; startedAt=s.startedAt; completedAt=s.completedAt; actualMinutes=s.actualMinutes; createdAt=s.createdAt }
}
private struct ExerciseAssignmentDTO: Codable {
    let id: UUID; let exerciseType: String; let daysOfWeek: [Int]; let time: Date
    let isActive: Bool; let createdAt: Date; let exposureId: UUID?
    let breathingPatternType: String?; let relaxationType: String?
    let groundingType: String?; let activityId: UUID?; let notificationId: String?
    init(_ a: ExerciseAssignment) { id=a.id; exerciseType=a.exerciseType.rawValue; daysOfWeek=a.daysOfWeek; time=a.time; isActive=a.isActive; createdAt=a.createdAt; exposureId=a.exposureId; breathingPatternType=a.breathingPatternType; relaxationType=a.relaxationType; groundingType=a.groundingType; activityId=a.activityId; notificationId=a.notificationId }
}
private struct FavoriteExerciseDTO: Codable {
    let id: UUID; let exerciseType: String; let exerciseId: UUID?; let exerciseIdentifier: String?; let createdAt: Date
    init(_ f: FavoriteExercise) { id=f.id; exerciseType=f.exerciseType.rawValue; exerciseId=f.exerciseId; exerciseIdentifier=f.exerciseIdentifier; createdAt=f.createdAt }
}

// MARK: - Preview

#Preview {
    SettingsView(path: .constant(NavigationPath()))
        .environment(NotificationManager())
        .modelContainer(for: [
            Exposure.self, ExposureStep.self, ExposureSessionResult.self,
            BreathingSessionResult.self, RelaxationSessionResult.self,
            GroundingSessionResult.self, ActivationCategory.self,
            ActivationTask.self, ActivationSession.self, ExerciseAssignment.self,
            FavoriteExercise.self
        ], inMemory: true)
}
