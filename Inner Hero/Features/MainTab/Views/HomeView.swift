import SwiftUI
import SwiftData

struct HomeView: View {
    @Binding var path: NavigationPath

    @Environment(\.modelContext) private var modelContext
    @Environment(ArticlesStore.self) private var articlesStore
    @State private var viewModel = HomeViewModel()
    @State private var appeared = false

    @Query(sort: \ExerciseAssignment.time) private var allAssignments: [ExerciseAssignment]
    @Query(sort: \ExerciseCompletion.createdAt, order: .reverse) private var allCompletions: [ExerciseCompletion]
    @Query(sort: \Exposure.title) private var exposures: [Exposure]
    @Query(sort: \ActivityList.title) private var activityLists: [ActivityList]
    @Query(sort: \FavoriteExercise.createdAt, order: .reverse) private var favorites: [FavoriteExercise]
    @Query(sort: \BreathingSessionResult.performedAt, order: .reverse) private var breathingSessions: [BreathingSessionResult]
    @Query(sort: \GroundingSessionResult.performedAt, order: .reverse) private var groundingSessions: [GroundingSessionResult]
    @Query(sort: \RelaxationSessionResult.performedAt, order: .reverse) private var relaxationSessions: [RelaxationSessionResult]
    @Query(sort: \ExposureSessionResult.startAt, order: .reverse) private var exposureSessions: [ExposureSessionResult]
    @Query(sort: \BehavioralActivationSession.startedAt, order: .reverse) private var activationSessions: [BehavioralActivationSession]

    // MARK: - Computed

    private var featuredArticle: Article? { articlesStore.featuredArticles.first }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:  return String(localized: "Good morning")
        case 12..<17: return String(localized: "Good afternoon")
        case 17..<22: return String(localized: "Good evening")
        default:      return String(localized: "Good night")
        }
    }

    /// Resolved quick access items — favorites if any, otherwise 3 sensible defaults
    private var quickAccessItems: [QuickAccessItem] {
        let resolved = viewModel.quickStartFavorites.compactMap { resolveItem($0) }
        guard resolved.isEmpty else { return resolved }
        return QuickAccessItem.defaults
    }

    // MARK: - Body

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.sm) {

                    // Today plan hero card
                    todayHeroCard
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 12)
                        .animation(AppAnimation.appear.delay(0.05), value: appeared)

                    // Streak + Minutes compact row
                    statsRow
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 12)
                        .animation(AppAnimation.appear.delay(0.10), value: appeared)

                    // Quick access
                    quickAccessSection
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 12)
                        .animation(AppAnimation.appear.delay(0.15), value: appeared)

                    // Article of the day
                    if let article = featuredArticle {
                        articleRow(article: article)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 12)
                            .animation(AppAnimation.appear.delay(0.20), value: appeared)
                    }
                }
                .padding(.horizontal, Spacing.sm)
                .padding(.top, Spacing.xxs)
                .padding(.bottom, Spacing.xxl)
            }
            .homeBackground()
            .navigationTitle(greeting)
            .navigationBarTitleDisplayMode(.large)
            .onAppear { appeared = true }
            .task { refreshViewModel() }
            .onChange(of: refreshTrigger) { refreshViewModel() }
            .navigationDestination(for: AppRoute.self) { route in
                AppRouteView(route: route)
            }
        }
    }

    // MARK: - Today Hero Card

    @ViewBuilder
    private var todayHeroCard: some View {
        if viewModel.plannedTodayCount == 0 {
            // Neutral hint — no big red card when there's nothing scheduled
            noScheduleHint
        } else {
            heroCard
        }
    }

    private var noScheduleHint: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: IconSize.glyph, weight: .medium))
                .foregroundStyle(AppColors.gray400)
                .iconContainer(
                    size: IconSize.card,
                    backgroundColor: AppColors.gray200,
                    cornerRadius: CornerRadius.sm
                )
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(String(localized: "No exercises scheduled"))
                    .appFont(.bodyMedium)
                    .foregroundStyle(TextColors.primary)
                Text(String(localized: "Set up a schedule to track your progress"))
                    .appFont(.small)
                    .foregroundStyle(TextColors.secondary)
            }

            Spacer(minLength: 0)

            NavigationLink(value: AppRoute.exerciseSchedule) {
                Text(String(localized: "Set up"))
                    .appFont(.smallMedium)
                    .foregroundStyle(AppColors.primary)
                    .padding(.horizontal, Spacing.xs)
                    .padding(.vertical, Spacing.xxxs + 2)
                    .background(
                        Capsule().fill(AppColors.primary.opacity(Opacity.subtleBackground))
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .cardStyle(cornerRadius: CornerRadius.lg, padding: 0)
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Header row
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xxxs) {
                    Text(String(localized: "Today's plan"))
                        .appFont(.small)
                        .foregroundStyle(TextColors.onColorSecondary)

                    Text(String(
                        format: String(localized: "Completed %1$d of %2$d"),
                        viewModel.doneTodayCount,
                        viewModel.plannedTodayCount
                    ))
                    .appFont(.h2)
                    .foregroundStyle(TextColors.onColor)
                    .monospacedDigit()
                }

                Spacer()

                ProgressRingView(
                    progress: Double(viewModel.doneTodayCount) / Double(viewModel.plannedTodayCount),
                    lineWidth: 6,
                    tint: .white.opacity(0.9)
                )
                .frame(width: 44, height: 44)
                .accessibilityHidden(true)
            }

            if let next = viewModel.nextPlanned {
                // Next exercise info
                HStack(spacing: Spacing.xxs) {
                    Image(systemName: "clock")
                        .font(.system(size: 12))
                        .foregroundStyle(TextColors.onColorSecondary)
                    Text(next.date.formatted(date: .omitted, time: .shortened))
                        .appFont(.smallMedium)
                        .foregroundStyle(TextColors.onColorSecondary)
                        .monospacedDigit()
                    Text("·")
                        .appFont(.small)
                        .foregroundStyle(TextColors.onColorSecondary)
                    Text(next.title)
                        .appFont(.small)
                        .foregroundStyle(TextColors.onColorSecondary)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                }

                NavigationLink(value: AppRoute.plannedSession(assignmentId: next.assignmentId)) {
                    HStack(spacing: Spacing.xxs) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 12, weight: .semibold))
                        Text(String(localized: "Start next"))
                            .appFont(.buttonSmall)
                    }
                    .foregroundStyle(AppColors.primary)
                    .padding(.horizontal, Spacing.xs)
                    .padding(.vertical, Spacing.xxxs + 2)
                    .background(Capsule().fill(.white))
                }
                .buttonStyle(.plain)
            } else {
                // All done
                HStack(spacing: Spacing.xxs) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.9))
                    Text(String(localized: "All done for today 🎉"))
                        .appFont(.smallMedium)
                        .foregroundStyle(TextColors.onColorSecondary)
                }
            }
        }
        .padding(Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.xl, style: .continuous)
                .fill(AppColors.primary)
        )
        .accessibilityElement(children: .combine)
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 0) {
            statItem(
                icon: "flame.fill",
                value: "\(viewModel.streakDays)",
                label: String(localized: "Streak"),
                color: AppColors.State.warning
            )
            Divider().frame(height: 40)
            statItem(
                icon: "timer",
                value: "\(viewModel.minutesToday)",
                label: String(localized: "Min today"),
                color: AppColors.positive
            )
            Divider().frame(height: 40)
            statItem(
                icon: "chart.bar.fill",
                value: "\(viewModel.minutesLast7Days)",
                label: String(localized: "Min / 7d"),
                color: AppColors.accent
            )
        }
        .cardStyle(cornerRadius: CornerRadius.lg, padding: 0)
    }

    private func statItem(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: Spacing.xxxs) {
            HStack(spacing: Spacing.xxxs) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(color)
                Text(value)
                    .appFont(.h2)
                    .foregroundStyle(TextColors.primary)
                    .monospacedDigit()
            }
            Text(label)
                .appFont(.small)
                .foregroundStyle(TextColors.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.sm)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(value) \(label)")
    }

    // MARK: - Quick Access Section

    private var quickAccessSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            SectionHeader(
                title: String(localized: "Quick access"),
                onSeeAll: nil
            )

            VStack(spacing: Spacing.xxs) {
                ForEach(quickAccessItems) { item in
                    NavigationLink(value: item.route) {
                        quickAccessRow(item)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func quickAccessRow(_ item: QuickAccessItem) -> some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: item.icon)
                .font(.system(size: IconSize.glyph, weight: .medium))
                .foregroundStyle(item.color)
                .iconContainer(
                    size: IconSize.card,
                    backgroundColor: item.color.opacity(Opacity.softBackground),
                    cornerRadius: CornerRadius.sm
                )
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .appFont(.bodyMedium)
                    .foregroundStyle(TextColors.primary)
                Text(item.meta)
                    .appFont(.small)
                    .foregroundStyle(TextColors.secondary)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppColors.gray400)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .cardStyle(cornerRadius: CornerRadius.lg, padding: 0)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(item.name)
    }

    // MARK: - Article Row

    private func articleRow(article: Article) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            SectionHeader(title: String(localized: "Article of the day"), onSeeAll: nil)

            NavigationLink(value: AppRoute.articleDetail(articleId: article.id)) {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: article.icon)
                        .font(.system(size: IconSize.glyph, weight: .medium))
                        .foregroundStyle(AppColors.accent)
                        .iconContainer(
                            size: IconSize.card,
                            backgroundColor: AppColors.accent.opacity(Opacity.softBackground),
                            cornerRadius: CornerRadius.sm
                        )
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(article.title)
                            .appFont(.bodyMedium)
                            .foregroundStyle(TextColors.primary)
                            .lineLimit(2)
                        HStack(spacing: Spacing.xxs) {
                            Text(article.category)
                                .appFont(.small)
                                .foregroundStyle(AppColors.accent.opacity(0.8))
                            Text("·")
                                .appFont(.small)
                                .foregroundStyle(TextColors.tertiary)
                            Text(String(format: NSLocalizedString("%d min read", comment: ""), article.readTime))
                                .appFont(.small)
                                .foregroundStyle(TextColors.secondary)
                        }
                    }

                    Spacer(minLength: 0)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppColors.gray400)
                }
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
                .cardStyle(cornerRadius: CornerRadius.lg, padding: 0)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Resolve Favorite → QuickAccessItem

    private func resolveItem(_ favorite: FavoriteExercise) -> QuickAccessItem? {
        switch favorite.exerciseType {
        case .exposure:
            guard let id = favorite.exerciseId,
                  let exposure = exposures.first(where: { $0.id == id })
            else { return nil }
            return QuickAccessItem(
                id: favorite.id,
                name: exposure.localizedTitle,
                meta: String(localized: "Exposure · \(exposure.localizedStepTexts.count) steps"),
                icon: "leaf",
                color: AppColors.primary,
                route: .exposureDetail(exposureId: id)
            )
        case .breathing:
            guard let raw = favorite.exerciseIdentifier,
                  let type = BreathingPatternType(rawValue: raw),
                  let pattern = BreathingPattern.predefinedPatterns.first(where: { $0.type == type })
            else { return nil }
            return QuickAccessItem(
                id: favorite.id,
                name: pattern.localizedName,
                meta: String(localized: "Breathing"),
                icon: pattern.icon,
                color: AppColors.positive,
                route: .breathingDetail(patternType: type)
            )
        case .relaxation:
            guard let raw = favorite.exerciseIdentifier,
                  let type = RelaxationType(rawValue: raw),
                  let exercise = RelaxationExercise.predefinedExercises.first(where: { $0.type == type })
            else { return nil }
            return QuickAccessItem(
                id: favorite.id,
                name: exercise.name,
                meta: String(localized: "Relaxation · \(Int(exercise.duration / 60)) min"),
                icon: exercise.icon,
                color: AppColors.positive,
                route: .relaxationDetail(relaxationType: type)
            )
        case .grounding:
            guard let raw = favorite.exerciseIdentifier,
                  let type = GroundingType(rawValue: raw),
                  let exercise = GroundingExercise.predefinedExercises.first(where: { $0.type == type })
            else { return nil }
            return QuickAccessItem(
                id: favorite.id,
                name: exercise.name,
                meta: String(localized: "Grounding · \(max(1, Int(exercise.estimatedDuration / 60))) min"),
                icon: exercise.icon,
                color: AppColors.accent,
                route: .groundingDetail(groundingType: type)
            )
        case .behavioralActivation:
            guard let id = favorite.exerciseId,
                  let list = activityLists.first(where: { $0.id == id })
            else { return nil }
            return QuickAccessItem(
                id: favorite.id,
                name: list.localizedTitle,
                meta: String(localized: "Activation · \(list.localizedActivities.count) activities"),
                icon: "figure.walk",
                color: AppColors.positive,
                route: .activationView(activityListId: id, assignmentId: nil)
            )
        }
    }

    // MARK: - Refresh

    private func refreshViewModel() {
        viewModel.refresh(
            assignments: allAssignments,
            completions: allCompletions,
            exposures: exposures,
            activityLists: activityLists,
            breathingSessions: breathingSessions,
            groundingSessions: groundingSessions,
            relaxationSessions: relaxationSessions,
            exposureSessions: exposureSessions,
            activationSessions: activationSessions,
            favorites: favorites
        )
    }

    private var refreshTrigger: HomeRefreshTrigger {
        HomeRefreshTrigger(
            assignmentCount: allAssignments.count,
            completionCount: allCompletions.count,
            breathingCount: breathingSessions.count,
            groundingCount: groundingSessions.count,
            relaxationCount: relaxationSessions.count,
            exposureSessionCount: exposureSessions.count,
            activationCount: activationSessions.count,
            favoriteCount: favorites.count,
            exposureCount: exposures.count,
            activityListCount: activityLists.count
        )
    }

    private struct HomeRefreshTrigger: Equatable {
        let assignmentCount: Int
        let completionCount: Int
        let breathingCount: Int
        let groundingCount: Int
        let relaxationCount: Int
        let exposureSessionCount: Int
        let activationCount: Int
        let favoriteCount: Int
        let exposureCount: Int
        let activityListCount: Int
    }
}

// MARK: - QuickAccessItem

private struct QuickAccessItem: Identifiable {
    let id: UUID
    let name: String
    let meta: String
    let icon: String
    let color: Color
    let route: AppRoute

    /// Default exercises shown when favorites list is empty
    static let defaults: [QuickAccessItem] = [
        QuickAccessItem(
            id: UUID(),
            name: String(localized: "Box Breathing"),
            meta: String(localized: "Breathing · 4·4·4·4"),
            icon: "square.dashed",
            color: AppColors.positive,
            route: .breathingDetail(patternType: .box)
        ),
        QuickAccessItem(
            id: UUID(),
            name: String(localized: "Exposures"),
            meta: String(localized: "Face your fears gradually"),
            icon: "leaf",
            color: AppColors.primary,
            route: .exerciseList(.exposures)
        ),
        QuickAccessItem(
            id: UUID(),
            name: String(localized: "5-4-3-2-1"),
            meta: String(localized: "Grounding · 2 min"),
            icon: "brain.head.profile",
            color: AppColors.accent,
            route: .groundingDetail(groundingType: .fiveFourThreeTwoOne)
        ),
    ]
}

// MARK: - Preview

#Preview {
    HomeView(path: .constant(NavigationPath()))
        .modelContainer(
            for: [
                ExerciseAssignment.self,
                ExerciseCompletion.self,
                FavoriteExercise.self,
                Exposure.self,
                ActivityList.self,
                BreathingSessionResult.self,
                GroundingSessionResult.self,
                RelaxationSessionResult.self,
                ExposureSessionResult.self,
                BehavioralActivationSession.self
            ],
            inMemory: true
        )
        .environment(ArticlesStore())
}
