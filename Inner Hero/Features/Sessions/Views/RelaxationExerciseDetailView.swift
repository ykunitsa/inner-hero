import SwiftUI
import SwiftData

struct RelaxationExerciseDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scheduleViewModel) private var scheduleViewModel
    @Environment(NotificationManager.self) private var notificationManager

    let exercise: RelaxationExercise

    @Query(sort: \ExerciseAssignment.createdAt) private var allAssignments: [ExerciseAssignment]
    @Query(sort: \RelaxationSessionResult.performedAt, order: .reverse) private var allSessions: [RelaxationSessionResult]
    @Query(sort: \FavoriteExercise.createdAt, order: .reverse) private var favorites: [FavoriteExercise]

    @State private var showScheduleSheet = false

    private var isFavorite: Bool {
        FavoritesService.isFavorite(type: .relaxation, exerciseId: nil, identifier: exercise.type.rawValue, in: favorites)
    }

    private var assignments: [ExerciseAssignment] {
        allAssignments.filter {
            $0.exerciseType == .relaxation && $0.relaxation == exercise.type
        }
    }

    private var sessions: [RelaxationSessionResult] {
        allSessions.filter { $0.type == exercise.type }
    }

    private var lastSessionDate: Date? { sessions.first?.performedAt }

    private var averageDuration: TimeInterval? {
        guard !sessions.isEmpty else { return nil }
        return sessions.reduce(0) { $0 + $1.duration } / Double(sessions.count)
    }

    private var steps: [MuscleGroup] { MuscleGroup.groups(for: exercise.type) }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                statsRow
                purposeCard
                howToCard
                startSessionButton
                stepsSection
                ExerciseScheduleSection(
                    assignments: assignments,
                    exerciseType: .relaxation,
                    exposureId: nil,
                    groundingType: nil,
                    breathingPatternType: nil,
                    relaxationType: exercise.type,
                    activityListId: nil
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
                    preSelectedRelaxationType: exercise.type
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
                     label: String(localized: "sessions"), color: AppColors.positive)
            Divider().frame(height: 28)
            statItem(icon: "timer", value: averageDuration.map(formatDuration) ?? "—",
                     label: String(localized: "avg"), color: AppColors.State.warning)
            Divider().frame(height: 28)
            statItem(icon: "figure.mind.and.body", value: "\(steps.count)",
                     label: String(localized: "groups"), color: AppColors.positive)
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

    // MARK: - Info Cards

    private var purposeCard: some View {
        infoSection(
            label: String(localized: "What it's for"),
            icon: "target",
            color: AppColors.positive,
            text: String(localized: "Progressive muscle relaxation helps reduce anxiety and body tension through mindful tensing and releasing. You learn to notice where stress builds up in your body and gently release it.")
        )
    }

    private var howToCard: some View {
        infoSection(
            label: String(localized: "How to do it"),
            icon: "list.bullet.rectangle",
            color: AppColors.positive,
            text: String(localized: "Get comfortable. On \"Tense\" phases, tense the muscle group moderately (no pain) and hold. On \"Release\" phases, fully let go and notice the sensations. Breathe steadily.\n\nTip: if tensing is difficult, ease off or skip that step — staying comfortable matters.")
        )
    }

    private func infoSection(label: String, icon: String, color: Color, text: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            HStack(spacing: Spacing.xxs) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(color)
                SectionLabel(text: label)
            }
            Text(text)
                .appFont(.body)
                .foregroundStyle(TextColors.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    // MARK: - Start Session

    private var startSessionButton: some View {
        NavigationLink(value: AppRoute.relaxationSession(relaxationType: exercise.type)) {
            PrimaryButtonLabel(
                title: String(localized: "Start session"),
                systemImage: "play.fill",
                color: AppColors.positive
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Muscle Group Steps

    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            SectionLabel(text: String(localized: "Steps"))
            VStack(spacing: Spacing.xxs) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    muscleGroupCard(step: step, index: index)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func muscleGroupCard(step: MuscleGroup, index: Int) -> some View {
        let isTension = step.phase == .tension
        let phaseColor: Color = isTension ? AppColors.State.warning : AppColors.positive

        return HStack(alignment: .top, spacing: Spacing.sm) {
            Text("\(index + 1)")
                .appFont(.bodyMedium)
                .foregroundStyle(phaseColor)
                .frame(width: 32, height: 32)
                .background(
                    Circle().fill(phaseColor.opacity(Opacity.softBackground))
                )
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Spacing.xxxs) {
                HStack(spacing: Spacing.xxs) {
                    Text(step.name)
                        .appFont(.bodyMedium)
                        .foregroundStyle(TextColors.primary)
                    Text("·")
                        .appFont(.body)
                        .foregroundStyle(TextColors.tertiary)
                    Text(isTension
                         ? String(localized: "Tense")
                         : String(localized: "Relax"))
                        .appFont(.smallMedium)
                        .foregroundStyle(phaseColor)
                }
                Text(step.instruction)
                    .appFont(.body)
                    .foregroundStyle(TextColors.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Label(
                    String(format: String(localized: "%d s"), Int(step.duration)),
                    systemImage: "timer"
                )
                .appFont(.small)
                .foregroundStyle(TextColors.tertiary)
            }
        }
        .padding(Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                .fill(AppColors.gray100)
        )
    }

    // MARK: - Helpers

    private func formatDuration(_ duration: TimeInterval) -> String {
        let totalSeconds = Int(duration.rounded())
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        if minutes == 0 { return String(format: String(localized: "%d s"), seconds) }
        return "\(minutes):\(String(format: "%02d", seconds))"
    }

    private func toggleFavorite() {
        Task {
            do {
                _ = try FavoritesService.toggle(
                    type: .relaxation,
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
        RelaxationExerciseDetailView(exercise: RelaxationExercise.predefinedExercises[0])
    }
    .modelContainer(for: [ExerciseAssignment.self, RelaxationSessionResult.self, FavoriteExercise.self], inMemory: true)
}
