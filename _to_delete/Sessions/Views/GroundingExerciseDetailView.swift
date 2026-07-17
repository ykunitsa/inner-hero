import SwiftUI
import SwiftData

struct GroundingExerciseDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scheduleViewModel) private var scheduleViewModel
    @Environment(NotificationManager.self) private var notificationManager

    let exercise: GroundingExercise

    @Query(sort: \ExerciseAssignment.createdAt) private var allAssignments: [ExerciseAssignment]
    @Query(sort: \GroundingSessionResult.performedAt, order: .reverse) private var allSessions: [GroundingSessionResult]
    @Query(sort: \FavoriteExercise.createdAt, order: .reverse) private var favorites: [FavoriteExercise]

    @State private var showScheduleSheet = false

    private var isFavorite: Bool {
        FavoritesService.isFavorite(type: .grounding, exerciseId: nil, identifier: exercise.type.rawValue, in: favorites)
    }

    private var assignments: [ExerciseAssignment] {
        allAssignments.filter {
            $0.exerciseType == .grounding && $0.grounding == exercise.type
        }
    }

    private var sessions: [GroundingSessionResult] {
        allSessions.filter { $0.type == exercise.type }
    }

    private var averageDuration: TimeInterval? {
        guard !sessions.isEmpty else { return nil }
        return sessions.reduce(0) { $0 + $1.duration } / Double(sessions.count)
    }

    private var lastSessionDate: Date? { sessions.first?.performedAt }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                statsRow
                descriptionCard
                stepsCard
                startSessionButton
                sessionsHistoryRow
                ExerciseScheduleSection(
                    assignments: assignments,
                    exerciseType: .grounding,
                    exposureId: nil,
                    groundingType: exercise.type,
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
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar { toolbarContent }
        .sheet(isPresented: $showScheduleSheet) {
            if let viewModel = scheduleViewModel {
                ScheduleExerciseView(
                    assignment: nil,
                    viewModel: viewModel,
                    notificationManager: notificationManager,
                    preSelectedGroundingType: exercise.type
                )
            }
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
            }
        }
    }

    // MARK: - Inline Stats Row

    private var statsRow: some View {
        HStack(spacing: 0) {
            statItem(icon: "chart.bar.fill", value: "\(sessions.count)",
                     label: String(localized: "sessions"), color: AppColors.accent)
            Divider().frame(height: 28)
            statItem(icon: "timer", value: averageDuration.map(formatDuration) ?? "—",
                     label: String(localized: "avg"), color: AppColors.State.warning)
            Divider().frame(height: 28)
            statItem(icon: "list.number", value: "\(exercise.instructionSteps.count)",
                     label: String(localized: "steps"), color: AppColors.accent)
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
            Text(exercise.description)
                .appFont(.body)
                .foregroundStyle(TextColors.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    // MARK: - Instruction Steps

    private var stepsCard: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            SectionLabel(text: String(localized: "Steps"))
            VStack(spacing: Spacing.xxs) {
                ForEach(Array(exercise.instructionSteps.enumerated()), id: \.element.id) { index, step in
                    HStack(alignment: .center, spacing: Spacing.sm) {
                        Text("\(step.number)")
                            .appFont(.bodyMedium)
                            .foregroundStyle(AppColors.accent)
                            .frame(width: 32, height: 32)
                            .background(
                                Circle().fill(AppColors.accent.opacity(Opacity.softBackground))
                            )
                            .accessibilityHidden(true)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(step.title)
                                .appFont(.bodyMedium)
                                .foregroundStyle(TextColors.primary)
                            Text(step.prompt)
                                .appFont(.body)
                                .foregroundStyle(TextColors.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(Spacing.sm)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                            .fill(AppColors.gray100)
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    // MARK: - Start Session

    private var startSessionButton: some View {
        NavigationLink(value: AppRoute.groundingSession(groundingType: exercise.type)) {
            PrimaryButtonLabel(
                title: String(localized: "Start session"),
                systemImage: "play.fill",
                color: AppColors.accent
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Sessions History Row

    private var sessionsHistoryRow: some View {
        NavigationLink(value: AppRoute.sessionHistoryGrounding(groundingType: exercise.type)) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "clock")
                    .font(.system(size: IconSize.glyph, weight: .medium))
                    .foregroundStyle(AppColors.accent)
                    .iconContainer(
                        size: IconSize.card,
                        backgroundColor: AppColors.accent.opacity(Opacity.softBackground),
                        cornerRadius: CornerRadius.sm
                    )
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(String(localized: "Session history"))
                        .appFont(.bodyMedium)
                        .foregroundStyle(TextColors.primary)
                    Text(sessions.isEmpty
                         ? String(localized: "No sessions yet")
                         : "\(sessions.count) sessions\(lastSessionDate.map { " · \($0.formatted(.relative(presentation: .named)))" } ?? "")")
                        .appFont(.small)
                        .foregroundStyle(TextColors.secondary)
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

    // MARK: - Helpers

    private func formatDuration(_ duration: TimeInterval) -> String {
        let totalSeconds = Int(duration.rounded())
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return "\(minutes):\(String(format: "%02d", seconds))"
    }

    private func toggleFavorite() {
        Task {
            do {
                _ = try FavoritesService.toggle(
                    type: .grounding,
                    exerciseId: nil,
                    identifier: exercise.type.rawValue,
                    context: modelContext
                )
                await MainActor.run { HapticFeedback.selection() }
            } catch { HapticFeedback.error() }
        }
    }
}

#Preview {
    NavigationStack {
        GroundingExerciseDetailView(exercise: GroundingExercise.predefinedExercises[0])
    }
    .modelContainer(for: [ExerciseAssignment.self, FavoriteExercise.self, GroundingSessionResult.self], inMemory: true)
}
