import SwiftUI
import SwiftData

// MARK: - ActivationDetailView

struct ActivationDetailView: View {
    let activation: ActivityList
    let assignment: ExerciseAssignment?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.scheduleViewModel) private var scheduleViewModel
    @Environment(NotificationManager.self) private var notificationManager

    @State private var showingEditSheet = false
    @State private var showScheduleSheet = false
    @State private var pickedActivity: String? = nil
    @State private var isShuffling = false

    @Query(sort: \ExerciseAssignment.createdAt) private var allAssignments: [ExerciseAssignment]
    @Query(sort: \FavoriteExercise.createdAt, order: .reverse) private var favorites: [FavoriteExercise]

    private var isFavorite: Bool {
        FavoritesService.isFavorite(
            type: .behavioralActivation,
            exerciseId: activation.id,
            identifier: nil,
            in: favorites
        )
    }

    private var scheduleAssignments: [ExerciseAssignment] {
        allAssignments.filter {
            $0.exerciseType == .behavioralActivation && $0.activityListId == activation.id
        }
    }

    init(activation: ActivityList, assignment: ExerciseAssignment? = nil) {
        self.activation = activation
        self.assignment = assignment
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xs) {
                statsRow
                    .padding(.top, Spacing.xxs)

                activitiesSection

                shuffleSection

                ExerciseScheduleSection(
                    assignments: scheduleAssignments,
                    exerciseType: .behavioralActivation,
                    exposureId: nil,
                    groundingType: nil,
                    breathingPatternType: nil,
                    relaxationType: nil,
                    activityListId: activation.id
                )
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.bottom, Spacing.xxl)
        }
        .homeBackground()
        .navigationTitle(activation.localizedTitle)
        .navigationBarTitleDisplayMode(.large)
        .toolbar { toolbarItems }
        .sheet(isPresented: $showingEditSheet) {
            EditActivationView(activation: activation)
        }
        .sheet(isPresented: $showScheduleSheet) {
            if let viewModel = scheduleViewModel {
                ScheduleExerciseView(
                    assignment: nil,
                    viewModel: viewModel,
                    notificationManager: notificationManager,
                    preSelectedActivityListId: activation.id
                )
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            HStack(spacing: Spacing.xxxs) {
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

                if !activation.isPredefined {
                    Button { showingEditSheet = true } label: {
                        Image(systemName: "pencil")
                            .foregroundStyle(TextColors.toolbar)
                    }
                    .touchTarget()
                    .accessibilityLabel(String(localized: "Edit"))
                }
            }
        }
    }

    // MARK: - Stats Row
    //
    // Quick context at a glance — no big hero block needed here.

    private var statsRow: some View {
        HStack(spacing: 0) {
            statCell(
                icon: "list.bullet",
                value: "\(activation.localizedActivities.count)",
                label: String(localized: "Activities"),
                color: AppColors.positive
            )
            Divider().frame(height: 28)
            statCell(
                icon: activation.isPredefined ? "lock.fill" : "person.fill",
                value: activation.isPredefined
                    ? String(localized: "Preset")
                    : String(localized: "My list"),
                label: String(localized: "Type"),
                color: AppColors.positive
            )
        }
        .cardStyle(cornerRadius: CornerRadius.lg, padding: 0)
    }

    private func statCell(icon: String, value: String, label: String, color: Color) -> some View {
        HStack(spacing: Spacing.xxs) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
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
    }

    // MARK: - Activities Section

    private var activitiesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(String(localized: "Activities"))
                .appFont(.h3)
                .foregroundStyle(TextColors.primary)

            if activation.localizedActivities.isEmpty {
                Text(String(localized: "No activities yet"))
                    .appFont(.body)
                    .foregroundStyle(TextColors.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, Spacing.xl)
            } else {
                ActivityGroupCard(activities: activation.localizedActivities)
            }
        }
        .cardStyle()
    }

    // MARK: - Shuffle Section
    //
    // Secondary action — discover a random activity without commitment.
    // Result appears inline below the row; user can start directly from result.

    private var shuffleSection: some View {
        VStack(spacing: Spacing.xxs) {
            shuffleRow

            if let picked = pickedActivity {
                shuffleResult(picked)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(AppAnimation.spring, value: pickedActivity != nil)
    }

    private var shuffleRow: some View {
        Button { shuffle() } label: {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "shuffle")
                    .font(.system(size: IconSize.glyph, weight: .medium))
                    .foregroundStyle(AppColors.positive)
                    .iconContainer(
                        size: IconSize.card,
                        backgroundColor: AppColors.positive.opacity(Opacity.softBackground),
                        cornerRadius: CornerRadius.sm
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text(String(localized: "Pick random activity"))
                        .appFont(.bodyMedium)
                        .foregroundStyle(TextColors.primary)
                    Text(isShuffling
                         ? String(localized: "Picking…")
                         : String(localized: "Tap to get inspired"))
                        .appFont(.small)
                        .foregroundStyle(TextColors.secondary)
                }

                Spacer()

                if isShuffling {
                    ProgressView()
                        .scaleEffect(0.85)
                        .frame(width: IconSize.action, height: IconSize.action)
                } else {
                    Image(systemName: pickedActivity != nil ? "arrow.clockwise" : "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppColors.gray400)
                }
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .cardStyle(padding: 0)
        .disabled(isShuffling || activation.localizedActivities.isEmpty)
    }

    private func shuffleResult(_ activity: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(String(localized: "Your activity"))
                .appFont(.small)
                .foregroundStyle(TextColors.secondary)
            Text(activity)
                .appFont(.bodyMedium)
                .foregroundStyle(TextColors.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                .fill(AppColors.positive.opacity(Opacity.subtleBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                .strokeBorder(
                    AppColors.positive.opacity(Opacity.subtleBorder),
                    lineWidth: 1
                )
        )
    }

    // MARK: - Shuffle Logic

    private func shuffle() {
        let pool = activation.localizedActivities
        guard !pool.isEmpty, !isShuffling else { return }

        isShuffling = true
        pickedActivity = nil
        HapticFeedback.selection()

        // Build a short spin sequence, landing on the real pick
        let final = pool.randomElement()!
        var sequence = (0..<8).map { _ in pool.randomElement()! }
        sequence.append(final)

        var delay: Double = 0
        var interval: Double = 0.06

        for (i, item) in sequence.enumerated() {
            let isFinal = i == sequence.count - 1
            let d = delay

            DispatchQueue.main.asyncAfter(deadline: .now() + d) {
                withAnimation(AppAnimation.fast) {
                    pickedActivity = item
                }
                if isFinal {
                    isShuffling = false
                    HapticFeedback.success()
                }
            }

            delay += interval
            interval = min(interval * 1.25, 0.35)
        }
    }

    // MARK: - Actions

    private func toggleFavorite() {
        Task {
            do {
                _ = try FavoritesService.toggle(
                    type: .behavioralActivation,
                    exerciseId: activation.id,
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

// MARK: - ActivityGroupCard

struct ActivityGroupCard: View {
    let activities: [String]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(activities.indices, id: \.self) { idx in
                HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                    Text("•")
                        .appFont(.smallMedium)
                        .foregroundStyle(AppColors.positive)
                        .accessibilityHidden(true)

                    Text(activities[idx])
                        .appFont(.body)
                        .foregroundStyle(TextColors.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, Spacing.xs)

                if idx != activities.indices.last {
                    Divider()
                        .padding(.leading, Spacing.md) // align with text
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(String(localized: "Activity list"))
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ActivationDetailView(
            activation: ActivityList(
                title: "Morning Routine",
                activities: [
                    "Stretch for 10 minutes",
                    "Healthy breakfast",
                    "10 minutes of journaling",
                    "Walk outside",
                    "Review goals for the day"
                ],
                isPredefined: false
            )
        )
    }
    .modelContainer(for: [ExerciseAssignment.self, FavoriteExercise.self], inMemory: true)
}
