import Foundation
import Observation
import SwiftData

// MARK: - BehavioralActivationViewModel

@Observable
final class BehavioralActivationViewModel {

    /// Injected time source. Defaults to the system clock; tests pass a fixed clock/calendar
    /// so "today", weekly windows, and staleness checks are deterministic.
    @ObservationIgnored private let now: () -> Date
    @ObservationIgnored private let calendar: Calendar

    init(now: @escaping () -> Date = { Date() }, calendar: Calendar = .current) {
        self.now = now
        self.calendar = calendar
    }

    // MARK: - Tab

    var selectedTab: Int = 0

    // MARK: - Search & Filter

    var searchText: String = ""
    var filterCategoryIds: Set<UUID> = []
    var filterPleasure: Bool = false
    var filterMastery: Bool = false
    var filterEffortLevels: Set<EffortLevel> = []

    var hasActiveFilters: Bool {
        !filterCategoryIds.isEmpty || filterPleasure || filterMastery || !filterEffortLevels.isEmpty
    }

    var showingCreateActivity: Bool = false

    // MARK: - Crash Recovery

    var interruptedSession: ActivationSession?
    var showingCrashRecovery: Bool = false

    // MARK: - Session Flow (push)

    /// Consumed once when `BASessionFlowView` appears after programmatic navigation (crash recovery).
    enum PendingSessionFlowResume: Hashable {
        case atActive(sessionId: UUID)
        case atPost(sessionId: UUID)
    }

    var pendingSessionFlowResume: PendingSessionFlowResume?

    func consumePendingSessionFlowResume() -> PendingSessionFlowResume? {
        let v = pendingSessionFlowResume
        pendingSessionFlowResume = nil
        return v
    }

    // MARK: - Toasts

    var showingRandomEmptyToast: Bool = false

    // MARK: - Filtering

    func filteredTasks(_ tasks: [ActivationTask]) -> [ActivationTask] {
        tasks.filter { task in
            guard !task.isHiddenByUser else { return false }

            if !searchText.isEmpty {
                let q = searchText.lowercased()
                let matchTitle = task.localizedTitle.lowercased().contains(q)
                let matchHint = task.localizedHint?.lowercased().contains(q) ?? false
                guard matchTitle || matchHint else { return false }
            }

            if !filterCategoryIds.isEmpty, !filterCategoryIds.contains(task.categoryId) { return false }
            if filterPleasure, !task.pleasureTag { return false }
            if filterMastery, !task.masteryTag { return false }
            if !filterEffortLevels.isEmpty, !filterEffortLevels.contains(task.effortLevel) { return false }
            return true
        }
    }

    // MARK: - Smart Random (Spec §3.1)

    /// Result of a smart-random pick. `ignoredFilters` is `true` when no task matched the
    /// active filters and the pick fell back to the full pool — the caller decides how to surface that.
    struct SmartRandomResult {
        let task: ActivationTask?
        let ignoredFilters: Bool
    }

    func smartRandom(from tasks: [ActivationTask], recentSessions: [ActivationSession]) -> SmartRandomResult {
        var pool = filteredTasks(tasks)
        var ignoredFilters = false

        if pool.isEmpty {
            // Fallback: ignore filters (caller may inform the user via `ignoredFilters`)
            pool = tasks.filter { !$0.isHiddenByUser }
            if pool.isEmpty { return SmartRandomResult(task: nil, ignoredFilters: false) }
            ignoredFilters = hasActiveFilters
        }

        let completedTodayIds = Set(
            recentSessions
                .filter {
                    $0.status == .completed &&
                    ($0.completedAt.map { calendar.isDate($0, inSameDayAs: now()) } ?? false)
                }
                .map { $0.activityId }
        )

        var candidates = pool.filter { !completedTodayIds.contains($0.id) }
        if candidates.isEmpty { candidates = pool }

        let hour = calendar.component(.hour, from: now())
        let lastThreeMoods = recentSessions
            .sorted { $0.createdAt > $1.createdAt }
            .prefix(3)
            .compactMap { $0.moodBefore }
        let lowEnergyContext = hour < 10 || (!lastThreeMoods.isEmpty && lastThreeMoods.allSatisfy { $0 <= 3 })

        let weighted: [(task: ActivationTask, weight: Int)] = candidates.map {
            (task: $0, weight: lowEnergyContext && $0.effortLevel == .low ? 3 : 1)
        }
        let total = weighted.reduce(0) { $0 + $1.weight }
        guard total > 0 else {
            return SmartRandomResult(task: candidates.randomElement(), ignoredFilters: ignoredFilters)
        }

        var roll = Int.random(in: 0..<total)
        for item in weighted {
            roll -= item.weight
            if roll < 0 { return SmartRandomResult(task: item.task, ignoredFilters: ignoredFilters) }
        }
        return SmartRandomResult(task: candidates.randomElement(), ignoredFilters: ignoredFilters)
    }

    // MARK: - Crash Recovery Check

    /// An in-progress session older than this is auto-abandoned instead of offered for resume.
    private static let staleSessionThreshold: TimeInterval = 24 * 60 * 60

    func checkInterruptedSession(_ sessions: [ActivationSession], context: ModelContext) {
        // Guard prevents re-showing after dismiss: interruptedSession stays non-nil
        // until the user explicitly resolves the session (continue / abandon / delete).
        guard interruptedSession == nil else { return }
        guard let session = sessions.first(where: { $0.status == .inProgress }) else { return }
        if let startedAt = session.startedAt, now().timeIntervalSince(startedAt) > Self.staleSessionThreshold {
            session.status = .abandoned
            try? context.save()
        } else {
            interruptedSession = session
            showingCrashRecovery = true
        }
    }

    // MARK: - Reset Filters

    func resetFilters() {
        filterCategoryIds = []
        filterPleasure = false
        filterMastery = false
        filterEffortLevels = []
        searchText = ""
    }

    // MARK: - Analytics (Spec §3.4)

    struct JournalAnalytics {
        var totalCompleted: Int = 0
        var weeklyCompleted: Int = 0
        var averageDelta: Double?
        var averageMoodBefore: Double?
        var averageMoodAfter: Double?
    }

    func analytics(from sessions: [ActivationSession]) -> JournalAnalytics {
        let completed = sessions.filter { $0.status == .completed }
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: now()) ?? now()
        let weekly = completed.filter { ($0.completedAt ?? .distantPast) > weekAgo }

        func avg(_ arr: [Int]) -> Double? {
            arr.isEmpty ? nil : Double(arr.reduce(0, +)) / Double(arr.count)
        }

        return JournalAnalytics(
            totalCompleted: completed.count,
            weeklyCompleted: weekly.count,
            averageDelta: avg(completed.compactMap { $0.moodDelta }),
            averageMoodBefore: avg(completed.compactMap { $0.moodBefore }),
            averageMoodAfter: avg(completed.compactMap { $0.moodAfter })
        )
    }
}
