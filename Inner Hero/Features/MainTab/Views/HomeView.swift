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

    private var articles: [Article] {
        articlesStore.featuredArticles
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                LazyVStack(spacing: Spacing.xs) {
                    TodayPlanHeroWidget(
                        planned: viewModel.plannedTodayCount,
                        done: viewModel.doneTodayCount,
                        next: viewModel.nextPlanned
                    )
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .animation(.easeOut(duration: 0.3).delay(0.0), value: appeared)

                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: Spacing.xs),
                            GridItem(.flexible(), spacing: Spacing.xs)
                        ],
                        spacing: Spacing.xs
                    ) {
                        NextPlannedWidget(next: viewModel.nextPlanned)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                            .animation(.easeOut(duration: 0.3).delay(0.05), value: appeared)

                        MinutesWidget(todayMinutes: viewModel.minutesToday, weekMinutes: viewModel.minutesLast7Days)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                            .animation(.easeOut(duration: 0.3).delay(0.10), value: appeared)

                        StreakWidget(streakDays: viewModel.streakDays)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                            .animation(.easeOut(duration: 0.3).delay(0.15), value: appeared)

                        QuickStartWidget(favorites: viewModel.quickStartFavorites)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                            .animation(.easeOut(duration: 0.3).delay(0.20), value: appeared)

                        ArticleOfTheDayWidget(article: articles.first)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                            .animation(.easeOut(duration: 0.3).delay(0.25), value: appeared)
                    }
                }
                .padding(.horizontal, Spacing.sm)
                .padding(.top, Spacing.xs)
                .padding(.bottom, Spacing.xxl)
            }
            .homeBackground()
            .navigationTitle("Summary")
            .navigationBarTitleDisplayMode(.large)
            .opacity(appeared ? 1 : 0)
            .animation(.easeIn(duration: 0.3), value: appeared)
            .onAppear {
                appeared = true
            }
            .task {
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
            .onChange(of: refreshTrigger) {
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
            .navigationDestination(for: AppRoute.self) { route in
                AppRouteView(route: route)
            }
        }
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
