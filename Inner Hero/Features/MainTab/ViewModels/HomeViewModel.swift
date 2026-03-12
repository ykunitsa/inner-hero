import Foundation
import SwiftData

@Observable
@MainActor
final class HomeViewModel {

    // MARK: - State

    private(set) var plannedToday: [ExerciseAssignment] = []
    private(set) var doneTodayCount: Int = 0
    private(set) var plannedTodayCount: Int = 0
    private(set) var nextPlanned: PlannedUpcoming? = nil
    private(set) var isLoading: Bool = false

    /// Derived for widgets (minutes, streak, quick start).
    private(set) var minutesToday: Int = 0
    private(set) var minutesLast7Days: Int = 0
    private(set) var streakDays: Int = 0
    private(set) var quickStartFavorites: [FavoriteExercise] = []

    private let calendar = Calendar.current

    // MARK: - Refresh

    func refresh(
        assignments: [ExerciseAssignment],
        completions: [ExerciseCompletion],
        exposures: [Exposure],
        activityLists: [ActivityList],
        breathingSessions: [BreathingSessionResult],
        groundingSessions: [GroundingSessionResult],
        relaxationSessions: [RelaxationSessionResult],
        exposureSessions: [ExposureSessionResult],
        activationSessions: [BehavioralActivationSession],
        favorites: [FavoriteExercise]
    ) {
        let dayStart = calendar.startOfDay(for: Date())
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? Date()
        let weekday = calendar.component(.weekday, from: Date())

        // Planned today: active assignments that include today's weekday, sorted by time
        let planned = assignments
            .filter { $0.isActive && $0.hasDay(weekday) }
            .sorted { $0.time < $1.time }
        plannedToday = planned
        plannedTodayCount = planned.count

        let plannedTodayIds = Set(planned.map(\.id))

        // Done today: completions for today whose assignment is in planned today
        let todayCompletions = completions.filter { completion in
            completion.day == dayStart && plannedTodayIds.contains(completion.assignmentId)
        }
        doneTodayCount = todayCompletions.count

        // Next planned: first occurrence in the next 3 days
        nextPlanned = nextPlannedUpcoming(
            assignments: assignments,
            dayStart: dayStart,
            exposures: exposures,
            activityLists: activityLists
        )

        // Practice minutes
        minutesToday = totalPracticeMinutes(from: dayStart, to: dayEnd,
            breathingSessions: breathingSessions,
            groundingSessions: groundingSessions,
            relaxationSessions: relaxationSessions,
            exposureSessions: exposureSessions,
            activationSessions: activationSessions
        )
        let weekStart = calendar.date(byAdding: .day, value: -6, to: dayStart) ?? dayStart
        minutesLast7Days = totalPracticeMinutes(from: weekStart, to: dayEnd,
            breathingSessions: breathingSessions,
            groundingSessions: groundingSessions,
            relaxationSessions: relaxationSessions,
            exposureSessions: exposureSessions,
            activationSessions: activationSessions
        )

        // Streak
        streakDays = streakDays(from: completions, dayStart: dayStart)

        quickStartFavorites = Array(favorites.prefix(3))
    }

    // MARK: - Private

    private func nextPlannedUpcoming(
        assignments: [ExerciseAssignment],
        dayStart: Date,
        exposures: [Exposure],
        activityLists: [ActivityList]
    ) -> PlannedUpcoming? {
        let now = Date()
        for dayOffset in 0..<3 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: dayStart) else { continue }
            let weekday = calendar.component(.weekday, from: date)
            let dayAssignments = assignments
                .filter { $0.isActive && $0.hasDay(weekday) }
                .sorted { $0.time < $1.time }
            for assignment in dayAssignments {
                let timeComponents = calendar.dateComponents([.hour, .minute], from: assignment.time)
                var dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
                dateComponents.hour = timeComponents.hour
                dateComponents.minute = timeComponents.minute
                guard let occurrence = calendar.date(from: dateComponents) else { continue }
                guard occurrence >= now else { continue }
                let title = assignment.displayTitle(exposures: exposures, activityLists: activityLists)
                return PlannedUpcoming(date: occurrence, assignment: assignment, title: title)
            }
        }
        return nil
    }

    private func totalPracticeMinutes(
        from start: Date,
        to end: Date,
        breathingSessions: [BreathingSessionResult],
        groundingSessions: [GroundingSessionResult],
        relaxationSessions: [RelaxationSessionResult],
        exposureSessions: [ExposureSessionResult],
        activationSessions: [BehavioralActivationSession]
    ) -> Int {
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

    private func streakDays(from completions: [ExerciseCompletion], dayStart: Date) -> Int {
        let daysWithCompletion = Set(completions.map { calendar.startOfDay(for: $0.day) })
        var streak = 0
        var cursor = dayStart
        while daysWithCompletion.contains(cursor) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return streak
    }
}
