import Foundation
import SwiftData
import SwiftUI

// MARK: - WeekProgress

struct WeekProgress: Equatable {
    let completedThisWeek: Int
    let plannedDoneThisWeek: Int
    let streakDays: Int

    static let empty = WeekProgress(completedThisWeek: 0, plannedDoneThisWeek: 0, streakDays: 0)
}

// MARK: - CompletedEntry

struct CompletedEntry: Identifiable {
    let id: String
    let title: String
    let time: Date?
    let detail: String?
    let sourceLabel: String
    let systemImage: String
    let tint: Color

    var timeString: String? {
        guard let time else { return nil }
        return ScheduleViewModel.timeFormatter.string(from: time)
    }
}

// MARK: - ScheduleViewModel

@Observable
@MainActor
final class ScheduleViewModel {
    var selectedDate: Date = Date()
    var plannedAssignments: [ExerciseAssignment] = []
    var completedEntries: [CompletedEntry] = []
    var weekProgress: WeekProgress = .empty
    var manualCompletionByAssignmentId: [UUID: ExerciseCompletion] = [:]
    var isLoading = false
    var error: String?

    private static let completedStatusRaw = SessionStatus.completed.rawValue

    static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = .current
        f.timeStyle = .short
        f.dateStyle = .none
        return f
    }()

    private static let durationFormatter: DateComponentsFormatter = {
        let f = DateComponentsFormatter()
        f.allowedUnits = [.minute, .second]
        f.unitsStyle = .abbreviated
        f.zeroFormattingBehavior = .dropAll
        return f
    }()

    // MARK: - Refresh

    /// Refreshes plannedAssignments, completedEntries, weekProgress, manualCompletionByAssignmentId for the given selectedDate.
    func refresh(
        context: ModelContext,
        allAssignments: [ExerciseAssignment],
        selectedDate: Date,
        exposures: [Exposure],
        activationTasks: [ActivationTask]
    ) async {
        isLoading = true
        error = nil
        self.selectedDate = selectedDate

        defer { isLoading = false }

        let weekday = Calendar.current.component(.weekday, from: selectedDate)
        plannedAssignments = allAssignments.filter { $0.hasDay(weekday) }

        do {
            refreshManualCompletions(context: context, selectedDate: selectedDate)
            completedEntries = try buildCompletedEntries(context: context, selectedDate: selectedDate, exposures: exposures, activationTasks: activationTasks)
            weekProgress = try buildWeekProgress(context: context, selectedDate: selectedDate)
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func refreshManualCompletions(context: ModelContext, selectedDate: Date) {
        let dayStart = Calendar.current.startOfDay(for: selectedDate)
        let descriptor = FetchDescriptor<ExerciseCompletion>(
            predicate: #Predicate { $0.day == dayStart },
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        do {
            let results = try context.fetch(descriptor)
            manualCompletionByAssignmentId = Dictionary(uniqueKeysWithValues: results.map { ($0.assignmentId, $0) })
        } catch {
            manualCompletionByAssignmentId = [:]
        }
    }

    private func buildCompletedEntries(
        context: ModelContext,
        selectedDate: Date,
        exposures: [Exposure],
        activationTasks: [ActivationTask]
    ) throws -> [CompletedEntry] {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: selectedDate)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart.addingTimeInterval(24 * 60 * 60)

        var entries: [CompletedEntry] = []

        let manualDescriptor = FetchDescriptor<ExerciseCompletion>(
            predicate: #Predicate { $0.day == dayStart },
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        let manual = try context.fetch(manualDescriptor)
        entries.append(contentsOf: manual.map { completion in
            CompletedEntry(
                id: "manual|\(completion.id.uuidString)",
                title: completionTitle(completion, exposures: exposures, activationTasks: activationTasks),
                time: completion.createdAt,
                detail: String(localized: "on schedule"),
                sourceLabel: String(localized: "Entry"),
                systemImage: "checkmark.circle.fill",
                tint: .green
            )
        })

        let breathingDescriptor = FetchDescriptor<BreathingSessionResult>(
            predicate: #Predicate { $0.performedAt >= dayStart && $0.performedAt < dayEnd },
            sortBy: [SortDescriptor(\.performedAt, order: .forward)]
        )
        let breathingResults = try context.fetch(breathingDescriptor)
        entries.append(contentsOf: breathingResults.map { result in
            let name = BreathingPattern.predefinedPatterns.first(where: { $0.type == result.patternType })?.localizedName ?? result.patternType.rawValue
            return CompletedEntry(
                id: "breathing|\(result.id.uuidString)",
                title: String(format: NSLocalizedString("Breathing: %@", comment: ""), name),
                time: result.performedAt,
                detail: formatDuration(result.duration),
                sourceLabel: String(localized: "Session"),
                systemImage: "wind",
                tint: .cyan
            )
        })

        let relaxationDescriptor = FetchDescriptor<RelaxationSessionResult>(
            predicate: #Predicate { $0.performedAt >= dayStart && $0.performedAt < dayEnd },
            sortBy: [SortDescriptor(\.performedAt, order: .forward)]
        )
        let relaxationResults = try context.fetch(relaxationDescriptor)
        entries.append(contentsOf: relaxationResults.map { result in
            let name = RelaxationExercise.predefinedExercises.first(where: { $0.type == result.type })?.name ?? result.type.rawValue
            return CompletedEntry(
                id: "relaxation|\(result.id.uuidString)",
                title: String(format: NSLocalizedString("Relaxation: %@", comment: ""), name),
                time: result.performedAt,
                detail: formatDuration(result.duration),
                sourceLabel: String(localized: "Session"),
                systemImage: "figure.mind.and.body",
                tint: .blue
            )
        })

        let groundingDescriptor = FetchDescriptor<GroundingSessionResult>(
            predicate: #Predicate { $0.performedAt >= dayStart && $0.performedAt < dayEnd },
            sortBy: [SortDescriptor(\.performedAt, order: .forward)]
        )
        let groundingResults = try context.fetch(groundingDescriptor)
        entries.append(contentsOf: groundingResults.map { result in
            let name = GroundingExercise.predefinedExercises.first(where: { $0.type == result.type })?.name ?? result.type.rawValue
            return CompletedEntry(
                id: "grounding|\(result.id.uuidString)",
                title: String(format: NSLocalizedString("Grounding: %@", comment: ""), name),
                time: result.performedAt,
                detail: formatDuration(result.duration),
                sourceLabel: String(localized: "Session"),
                systemImage: "brain.head.profile",
                tint: .indigo
            )
        })

        let exposureDescriptor = FetchDescriptor<ExposureSessionResult>(
            predicate: #Predicate { $0.startAt >= dayStart && $0.startAt < dayEnd && $0.endAt != nil },
            sortBy: [SortDescriptor(\.startAt, order: .forward)]
        )
        let exposureResults = try context.fetch(exposureDescriptor)
        entries.append(contentsOf: exposureResults.map { result in
            let title = result.exposure?.localizedTitle ?? String(localized: "Exposure")
            let duration: TimeInterval = {
                guard let endAt = result.endAt else { return 0 }
                return max(0, endAt.timeIntervalSince(result.startAt))
            }()
            return CompletedEntry(
                id: "exposure|\(result.id.uuidString)",
                title: String(format: NSLocalizedString("Exposure: %@", comment: ""), title),
                time: result.startAt,
                detail: duration > 0 ? formatDuration(duration) : nil,
                sourceLabel: String(localized: "Session"),
                systemImage: "shield.lefthalf.filled",
                tint: .orange
            )
        })

        let completedRaw = Self.completedStatusRaw
        let baDescriptor = FetchDescriptor<ActivationSession>(
            predicate: #Predicate { $0.statusRaw == completedRaw && $0.completedAt != nil },
            sortBy: [SortDescriptor(\.completedAt, order: .forward)]
        )
        let baResults = try context.fetch(baDescriptor).filter {
            guard let completedAt = $0.completedAt else { return false }
            return completedAt >= dayStart && completedAt < dayEnd
        }
        entries.append(contentsOf: baResults.map { session in
            let taskTitle = activationTasks.first(where: { $0.id == session.activityId })?.localizedTitle ?? String(localized: "Behavioral activation")
            let durationDetail = session.actualMinutes.map { "\($0) min" }
            return CompletedEntry(
                id: "ba|\(session.id.uuidString)",
                title: String(format: NSLocalizedString("Activation: %@", comment: ""), taskTitle),
                time: session.completedAt,
                detail: durationDetail,
                sourceLabel: String(localized: "Session"),
                systemImage: "sparkles",
                tint: .mint
            )
        })

        entries.sort { ($0.time ?? .distantPast) < ($1.time ?? .distantPast) }
        return entries
    }

    private func completionTitle(_ completion: ExerciseCompletion, exposures: [Exposure], activationTasks: [ActivationTask]) -> String {
        switch completion.exerciseType {
        case .exposure:
            if let id = completion.exposureId, let exposure = exposures.first(where: { $0.id == id }) {
                return String(format: NSLocalizedString("Exposure: %@", comment: ""), exposure.localizedTitle)
            }
            return String(localized: "Exposure")
        case .breathing:
            if let raw = completion.breathingPatternType, let type = BreathingPatternType(rawValue: raw) {
                let name = BreathingPattern.predefinedPatterns.first(where: { $0.type == type })?.localizedName ?? type.rawValue
                return String(format: NSLocalizedString("Breathing: %@", comment: ""), name)
            }
            return String(localized: "Breathing")
        case .relaxation:
            if let raw = completion.relaxationType, let type = RelaxationType(rawValue: raw) {
                let name = RelaxationExercise.predefinedExercises.first(where: { $0.type == type })?.name ?? type.rawValue
                return String(format: NSLocalizedString("Relaxation: %@", comment: ""), name)
            }
            return String(localized: "Relaxation")
        case .grounding:
            if let raw = completion.groundingType, let type = GroundingType(rawValue: raw) {
                let name = GroundingExercise.predefinedExercises.first(where: { $0.type == type })?.name ?? type.rawValue
                return String(format: NSLocalizedString("Grounding: %@", comment: ""), name)
            }
            return String(localized: "Grounding")
        case .behavioralActivation:
            if let id = completion.activityId, let task = activationTasks.first(where: { $0.id == id }) {
                return String(format: NSLocalizedString("Activation: %@", comment: ""), task.localizedTitle)
            }
            return String(localized: "Behavioral activation")
        }
    }

    private func buildWeekProgress(context: ModelContext, selectedDate: Date) throws -> WeekProgress {
        let calendar = Calendar.current
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: selectedDate) else {
            return .empty
        }
        let completedThisWeek = countAllCompletedSessions(context: context, from: weekInterval.start, to: weekInterval.end)
        let plannedDoneThisWeek = countManualCompletions(context: context, from: weekInterval.start, to: weekInterval.end)
        let streakDays = computeStreakDays(context: context, lookbackDays: 60)
        return WeekProgress(
            completedThisWeek: completedThisWeek + plannedDoneThisWeek,
            plannedDoneThisWeek: plannedDoneThisWeek,
            streakDays: streakDays
        )
    }

    private func countManualCompletions(context: ModelContext, from start: Date, to end: Date) -> Int {
        let startDay = Calendar.current.startOfDay(for: start)
        let endDay = Calendar.current.startOfDay(for: end)
        let descriptor = FetchDescriptor<ExerciseCompletion>(
            predicate: #Predicate { $0.day >= startDay && $0.day < endDay }
        )
        return (try? context.fetchCount(descriptor)) ?? 0
    }

    private func countAllCompletedSessions(context: ModelContext, from start: Date, to end: Date) -> Int {
        var total = 0
        total += (try? context.fetchCount(FetchDescriptor<BreathingSessionResult>(predicate: #Predicate { $0.performedAt >= start && $0.performedAt < end }))) ?? 0
        total += (try? context.fetchCount(FetchDescriptor<RelaxationSessionResult>(predicate: #Predicate { $0.performedAt >= start && $0.performedAt < end }))) ?? 0
        total += (try? context.fetchCount(FetchDescriptor<GroundingSessionResult>(predicate: #Predicate { $0.performedAt >= start && $0.performedAt < end }))) ?? 0
        total += (try? context.fetchCount(FetchDescriptor<ExposureSessionResult>(predicate: #Predicate { $0.startAt >= start && $0.startAt < end && $0.endAt != nil }))) ?? 0
        let completedRaw = Self.completedStatusRaw
        total += (try? context.fetchCount(FetchDescriptor<ActivationSession>(predicate: #Predicate { $0.statusRaw == completedRaw && $0.completedAt != nil && $0.completedAt! >= start && $0.completedAt! < end }))) ?? 0
        return total
    }

    private func computeStreakDays(context: ModelContext, lookbackDays: Int) -> Int {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        guard let lookbackStart = calendar.date(byAdding: .day, value: -(max(1, lookbackDays) - 1), to: todayStart) else { return 0 }
        let end = calendar.date(byAdding: .day, value: 1, to: todayStart) ?? Date()
        var daysWithCompletion = Set<Date>()
        func insertDay(_ date: Date) { daysWithCompletion.insert(calendar.startOfDay(for: date)) }

        if let results = try? context.fetch(FetchDescriptor<ExerciseCompletion>(predicate: #Predicate { $0.day >= lookbackStart && $0.day < end })) {
            results.forEach { insertDay($0.day) }
        }
        if let results = try? context.fetch(FetchDescriptor<BreathingSessionResult>(predicate: #Predicate { $0.performedAt >= lookbackStart && $0.performedAt < end })) {
            results.forEach { insertDay($0.performedAt) }
        }
        if let results = try? context.fetch(FetchDescriptor<RelaxationSessionResult>(predicate: #Predicate { $0.performedAt >= lookbackStart && $0.performedAt < end })) {
            results.forEach { insertDay($0.performedAt) }
        }
        if let results = try? context.fetch(FetchDescriptor<GroundingSessionResult>(predicate: #Predicate { $0.performedAt >= lookbackStart && $0.performedAt < end })) {
            results.forEach { insertDay($0.performedAt) }
        }
        if let results = try? context.fetch(FetchDescriptor<ExposureSessionResult>(predicate: #Predicate { $0.startAt >= lookbackStart && $0.startAt < end && $0.endAt != nil })) {
            results.forEach { insertDay($0.startAt) }
        }
        let completedRaw = Self.completedStatusRaw
        if let results = try? context.fetch(FetchDescriptor<ActivationSession>(predicate: #Predicate { $0.statusRaw == completedRaw && $0.completedAt != nil })) {
            results.filter {
                guard let d = $0.completedAt else { return false }
                return d >= lookbackStart && d < end
            }.forEach { insertDay($0.completedAt!) }
        }

        var streak = 0
        for offset in 0..<lookbackDays {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: todayStart) else { break }
            if daysWithCompletion.contains(day) { streak += 1 } else { break }
        }
        return streak
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        Self.durationFormatter.string(from: seconds) ?? ""
    }

    // MARK: - Create / Update / Delete

    func createAssignment(
        context: ModelContext,
        exerciseType: ExerciseType,
        daysOfWeek: [Int],
        time: Date,
        isActive: Bool,
        exposureId: UUID?,
        breathingPatternType: BreathingPatternType?,
        relaxationType: RelaxationType?,
        groundingType: GroundingType?,
        activityId: UUID?,
        notificationManager: NotificationManager
    ) async throws -> ExerciseAssignment {
        let assignment = ExerciseAssignment(
            exerciseType: exerciseType,
            daysOfWeek: daysOfWeek,
            time: time,
            isActive: isActive,
            exposureId: exposureId,
            breathingPatternType: breathingPatternType,
            relaxationType: relaxationType,
            groundingType: groundingType,
            activityId: activityId
        )
        context.insert(assignment)
        try context.save()
        if isActive {
            try await notificationManager.scheduleNotification(for: assignment)
            try context.save()
        }
        return assignment
    }

    func updateAssignment(
        _ assignment: ExerciseAssignment,
        context: ModelContext,
        daysOfWeek: [Int]? = nil,
        time: Date? = nil,
        isActive: Bool? = nil,
        exerciseType: ExerciseType? = nil,
        exposureId: UUID? = nil,
        breathingPatternType: BreathingPatternType? = nil,
        relaxationType: RelaxationType? = nil,
        groundingType: GroundingType? = nil,
        activityId: UUID? = nil,
        notificationManager: NotificationManager
    ) async throws {
        if let daysOfWeek { assignment.daysOfWeek = daysOfWeek }
        if let time { assignment.time = time }
        if let isActive { assignment.isActive = isActive }
        if let exerciseType { assignment.exerciseType = exerciseType }
        if let exposureId { assignment.exposureId = exposureId }
        if let breathingPatternType { assignment.breathingPattern = breathingPatternType }
        if let relaxationType { assignment.relaxation = relaxationType }
        if let groundingType { assignment.grounding = groundingType }
        if let activityId { assignment.activityId = activityId }
        try context.save()
        if assignment.isActive {
            try await notificationManager.updateNotification(for: assignment)
        } else {
            await notificationManager.cancelNotification(for: assignment)
        }
    }

    func deleteAssignment(
        _ assignment: ExerciseAssignment,
        context: ModelContext,
        notificationManager: NotificationManager
    ) async throws {
        await notificationManager.cancelNotification(for: assignment)
        context.delete(assignment)
        try context.save()
    }

    // MARK: - Mark completed (manual toggle on schedule tab)

    /// Toggles manual completion for the given assignment on selectedDate. Delegates to SessionCompletionService for idempotent create; removes completion if already present.
    func markCompleted(
        assignment: ExerciseAssignment,
        context: ModelContext,
        selectedDate: Date
    ) throws {
        let dayStart = Calendar.current.startOfDay(for: selectedDate)
        if let existing = manualCompletionByAssignmentId[assignment.id] {
            context.delete(existing)
            try context.save()
            refreshManualCompletions(context: context, selectedDate: selectedDate)
            return
        }
        if let _ = try? SessionCompletionService.markCompletedIfNeeded(assignmentId: assignment.id, context: context, day: dayStart) {
            refreshManualCompletions(context: context, selectedDate: selectedDate)
        }
    }
}

// MARK: - Environment Keys

private struct ScheduleViewModelKey: EnvironmentKey {
    static let defaultValue: ScheduleViewModel? = nil
}

extension EnvironmentValues {
    var scheduleViewModel: ScheduleViewModel? {
        get { self[ScheduleViewModelKey.self] }
        set { self[ScheduleViewModelKey.self] = newValue }
    }
}
