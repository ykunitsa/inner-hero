//
//  ScheduleViewModelTests.swift
//  Inner HeroTests
//
//  Exercises the public surface of ScheduleViewModel: planned-assignment filtering,
//  the manual-completion toggle, and weekly progress (counts + streak).
//
//  NOTE: ScheduleViewModel reads `Date()` / `Calendar.current` directly (not yet
//  time-injectable — see TECH_DEBT A2). Seeds are therefore anchored to the real
//  clock via TestSupport.dayStart/midday so assertions stay deterministic.
//

import Foundation
import Testing
import SwiftData
@testable import Inner_Hero

@MainActor
@Suite("ScheduleViewModel")
struct ScheduleViewModelTests {

    private func insertAssignment(
        into context: ModelContext,
        days: [Int],
        type: ExerciseType = .breathing
    ) -> ExerciseAssignment {
        let assignment = ExerciseAssignment(
            exerciseType: type,
            daysOfWeek: days,
            time: TestSupport.midday()
        )
        context.insert(assignment)
        try? context.save()
        return assignment
    }

    /// Seeds a manual ExerciseCompletion for `assignment` on the given day.
    private func insertCompletion(
        into context: ModelContext,
        assignment: ExerciseAssignment,
        day: Date
    ) {
        let completion = ExerciseCompletion(day: day, assignment: assignment)
        context.insert(completion)
        try? context.save()
    }

    // MARK: - Planned filtering

    @Test("refresh keeps only assignments scheduled for the selected weekday")
    func filtersPlannedByWeekday() async throws {
        let context = try TestSupport.makeInMemoryContext()
        let today = Date()
        let todayWeekday = Calendar.current.component(.weekday, from: today)
        let otherWeekday = todayWeekday == 7 ? 1 : todayWeekday + 1

        let matching = insertAssignment(into: context, days: [todayWeekday])
        _ = insertAssignment(into: context, days: [otherWeekday])

        let vm = ScheduleViewModel()
        await vm.refresh(
            context: context,
            allAssignments: try context.fetch(FetchDescriptor<ExerciseAssignment>()),
            selectedDate: today,
            exposures: [],
            activationTasks: []
        )

        #expect(vm.plannedAssignments.allSatisfy { $0.hasDay(todayWeekday) })
        #expect(vm.plannedAssignments.contains { $0.id == matching.id })
        #expect(vm.plannedAssignments.count == 1)
    }

    // MARK: - Manual completion toggle

    @Test("markCompleted creates then removes a manual completion")
    func markCompletedToggles() async throws {
        let context = try TestSupport.makeInMemoryContext()
        let today = Date()
        let assignment = insertAssignment(into: context, days: [])

        let vm = ScheduleViewModel()
        // Establish baseline state for the day.
        await vm.refresh(context: context, allAssignments: [assignment], selectedDate: today, exposures: [], activationTasks: [])

        // First toggle → creates.
        try vm.markCompleted(assignment: assignment, context: context, selectedDate: today)
        #expect(vm.manualCompletionByAssignmentId[assignment.id] != nil)
        #expect(try context.fetchCount(FetchDescriptor<ExerciseCompletion>()) == 1)

        // Second toggle → removes.
        try vm.markCompleted(assignment: assignment, context: context, selectedDate: today)
        #expect(vm.manualCompletionByAssignmentId[assignment.id] == nil)
        #expect(try context.fetchCount(FetchDescriptor<ExerciseCompletion>()) == 0)
    }

    // MARK: - Streak

    @Test("Streak counts consecutive days ending today")
    func streakCountsConsecutiveDays() async throws {
        let context = try TestSupport.makeInMemoryContext()
        let assignment = insertAssignment(into: context, days: [])

        insertCompletion(into: context, assignment: assignment, day: TestSupport.dayStart(offsetDays: 0))
        insertCompletion(into: context, assignment: assignment, day: TestSupport.dayStart(offsetDays: -1))
        insertCompletion(into: context, assignment: assignment, day: TestSupport.dayStart(offsetDays: -2))

        let vm = ScheduleViewModel()
        await vm.refresh(context: context, allAssignments: [assignment], selectedDate: Date(), exposures: [], activationTasks: [])

        #expect(vm.weekProgress.streakDays == 3)
    }

    @Test("Streak breaks on a missing day")
    func streakBreaksOnGap() async throws {
        let context = try TestSupport.makeInMemoryContext()
        let assignment = insertAssignment(into: context, days: [])

        // Today and two days ago, but NOT yesterday → streak should be just today.
        insertCompletion(into: context, assignment: assignment, day: TestSupport.dayStart(offsetDays: 0))
        insertCompletion(into: context, assignment: assignment, day: TestSupport.dayStart(offsetDays: -2))

        let vm = ScheduleViewModel()
        await vm.refresh(context: context, allAssignments: [assignment], selectedDate: Date(), exposures: [], activationTasks: [])

        #expect(vm.weekProgress.streakDays == 1)
    }

    @Test("No completions yields an empty progress")
    func emptyProgress() async throws {
        let context = try TestSupport.makeInMemoryContext()
        let vm = ScheduleViewModel()

        await vm.refresh(context: context, allAssignments: [], selectedDate: Date(), exposures: [], activationTasks: [])

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
        insertCompletion(into: context, assignment: assignment, day: TestSupport.dayStart(offsetDays: 0))
        // One breathing session today.
        let breathing = BreathingSessionResult(performedAt: TestSupport.midday(), duration: 120, patternType: .box)
        context.insert(breathing)
        try context.save()

        let vm = ScheduleViewModel()
        await vm.refresh(context: context, allAssignments: [assignment], selectedDate: Date(), exposures: [], activationTasks: [])

        // completedThisWeek = all sessions + manual completions in the week.
        #expect(vm.weekProgress.plannedDoneThisWeek == 1)
        #expect(vm.weekProgress.completedThisWeek == 2)
    }
}
