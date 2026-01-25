import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var appeared = false
    @EnvironmentObject private var articlesStore: ArticlesStore
    
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
    
    private var calendar: Calendar { .current }
    
    private var dayStart: Date {
        calendar.startOfDay(for: Date())
    }
    
    private var dayEnd: Date {
        calendar.date(byAdding: .day, value: 1, to: dayStart) ?? Date()
    }
    
    private var plannedToday: [ExerciseAssignment] {
        let weekday = calendar.component(.weekday, from: Date())
        return allAssignments
            .filter { $0.isActive && $0.hasDay(weekday) }
            .sorted { $0.time < $1.time }
    }
    
    private var plannedTodayIds: Set<UUID> {
        Set(plannedToday.map(\.id))
    }
    
    private var doneTodayCount: Int {
        let todayCompletions = allCompletions.filter { completion in
            completion.day == dayStart && plannedTodayIds.contains(completion.assignmentId)
        }
        return todayCompletions.count
    }
    
    private var plannedTodayCount: Int {
        plannedToday.count
    }
    
    private var nextPlanned: PlannedUpcoming? {
        let now = Date()
        
        // Look ahead for the next 3 days, same spirit as ScheduledExercisesSection but for a single next item.
        for dayOffset in 0..<3 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: dayStart) else { continue }
            let weekday = calendar.component(.weekday, from: date)
            
            let dayAssignments = allAssignments
                .filter { $0.isActive && $0.hasDay(weekday) }
                .sorted { $0.time < $1.time }
            
            for assignment in dayAssignments {
                let timeComponents = calendar.dateComponents([.hour, .minute], from: assignment.time)
                var dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
                dateComponents.hour = timeComponents.hour
                dateComponents.minute = timeComponents.minute
                
                guard let occurrence = calendar.date(from: dateComponents) else { continue }
                guard occurrence >= now else { continue }
                
                return PlannedUpcoming(
                    date: occurrence,
                    assignment: assignment,
                    title: assignmentTitle(assignment)
                )
            }
        }
        
        return nil
    }
    
    private var minutesToday: Int {
        totalPracticeMinutes(from: dayStart, to: dayEnd)
    }
    
    private var minutesLast7Days: Int {
        let start = calendar.date(byAdding: .day, value: -6, to: dayStart) ?? dayStart
        return totalPracticeMinutes(from: start, to: dayEnd)
    }
    
    private var streakDays: Int {
        let daysWithCompletion = Set(allCompletions.map { calendar.startOfDay(for: $0.day) })
        
        var streak = 0
        var cursor = dayStart
        while daysWithCompletion.contains(cursor) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        
        return streak
    }
    
    private var quickStartFavorites: [FavoriteExercise] {
        Array(favorites.prefix(3))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: Spacing.xs) {
                    TodayPlanHeroWidget(
                        planned: plannedTodayCount,
                        done: doneTodayCount,
                        next: nextPlanned
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
                        NextPlannedWidget(next: nextPlanned)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                            .animation(.easeOut(duration: 0.3).delay(0.05), value: appeared)
                        
                        MinutesWidget(todayMinutes: minutesToday, weekMinutes: minutesLast7Days)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                            .animation(.easeOut(duration: 0.3).delay(0.10), value: appeared)
                        
                        StreakWidget(streakDays: streakDays)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                            .animation(.easeOut(duration: 0.3).delay(0.15), value: appeared)
                        
                        QuickStartWidget(favorites: quickStartFavorites)
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
            .navigationTitle("Сводка")
            .navigationBarTitleDisplayMode(.large)
            .opacity(appeared ? 1 : 0)
            .animation(.easeIn(duration: 0.3), value: appeared)
            .onAppear {
                appeared = true
            }
        }
    }
    
    private func totalPracticeMinutes(from start: Date, to end: Date) -> Int {
        let totalSeconds: TimeInterval =
        breathingSessions
            .filter { $0.performedAt >= start && $0.performedAt < end }
            .reduce(0) { $0 + $1.duration }
        + groundingSessions
            .filter { $0.performedAt >= start && $0.performedAt < end }
            .reduce(0) { $0 + $1.duration }
        + relaxationSessions
            .filter { $0.performedAt >= start && $0.performedAt < end }
            .reduce(0) { $0 + $1.duration }
        + exposureSessions
            .filter { $0.startAt >= start && $0.startAt < end && $0.endAt != nil }
            .reduce(0) { sum, result in
                guard let endAt = result.endAt else { return sum }
                return sum + endAt.timeIntervalSince(result.startAt)
            }
        + activationSessions
            .filter { $0.startedAt >= start && $0.startedAt < end && $0.completedAt != nil }
            .reduce(0) { sum, result in
                guard let completedAt = result.completedAt else { return sum }
                return sum + completedAt.timeIntervalSince(result.startedAt)
            }
        
        return Int(totalSeconds / 60)
    }
    
    private func assignmentTitle(_ assignment: ExerciseAssignment) -> String {
        switch assignment.exerciseType {
        case .exposure:
            if let id = assignment.exposureId,
               let exposure = exposures.first(where: { $0.id == id }) {
                return exposure.title
            }
            return "Экспозиция"
            
        case .breathing:
            if let type = assignment.breathingPattern,
               let pattern = BreathingPattern.predefinedPatterns.first(where: { $0.type == type }) {
                return pattern.name
            }
            return "Дыхание"
            
        case .relaxation:
            if let type = assignment.relaxation,
               let exercise = RelaxationExercise.predefinedExercises.first(where: { $0.type == type }) {
                return exercise.name
            }
            return "Релаксация"
            
        case .grounding:
            if let type = assignment.grounding,
               let exercise = GroundingExercise.predefinedExercises.first(where: { $0.type == type }) {
                return exercise.name
            }
            return "Заземление"
            
        case .behavioralActivation:
            if let id = assignment.activityListId,
               let list = activityLists.first(where: { $0.id == id }) {
                return list.title
            }
            return "Поведенческая активация"
        }
    }
}

#Preview {
    HomeView()
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
        .environmentObject(ArticlesStore())
}


