//
//  BehavioralActivationCrashRecoveryTests.swift
//  Inner HeroTests
//
//  Swift Testing coverage for BehavioralActivationViewModel state that the existing
//  XCTest suite doesn't touch: crash-recovery (checkInterruptedSession, which writes
//  to the context) and filter reset / active-filter state.
//
//  Time is injected (fixed clock), so the 24h staleness threshold is exercised
//  deterministically.
//

import Foundation
import Testing
import SwiftData
@testable import Inner_Hero

@MainActor
@Suite("BehavioralActivationViewModel — crash recovery & filters")
struct BehavioralActivationCrashRecoveryTests {

    /// Fixed "now" used by the view model under test.
    private let fixedNow = TestSupport.date(year: 2026, month: 6, day: 22, hour: 14)

    private func makeViewModel() -> BehavioralActivationViewModel {
        BehavioralActivationViewModel(now: { self.fixedNow }, calendar: TestSupport.fixedCalendar)
    }

    /// Inserts an in-progress session started `hoursAgo` hours before the fixed now.
    @discardableResult
    private func insertInProgress(
        into context: ModelContext,
        hoursAgo: Double
    ) -> ActivationSession {
        let startedAt = fixedNow.addingTimeInterval(-hoursAgo * 3600)
        let session = ActivationSession(
            activityId: UUID(),
            status: .inProgress,
            startedAt: startedAt
        )
        context.insert(session)
        try? context.save()
        return session
    }

    // MARK: - checkInterruptedSession

    @Test("A fresh in-progress session is offered for resume")
    func freshSessionOffered() throws {
        let context = try TestSupport.makeInMemoryContext()
        let session = insertInProgress(into: context, hoursAgo: 1)
        let vm = makeViewModel()

        vm.checkInterruptedSession([session], context: context)

        #expect(vm.interruptedSession?.id == session.id)
        #expect(vm.showingCrashRecovery)
        #expect(session.status == .inProgress, "Fresh session must not be abandoned")
    }

    @Test("A stale in-progress session is auto-abandoned, not offered")
    func staleSessionAbandoned() throws {
        let context = try TestSupport.makeInMemoryContext()
        let session = insertInProgress(into: context, hoursAgo: 25) // > 24h threshold
        let vm = makeViewModel()

        vm.checkInterruptedSession([session], context: context)

        #expect(vm.interruptedSession == nil)
        #expect(!vm.showingCrashRecovery)
        #expect(session.status == .abandoned)

        // Persisted to the store.
        let abandoned = try context.fetch(
            FetchDescriptor<ActivationSession>(
                predicate: #Predicate { $0.statusRaw == "abandoned" }
            )
        )
        #expect(abandoned.count == 1)
    }

    @Test("No in-progress session leaves state untouched")
    func noInProgressSession() throws {
        let context = try TestSupport.makeInMemoryContext()
        let planned = ActivationSession(activityId: UUID(), status: .planned)
        context.insert(planned)
        try context.save()
        let vm = makeViewModel()

        vm.checkInterruptedSession([planned], context: context)

        #expect(vm.interruptedSession == nil)
        #expect(!vm.showingCrashRecovery)
    }

    @Test("An already-set interrupted session is not overwritten")
    func guardAgainstReshowing() throws {
        let context = try TestSupport.makeInMemoryContext()
        let first = insertInProgress(into: context, hoursAgo: 1)
        let second = insertInProgress(into: context, hoursAgo: 2)
        let vm = makeViewModel()

        vm.checkInterruptedSession([first], context: context)
        let captured = vm.interruptedSession?.id

        // A second call (e.g. another view appears) must not replace the pending session.
        vm.checkInterruptedSession([second, first], context: context)

        #expect(vm.interruptedSession?.id == captured)
    }

    // MARK: - Filters

    @Test("resetFilters clears every filter and the search text")
    func resetFiltersClearsEverything() {
        let vm = makeViewModel()
        vm.filterCategoryIds = [UUID()]
        vm.filterPleasure = true
        vm.filterMastery = true
        vm.filterEffortLevels = [.high]
        vm.searchText = "walk"

        vm.resetFilters()

        #expect(vm.filterCategoryIds.isEmpty)
        #expect(!vm.filterPleasure)
        #expect(!vm.filterMastery)
        #expect(vm.filterEffortLevels.isEmpty)
        #expect(vm.searchText.isEmpty)
        #expect(!vm.hasActiveFilters)
    }

    @Test("hasActiveFilters ignores search text but reflects real filters")
    func hasActiveFiltersSemantics() {
        let vm = makeViewModel()
        #expect(!vm.hasActiveFilters)

        // Search text alone is not an "active filter".
        vm.searchText = "walk"
        #expect(!vm.hasActiveFilters)

        vm.filterPleasure = true
        #expect(vm.hasActiveFilters)
    }
}
