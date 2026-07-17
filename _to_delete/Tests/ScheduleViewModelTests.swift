//
//  ScheduleViewModelTests.swift
//  Inner HeroTests
//
//  Exercises the public surface of ScheduleViewModel: planned-assignment filtering,
//  the manual-completion toggle, and weekly progress (counts + streak).
//
//  Time is injected (fixed clock + UTC calendar) so streak/week-window math is fully
//  deterministic regardless of when or where the suite runs.
//

import Foundation
import Testing
import SwiftData
@testable import Inner_Hero

@MainActor
@Suite("ScheduleViewModel")
struct ScheduleViewModelTests {

    /// Fixed "now": 2026-06-22 14:00 UTC (a Monday).
    private let fixedNow = TestSupport.date(year: 2026, month: 6, day: 22, hour: 14)
    private var calendar: Calendar { TestSupport.fixedCalendar }

    private func makeViewModel() -> ScheduleViewModel {
        ScheduleViewModel(now: { self.fixedNow }, calendar: calendar)
    }

    private func insertAssignment(
        into context: ModelContext,
        days: [Int],
        type: ExerciseType = .breathing
    ) -> ExerciseAssignment {
        let assignment = ExerciseAssignment(
            exerciseType: type,
            daysOfWeek: days,
            time: fixedNow
        )
        context.insert(assignment)
        try? context.save()
        return assignment
    }

    /// Seeds a manual ExerciseCompletion on `day`, normalized with the fixed calendar.
    private func insertCompletion(
        into context: ModelContext,
        assignment: ExerciseAssignment,
        day: Date
    ) {
        let completion = ExerciseCompletion(day: day, assignment: assignment, calendar: calendar)
        context.insert(completion)
        try? context.save()
    }

    /// Day start, `offsetDays` from the fixed "today".
    private func day(_ offsetDays: Int) -> Date {
        calendar.date(byAdding: .day, value: offsetDays, to: calendar.startOfDay(for: fixedNow))!
    }

    // MARK: - Planned filtering

    @Test("refresh keeps only assignments scheduled for the selected weekday")
    func filtersPlannedByWeekday() async throws {
        let context = try TestSupport.makeInMemoryContext()
        let todayWeekday = calendar.component(.weekday, from: fixedNow)
        let otherWeekday = todayWeekday == 7 ? 1 : todayWeekday + 1

        let matching = insertAssignment(into: context, days: [todayWeekday])
        _ = insertAssignment(into: context, days: [otherWeekday])

        let vm = makeViewModel()
        await vm.refresh(
            context: context,
            allAssignments: try context.fetch(FetchDescriptor<ExerciseAssignment>()),
            selectedDate: fixedNow,
            exposures: [],
            activationTasks: []
        )

        #expect(vm.plannedAssignments.map(\.id) == [matching.id])
    }

    // MARK: - Manual completion toggle

    @Test("markCompleted creates then removes a manual completion")
    func markCompletedToggles() async throws {
        let context = try TestSupport.makeInMemoryContext()
        let assignment = insertAssignment(into: context, days: [])

        let vm = makeViewModel()
        await vm.refresh(context: context, allAssignments: [assignment], selectedDate: fixedNow, exposures: [], activationTasks: [])

        // First toggle → creates.
        try vm.markCompleted(assignment: assignment, context: context, selectedDate: fixedNow)
        #expect(vm.manualCompletionByAssignmentId[assignment.id] != nil)
        #expect(try context.fetchCount(FetchDescriptor<ExerciseCompletion>()) == 1)

        // Second toggle → removes.
        try vm.markCompleted(assignment: assignment, context: context, selectedDate: fixedNow)
        #expect(vm.manualCompletionByAssignmentId[assignment.id] == nil)
        #expect(try context.fetchCount(FetchDescriptor<ExerciseCompletion>()) == 0)
    }

    // MARK: - Streak

    @Test("Streak counts consecutive days ending today")
    func streakCountsConsecutiveDays() async throws {
        let context = try TestSupport.makeInMemoryContext()
        let assignment = insertAssignment(into: context, days: [])

        insertCompletion(into: context, assignment: assignment, day: day(0))
        insertCompletion(into: context, assignment: assignment, day: day(-1))
        insertCompletion(into: context, assignment: assignment, day: day(-2))

        let vm = makeViewModel()
        await vm.refresh(context: context, allAssignments: [assignment], selectedDate: fixedNow, exposures: [], activationTasks: [])

        #expect(vm.weekProgress.streakDays == 3)
    }

    @Test("Streak breaks on a missing day")
    func streakBreaksOnGap() async throws {
        let context = try TestSupport.makeInMemoryContext()
        let assignment = insertAssignment(into: context, days: [])

        // Today and two days ago, but NOT yesterday → streak should be just today.
        insertCompletion(into: context, assignment: assignment, day: day(0))
        insertCompletion(into: context, assignment: assignment, day: day(-2))

        let vm = makeViewModel()
        await vm.refresh(context: context, allAssignments: [assignment], selectedDate: fixedNow, exposures: [], activationTasks: [])

        #expect(vm.weekProgress.streakDays == 1)
    }

    @Test("No completions yields an empty progress")
    func emptyProgress() async throws {
        let context = try TestSupport.makeInMemoryContext()
        let vm = makeViewModel()

        await vm.refresh(context: context, allAssignments: [], selectedDate: fixedNow, exposures: [], activationTasks: [])

        #expect(vm.weekProgress.streakDays == 0)
        #expect(vm.weekProgress.completedThisWeek == 0)
        #expect(vm.weekProgress.plannedDoneThisWeek == 0)
    }

    // MARK: - Weekly counts

    @Test("Weekly progress counts both sessions and manual completions")
    func weeklyCountsSessionsAndManual() async throws {
        let context = try TestSupport.makeInMemoryContext()
        let assignment = insertAssignment(into: context, days: [])

        // One manual completion today.
        insertCompletion(into: context, assignment: assignment, day: day(0))
        // One breathing session today (midday, inside the day window).
        let breathing = BreathingSessionResult(
            performedAt: TestSupport.date(year: 2026, month: 6, day: 22, hour: 12),
            duration: 120,
            patternType: .box
        )
        context.insert(breathing)
        try context.save()

        let vm = makeViewModel()
        await vm.refresh(context: context, allAssignments: [assignment], selectedDate: fixedNow, exposures: [], activationTasks: [])

        #expect(vm.weekProgress.plannedDoneThisWeek == 1)
        #expect(vm.weekProgress.completedThisWeek == 2)
    }
}
