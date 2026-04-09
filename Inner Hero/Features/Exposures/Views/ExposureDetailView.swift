import SwiftUI
import SwiftData

// MARK: - ExposureDetailView

struct ExposureDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scheduleViewModel) private var scheduleViewModel
    @Environment(NotificationManager.self) private var notificationManager
    @Environment(\.navigationRouter) private var router
    @Environment(\.currentAppTab) private var currentTab

    let exposure: Exposure
    var onStartSession: (() -> Void)? = nil

    @Query(sort: \ExerciseAssignment.createdAt) private var allAssignments: [ExerciseAssignment]
    @Query(sort: \FavoriteExercise.createdAt, order: .reverse) private var favorites: [FavoriteExercise]

    @State private var showScheduleSheet = false
    @State private var startSessionSheetExposure: Exposure?

    private var isFavorite: Bool {
        FavoritesService.isFavorite(type: .exposure, exerciseId: exposure.id, identifier: nil, in: favorites)
    }

    private var totalSteps: Int { exposure.localizedStepTexts.count }
    private var stepsWithTimer: Int { exposure.steps.filter { $0.hasTimer }.count }
    private var orderedStoredSteps: [ExposureStep] { exposure.steps.sorted { $0.order < $1.order } }

    private var assignments: [ExerciseAssignment] {
        allAssignments.filter {
            $0.exerciseType == .exposure && $0.exposureId == exposure.id
        }
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                statsRow
                descriptionCard
                startSessionButton
                if !exposure.localizedStepTexts.isEmpty {
                    stepsSection
                }
                sessionsHistoryRow
                ExerciseScheduleSection(
                    assignments: assignments,
                    exerciseType: .exposure,
                    exposureId: exposure.id,
                    groundingType: nil,
                    breathingPatternType: nil,
                    relaxationType: nil,
                    activityId: nil
                )
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.xxl)
        }
        .homeBackground()
        .navigationTitle(exposure.localizedTitle)
        .navigationBarTitleDisplayMode(.large)
        .toolbar { toolbarContent }
        .sheet(isPresented: $showScheduleSheet) {
            if let viewModel = scheduleViewModel {
                ScheduleExerciseView(
                    assignment: nil,
                    viewModel: viewModel,
                    notificationManager: notificationManager,
                    preSelectedExposureId: exposure.id
                )
            }
        }
        .sheet(item: $startSessionSheetExposure) { exp in
            StartSessionSheet(exposure: exp) { _ in }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            HStack(spacing: Spacing.xs) {
                Button { toggleFavorite() } label: {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .foregroundStyle(isFavorite ? AppColors.primary : TextColors.secondary)
                }
                .touchTarget()
                .accessibilityLabel(isFavorite
                    ? String(localized: "Remove from favorites")
                    : String(localized: "Add to favorites"))

                Button { showScheduleSheet = true } label: {
                    Image(systemName: "calendar.badge.plus")
                        .foregroundStyle(TextColors.toolbar)
                }
                .touchTarget()
                .accessibilityLabel(String(localized: "Schedule"))

                NavigationLink(value: AppRoute.editExposure(exposureId: exposure.id)) {
                    Image(systemName: "pencil")
                        .foregroundStyle(TextColors.toolbar)
                }
                .touchTarget()
            }
        }
    }

    // MARK: - Inline Stats Row

    private var statsRow: some View {
        HStack(spacing: 0) {
            statItem(
                icon: "list.number",
                value: "\(totalSteps)",
                label: String(localized: "steps"),
                color: AppColors.primary
            )
            Divider().frame(height: 28)
            statItem(
                icon: "timer",
                value: "\(stepsWithTimer)",
                label: String(localized: "timers"),
                color: AppColors.State.warning
            )
            Divider().frame(height: 28)
            statItem(
                icon: "chart.bar.fill",
                value: "\(exposure.sessionResults.count)",
                label: String(localized: "sessions"),
                color: AppColors.primary
            )
        }
        .cardStyle(cornerRadius: CornerRadius.lg, padding: 0)
        .frame(maxWidth: .infinity)
    }

    private func statItem(icon: String, value: String, label: String, color: Color) -> some View {
        HStack(spacing: Spacing.xxs) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(color)
            Text(value)
                .appFont(.bodyMedium)
                .foregroundStyle(TextColors.primary)
                .monospacedDigit()
            Text(label)
                .appFont(.small)
                .foregroundStyle(TextColors.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.sm)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(value) \(label)")
    }

    // MARK: - Description

    private var descriptionCard: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            SectionLabel(text: String(localized: "Description"))
            Text(exposure.localizedDescription)
                .appFont(.body)
                .foregroundStyle(TextColors.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    // MARK: - Start Session

    private var startSessionButton: some View {
        PrimaryButton(
            title: String(localized: "Start session"),
            systemImage: "play.fill",
            color: AppColors.primary
        ) {
            if let onStartSession {
                onStartSession()
            } else {
                startSessionSheetExposure = exposure
            }
        }
    }

    // MARK: - Steps

    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            SectionLabel(text: String(localized: "Steps"))
            VStack(spacing: Spacing.xxs) {
                ForEach(Array(exposure.localizedStepTexts.enumerated()), id: \.offset) { index, stepText in
                    let storedStep = index < orderedStoredSteps.count ? orderedStoredSteps[index] : nil
                    StepDetailCard(
                        stepText: stepText,
                        index: index,
                        hasTimer: storedStep?.hasTimer ?? false,
                        timerDuration: storedStep?.timerDuration ?? 0
                    )
                }
            }
        }
    }

    // MARK: - Session History (single tappable row)

    private var sessionsHistoryRow: some View {
        NavigationLink(value: AppRoute.sessionHistory(exposureId: exposure.id)) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "clock")
                    .font(.system(size: IconSize.glyph, weight: .medium))
                    .foregroundStyle(AppColors.primary)
                    .iconContainer(
                        size: IconSize.card,
                        backgroundColor: AppColors.primary.opacity(Opacity.softBackground),
                        cornerRadius: CornerRadius.sm
                    )
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(String(localized: "Session history"))
                        .appFont(.bodyMedium)
                        .foregroundStyle(TextColors.primary)
                    if exposure.sessionResults.isEmpty {
                        Text(String(localized: "No sessions yet"))
                            .appFont(.small)
                            .foregroundStyle(TextColors.secondary)
                    } else {
                        let last = exposure.sessionResults.sorted { $0.startAt > $1.startAt }.first
                        Text("\(exposure.sessionResults.count) sessions · \(last.map { $0.startAt.formatted(.relative(presentation: .named)) } ?? "")")
                            .appFont(.small)
                            .foregroundStyle(TextColors.secondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppColors.gray400)
            }
            .cardStyle()
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func toggleFavorite() {
        Task {
            do {
                _ = try FavoritesService.toggle(
                    type: .exposure,
                    exerciseId: exposure.id,
                    identifier: nil,
                    context: modelContext
                )
                await MainActor.run { HapticFeedback.selection() }
            } catch {
                HapticFeedback.error()
            }
        }
    }
}

// MARK: - QuickStatCard

struct QuickStatCard: View {
    let icon: String
    let value: String
    let label: String
    var color: Color = AppColors.primary

    var body: some View {
        VStack(spacing: Spacing.xxs) {
            Image(systemName: icon)
                .font(.system(size: IconSize.glyph, weight: .medium))
                .foregroundStyle(color)
            Text(value)
                .appFont(.h3)
                .foregroundStyle(TextColors.primary)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .appFont(.small)
                .foregroundStyle(TextColors.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.sm)
        .cardStyle(cornerRadius: CornerRadius.md, padding: 0)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(value) \(label)")
    }
}

// MARK: - StepDetailCard

struct StepDetailCard: View {
    let stepText: String
    let index: Int
    let hasTimer: Bool
    let timerDuration: Int

    var body: some View {
        HStack(alignment: .center, spacing: Spacing.sm) {
            Text("\(index + 1)")
                .appFont(.bodyMedium)
                .foregroundStyle(AppColors.primary)
                .frame(width: 32, height: 32)
                .background(
                    Circle().fill(AppColors.primary.opacity(Opacity.softBackground))
                )
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(stepText)
                    .appFont(.body)
                    .foregroundStyle(TextColors.primary)
                    .fixedSize(horizontal: false, vertical: true)

                if hasTimer {
                    let minutes = timerDuration / 60
                    let seconds = timerDuration % 60
                    Label(
                        "\(minutes):\(String(format: "%02d", seconds))",
                        systemImage: "timer"
                    )
                    .appFont(.smallMedium)
                    .foregroundStyle(AppColors.State.warning)
                    .padding(.horizontal, Spacing.xxs)
                    .padding(.vertical, Spacing.xxxs)
                    .background(
                        Capsule().fill(AppColors.State.warning.opacity(Opacity.subtleBackground))
                    )
                }
            }
        }
        .padding(Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(cornerRadius: CornerRadius.md, padding: 0)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(format: String(localized: "Step %d: %@"), index + 1, stepText))
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ExposureDetailView(exposure: Exposure(
            title: "Public Speaking",
            exposureDescription: "Facing the fear of speaking in front of others.",
            steps: []
        ))
    }
    .modelContainer(for: [ExerciseAssignment.self, FavoriteExercise.self], inMemory: true)
}
