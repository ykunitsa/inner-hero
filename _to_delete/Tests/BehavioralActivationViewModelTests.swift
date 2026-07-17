//
//  BehavioralActivationViewModelTests.swift
//  Inner HeroTests
//
//  Pure-logic tests for filtering, analytics, and smart-random selection.
//

import XCTest
@testable import Inner_Hero

final class BehavioralActivationViewModelTests: XCTestCase {

    private let catA = UUID()
    private let catB = UUID()

    private func makeTask(
        title: String,
        category: UUID,
        pleasure: Bool = false,
        mastery: Bool = false,
        effort: EffortLevel = .low,
        hidden: Bool = false,
        hint: String? = nil
    ) -> ActivationTask {
        ActivationTask(
            categoryId: category,
            title: title,
            hint: hint,
            pleasureTag: pleasure,
            masteryTag: mastery,
            effortLevel: effort,
            isHiddenByUser: hidden
        )
    }

    private func makeCompleted(
        activityId: UUID,
        before: Int,
        after: Int,
        completedAt: Date = Date()
    ) -> ActivationSession {
        ActivationSession(
            activityId: activityId,
            status: .completed,
            moodBefore: before,
            moodAfter: after,
            moodDelta: after - before,
            completedAt: completedAt
        )
    }

    // MARK: - filteredTasks

    func testFilteredTasksExcludesHidden() {
        let vm = BehavioralActivationViewModel()
        let visible = makeTask(title: "Walk", category: catA)
        let hidden = makeTask(title: "Hidden", category: catA, hidden: true)

        let result = vm.filteredTasks([visible, hidden])

        XCTAssertEqual(result.map(\.title), ["Walk"])
    }

    func testFilteredTasksSearchMatchesTitleAndHint() {
        let vm = BehavioralActivationViewModel()
        let byTitle = makeTask(title: "Morning walk", category: catA)
        let byHint = makeTask(title: "Call a friend", category: catA, hint: "go for a walk together")
        let noMatch = makeTask(title: "Read a book", category: catA)
        vm.searchText = "walk"

        let result = vm.filteredTasks([byTitle, byHint, noMatch])

        XCTAssertEqual(Set(result.map(\.title)), ["Morning walk", "Call a friend"])
    }

    func testFilteredTasksByCategory() {
        let vm = BehavioralActivationViewModel()
        let a = makeTask(title: "A", category: catA)
        let b = makeTask(title: "B", category: catB)
        vm.filterCategoryIds = [catB]

        let result = vm.filteredTasks([a, b])

        XCTAssertEqual(result.map(\.title), ["B"])
    }

    func testFilteredTasksByPleasureAndMastery() {
        let vm = BehavioralActivationViewModel()
        let pleasure = makeTask(title: "P", category: catA, pleasure: true)
        let mastery = makeTask(title: "M", category: catA, mastery: true)
        vm.filterPleasure = true

        XCTAssertEqual(vm.filteredTasks([pleasure, mastery]).map(\.title), ["P"])

        vm.filterPleasure = false
        vm.filterMastery = true
        XCTAssertEqual(vm.filteredTasks([pleasure, mastery]).map(\.title), ["M"])
    }

    func testFilteredTasksByEffort() {
        let vm = BehavioralActivationViewModel()
        let low = makeTask(title: "Low", category: catA, effort: .low)
        let high = makeTask(title: "High", category: catA, effort: .high)
        vm.filterEffortLevels = [.high]

        XCTAssertEqual(vm.filteredTasks([low, high]).map(\.title), ["High"])
    }

    // MARK: - analytics

    func testAnalyticsCountsAndAverages() {
        let vm = BehavioralActivationViewModel()
        let id = UUID()
        let sessions = [
            makeCompleted(activityId: id, before: 4, after: 7),
            makeCompleted(activityId: id, before: 6, after: 4),
            ActivationSession(activityId: id, status: .planned),
        ]

        let analytics = vm.analytics(from: sessions)

        XCTAssertEqual(analytics.totalCompleted, 2)
        XCTAssertEqual(analytics.weeklyCompleted, 2)
        XCTAssertEqual(analytics.averageDelta ?? .nan, 0.5, accuracy: 0.0001)
        XCTAssertEqual(analytics.averageMoodBefore ?? .nan, 5.0, accuracy: 0.0001)
        XCTAssertEqual(analytics.averageMoodAfter ?? .nan, 5.5, accuracy: 0.0001)
    }

    func testAnalyticsEmptyIsZeroAndNil() {
        let vm = BehavioralActivationViewModel()

        let analytics = vm.analytics(from: [])

        XCTAssertEqual(analytics.totalCompleted, 0)
        XCTAssertNil(analytics.averageDelta)
        XCTAssertNil(analytics.averageMoodBefore)
        XCTAssertNil(analytics.averageMoodAfter)
    }

    // MARK: - smartRandom

    func testSmartRandomReturnsNilWhenNoTasks() {
        let vm = BehavioralActivationViewModel()

        let result = vm.smartRandom(from: [], recentSessions: [])

        XCTAssertNil(result.task)
        XCTAssertFalse(result.ignoredFilters)
    }

    func testSmartRandomFlagsIgnoredFiltersOnFallback() {
        let vm = BehavioralActivationViewModel()
        let task = makeTask(title: "Walk", category: catA)
        vm.filterCategoryIds = [catB] // no task matches → fallback to full pool

        let result = vm.smartRandom(from: [task], recentSessions: [])

        XCTAssertEqual(result.task?.title, "Walk")
        XCTAssertTrue(result.ignoredFilters)
    }

    func testSmartRandomExcludesActivitiesCompletedToday() {
        let vm = BehavioralActivationViewModel()
        let done = makeTask(title: "Done", category: catA)
        let fresh = makeTask(title: "Fresh", category: catA)
        let completedToday = makeCompleted(activityId: done.id, before: 5, after: 6)

        let result = vm.smartRandom(from: [done, fresh], recentSessions: [completedToday])

        XCTAssertEqual(result.task?.title, "Fresh")
        XCTAssertFalse(result.ignoredFilters)
    }
}
