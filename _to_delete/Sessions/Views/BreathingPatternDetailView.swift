import SwiftUI
import SwiftData

struct BreathingPatternDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scheduleViewModel) private var scheduleViewModel
    @Environment(NotificationManager.self) private var notificationManager

    let pattern: BreathingPattern

    @Query(sort: \ExerciseAssignment.createdAt) private var allAssignments: [ExerciseAssignment]
    @Query(sort: \BreathingSessionResult.performedAt, order: .reverse) private var allSessions: [BreathingSessionResult]
    @Query(sort: \FavoriteExercise.createdAt, order: .reverse) private var favorites: [FavoriteExercise]

    @State private var showScheduleSheet = false

    private var isFavorite: Bool {
        FavoritesService.isFavorite(type: .breathing, exerciseId: nil, identifier: pattern.type.rawValue, in: favorites)
    }

    private var assignments: [ExerciseAssignment] {
        allAssignments.filter {
            $0.exerciseType == .breathing && $0.breathingPattern == pattern.type
        }
    }

    private var sessions: [BreathingSessionResult] {
        allSessions.filter { $0.patternType == pattern.type }
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
                startSessionButton
                sessionsHistoryRow
                ExerciseScheduleSection(
                    assignments: assignments,
                    exerciseType: .breathing,
                    exposureId: nil,
                    groundingType: nil,
                    breathingPatternType: pattern.type,
                    relaxationType: nil,
                    activityId: nil
                )
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.xxl)
        }
        .homeBackground()
        .navigationTitle(pattern.localizedName)
        .navigationBarTitleDisplayMode(.large)
        .toolbar { toolbarContent }
        .sheet(isPresented: $showScheduleSheet) {
            if let viewModel = scheduleViewModel {
                ScheduleExerciseView(
                    assignment: nil,
                    viewModel: viewModel,
                    notificationManager: notificationManager,
                    preSelectedBreathingPattern: pattern.type
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
            statItem(icon: "clock", value: lastSessionDate.map { $0.formatted(.relative(presentation: .named)) } ?? "—",
                     label: String(localized: "last"), color: AppColors.positive)
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
            Text(pattern.localizedDescription)
                .appFont(.body)
                .foregroundStyle(TextColors.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    // MARK: - Start Session

    private var startSessionButton: some View {
        NavigationLink(value: AppRoute.breathingSession(patternType: pattern.type)) {
            PrimaryButtonLabel(
                title: String(localized: "Start session"),
                systemImage: "play.fill",
                color: AppColors.positive
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Sessions History Row

    private var sessionsHistoryRow: some View {
        NavigationLink(value: AppRoute.sessionHistoryBreathing(patternType: pattern.type)) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "clock")
                    .font(.system(size: IconSize.glyph, weight: .medium))
                    .foregroundStyle(AppColors.positive)
                    .iconContainer(
                        size: IconSize.card,
                        backgroundColor: AppColors.positive.opacity(Opacity.softBackground),
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
        if minutes == 0 { return String(format: String(localized: "%d s"), seconds) }
        return "\(minutes):\(String(format: "%02d", seconds))"
    }

    private func toggleFavorite() {
        Task {
            do {
                _ = try FavoritesService.toggle(
                    type: .breathing,
                    exerciseId: nil,
                    identifier: pattern.type.rawValue,
                    context: modelContext
                )
                await MainActor.run { HapticFeedback.selection() }
            } catch { HapticFeedback.error() }
        }
    }
}

// MARK: - BreathingPatternType + rhythm label (reused from list view)

private extension BreathingPatternType {
    var rhythmLabel: String {
        switch self {
        case .box:     return "4 · 4 · 4 · 4"
        case .fourSix: return "4 · 6"
        case .paced:   return "5 · 1 · 5 · 1"
        }
    }
}

#Preview {
    NavigationStack {
        BreathingPatternDetailView(pattern: BreathingPattern.predefinedPatterns[0])
    }
    .modelContainer(for: [ExerciseAssignment.self, BreathingSessionResult.self, FavoriteExercise.self], inMemory: true)
}
