//
//  SessionCompletionServiceTests.swift
//  Inner HeroTests
//
//  Covers the idempotency contract of SessionCompletionService: at most one
//  ExerciseCompletion per (assignment, day), correct uniqueKey, snapshot fields,
//  and the not-found error path.
//

import Foundation
import Testing
import SwiftData
@testable import Inner_Hero

@MainActor
@Suite("SessionCompletionService")
struct SessionCompletionServiceTests {

    /// Inserts an assignment into the context and returns it.
    private func insertAssignment(
        into context: ModelContext,
        type: ExerciseType = .breathing,
        exposureId: UUID? = nil,
        breathing: BreathingPatternType? = nil
    ) -> ExerciseAssignment {
        let assignment = ExerciseAssignment(
            exerciseType: type,
            time: TestSupport.date(year: 2026, month: 6, day: 22, hour: 9),
            exposureId: exposureId,
            breathingPatternType: breathing
        )
        context.insert(assignment)
        return assignment
    }

    private func completionCount(in context: ModelContext) throws -> Int {
        try context.fetchCount(FetchDescriptor<ExerciseCompletion>())
    }

    // MARK: - Happy path

    @Test("Creates a completion when none exists for the day")
    func createsCompletion() throws {
        let context = try TestSupport.makeInMemoryContext()
        let assignment = insertAssignment(into: context)
        let day = TestSupport.date(year: 2026, month: 6, day: 22, hour: 14)

        let completion = try SessionCompletionService.markCompletedIfNeeded(
            assignmentId: assignment.id,
            context: context,
            day: day,
            calendar: TestSupport.fixedCalendar
        )

        let created = try #require(completion, "Should create a completion on first call")
        #expect(created.assignmentId == assignment.id)
        #expect(try completionCount(in: context) == 1)
    }

    @Test("Day is normalized to start of day")
    func normalizesToStartOfDay() throws {
        let context = try TestSupport.makeInMemoryContext()
        let assignment = insertAssignment(into: context)
        let day = TestSupport.date(year: 2026, month: 6, day: 22, hour: 23, minute: 59)

        let completion = try #require(try SessionCompletionService.markCompletedIfNeeded(
            assignmentId: assignment.id,
            context: context,
            day: day,
            calendar: TestSupport.fixedCalendar
        ))

        let expectedStart = TestSupport.date(year: 2026, month: 6, day: 22)
        #expect(completion.day == expectedStart)
    }

    @Test("uniqueKey has the documented format")
    func uniqueKeyFormat() throws {
        let context = try TestSupport.makeInMemoryContext()
        let assignment = insertAssignment(into: context)
        let day = TestSupport.date(year: 2026, month: 6, day: 22, hour: 10)

        let completion = try #require(try SessionCompletionService.markCompletedIfNeeded(
            assignmentId: assignment.id,
            context: context,
            day: day,
            calendar: TestSupport.fixedCalendar
        ))

        let dayStart = TestSupport.date(year: 2026, month: 6, day: 22)
        let expectedKey = "\(assignment.id.uuidString)|\(Int(dayStart.timeIntervalSince1970))"
        #expect(completion.uniqueKey == expectedKey)
    }

    // MARK: - Idempotency

    @Test("Second call on the same day is a no-op")
    func idempotentSameDay() throws {
        let context = try TestSupport.makeInMemoryContext()
        let assignment = insertAssignment(into: context)
        let morning = TestSupport.date(year: 2026, month: 6, day: 22, hour: 8)
        let evening = TestSupport.date(year: 2026, month: 6, day: 22, hour: 20)

        let first = try SessionCompletionService.markCompletedIfNeeded(
            assignmentId: assignment.id, context: context, day: morning, calendar: TestSupport.fixedCalendar
        )
        let second = try SessionCompletionService.markCompletedIfNeeded(
            assignmentId: assignment.id, context: context, day: evening, calendar: TestSupport.fixedCalendar
        )

        #expect(first != nil, "First call creates the completion")
        #expect(second == nil, "Second call on the same day returns nil")
        #expect(try completionCount(in: context) == 1, "Only one completion persisted")
    }

    @Test("Different days create separate completions")
    func differentDays() throws {
        let context = try TestSupport.makeInMemoryContext()
        let assignment = insertAssignment(into: context)

        let day1 = TestSupport.date(year: 2026, month: 6, day: 22, hour: 9)
        let day2 = TestSupport.date(year: 2026, month: 6, day: 23, hour: 9)

        _ = try SessionCompletionService.markCompletedIfNeeded(
            assignmentId: assignment.id, context: context, day: day1, calendar: TestSupport.fixedCalendar
        )
        let second = try SessionCompletionService.markCompletedIfNeeded(
            assignmentId: assignment.id, context: context, day: day2, calendar: TestSupport.fixedCalendar
        )

        #expect(second != nil, "A new day creates a new completion")
        #expect(try completionCount(in: context) == 2)
    }

    @Test("Different assignments on the same day are independent")
    func differentAssignmentsSameDay() throws {
        let context = try TestSupport.makeInMemoryContext()
        let a = insertAssignment(into: context, type: .breathing)
        let b = insertAssignment(into: context, type: .grounding)
        let day = TestSupport.date(year: 2026, month: 6, day: 22, hour: 9)

        let first = try SessionCompletionService.markCompletedIfNeeded(
            assignmentId: a.id, context: context, day: day, calendar: TestSupport.fixedCalendar
        )
        let second = try SessionCompletionService.markCompletedIfNeeded(
            assignmentId: b.id, context: context, day: day, calendar: TestSupport.fixedCalendar
        )

        #expect(first != nil)
        #expect(second != nil)
        #expect(try completionCount(in: context) == 2)
    }

    // MARK: - Snapshot fields

    @Test("Snapshot fields are copied from the assignment")
    func snapshotFields() throws {
        let context = try TestSupport.makeInMemoryContext()
        let exposureId = UUID()
        let assignment = insertAssignment(into: context, type: .exposure, exposureId: exposureId)
        let day = TestSupport.date(year: 2026, month: 6, day: 22, hour: 9)

        let completion = try #require(try SessionCompletionService.markCompletedIfNeeded(
            assignmentId: assignment.id, context: context, day: day, calendar: TestSupport.fixedCalendar
        ))

        #expect(completion.exerciseType == .exposure)
        #expect(completion.exposureId == exposureId)
    }

    // MARK: - Error path

    @Test("Throws when the assignment does not exist")
    func throwsWhenAssignmentMissing() throws {
        let context = try TestSupport.makeInMemoryContext()
        let missingId = UUID()

        #expect(throws: SessionCompletionError.self) {
            try SessionCompletionService.markCompletedIfNeeded(
                assignmentId: missingId,
                context: context,
                day: TestSupport.date(year: 2026, month: 6, day: 22),
                calendar: TestSupport.fixedCalendar
            )
        }
        #expect(try completionCount(in: context) == 0)
    }
}
