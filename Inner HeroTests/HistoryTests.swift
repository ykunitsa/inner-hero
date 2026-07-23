//
//  HistoryTests.swift
//  Inner HeroTests
//
//  Coverage for the History tab (spec §2.3): ladder positions, the active
//  rule, exposure fractions, the merged feed, medals and export.
//

import Foundation
import SwiftData
import Testing
@testable import Inner_Hero

// MARK: - Helpers

private func makeContext() throws -> ModelContext {
    let container = try ModelContainer(
        for: ExposureLogEntry.self, BreathingSessionEntry.self,
        PMRSessionEntry.self, BAActivity.self, BALogEntry.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    return ModelContext(container)
}

private let calendar = Calendar(identifier: .gregorian)
private let now = DateComponents(
    calendar: calendar, year: 2026, month: 7, day: 22, hour: 12
).date!

private func daysAgo(_ days: Int) -> Date {
    calendar.date(byAdding: .day, value: -days, to: now)!
}

@MainActor
private func makeViewModel() -> HistoryViewModel {
    HistoryViewModel(calendar: calendar)
}

// MARK: - Ladder positions

@Suite("History · ladder positions")
@MainActor
struct LadderPositionTests {

    @Test("An exercise with no sessions has no row — not a zero")
    func absentWhenEmpty() throws {
        let context = try makeContext()
        let breathing = BreathingSessionEntry(
            createdAt: now, pattern: .box, plannedDurationSeconds: 600
        )
        context.insert(breathing)

        let positions = makeViewModel()
            .ladderPositions(breathing: [breathing], pmr: [], activation: [])

        #expect(positions.count == 1)
        #expect(positions.first?.id == "breathing")
    }

    @Test("Exposures never appear: they have columns, not a ladder")
    func noExposureRow() throws {
        let positions = makeViewModel()
            .ladderPositions(breathing: [], pmr: [], activation: [])

        #expect(positions.isEmpty)
    }

    @Test("The newest session sets the position")
    func newestWins() throws {
        let context = try makeContext()
        let old = PMRSessionEntry(
            createdAt: daysAgo(4), step: .sixteenGroups, plannedDurationSeconds: 1500
        )
        let recent = PMRSessionEntry(
            createdAt: now, step: .fourGroups, plannedDurationSeconds: 600
        )
        context.insert(old)
        context.insert(recent)

        let positions = makeViewModel()
            .ladderPositions(breathing: [], pmr: [old, recent], activation: [])

        #expect(positions.first?.position == PMRStep.fourGroups.title)
    }
}

// MARK: - Exposure statistics

@Suite("History · exposure statistics")
@MainActor
struct ExposureStatsTests {

    private func entry(
        behavior: ExposureBehavior?,
        planned: Bool = false,
        prediction: PredictionOutcome? = nil,
        safety: [String] = [],
        at date: Date,
        in context: ModelContext
    ) -> ExposureLogEntry {
        let entry = ExposureLogEntry(
            createdAt: date,
            situation: "s",
            anxiety: 5,
            behavior: behavior ?? .stayed,
            safetyBehaviors: safety
        )
        entry.behaviorRaw = behavior?.rawValue
        // `isPlanned` is derived from the presence of a confidence answer
        // (spec §3: no stored is_planned flag).
        if planned { entry.confidenceRaw = PredictionConfidence.likely.rawValue }
        entry.predictionOutcomeRaw = prediction?.rawValue
        context.insert(entry)
        return entry
    }

    @Test("Predictions are counted only on planned sessions")
    func predictionsPlannedOnly() throws {
        let context = try makeContext()
        let entries = [
            // Planned, prediction missed — counts.
            entry(behavior: .stayed, planned: true, prediction: .didNotComeTrue,
                  at: now, in: context),
            // Situational: no "before" existed, so it has no prediction to judge
            // (§1.6). A prediction outcome here would be reconstructed data.
            entry(behavior: .stayed, at: daysAgo(1), in: context),
        ]

        let stats = makeViewModel().exposureStats(entries)

        let missed = try #require(stats.predictionsMissed)
        #expect(missed.total == 1)
        #expect(missed.done == 1)
        // The other two fractions still see both entries.
        #expect(stats.stayed?.total == 2)
    }

    @Test("Wanting to leave and staying counts as staying")
    func wantedToLeaveCountsAsStayed() throws {
        let context = try makeContext()
        let entries = [
            entry(behavior: .wantedToLeaveButStayed, at: now, in: context),
            entry(behavior: .leftEarly, at: daysAgo(1), in: context),
        ]

        let stats = makeViewModel().exposureStats(entries)

        #expect(stats.stayed?.done == 1)
        #expect(stats.stayed?.total == 2)
    }

    @Test("Safety behaviours: an empty list is the clean case")
    func safetyBehaviors() throws {
        let context = try makeContext()
        let entries = [
            entry(behavior: .stayed, safety: [], at: now, in: context),
            entry(behavior: .stayed, safety: ["phone"], at: daysAgo(1), in: context),
        ]

        let stats = makeViewModel().exposureStats(entries)

        #expect(stats.withoutSafetyBehaviors?.done == 1)
        #expect(stats.withoutSafetyBehaviors?.total == 2)
    }

    @Test("A fraction with an empty denominator is nil, so the row disappears")
    func emptyDenominator() throws {
        let context = try makeContext()
        // Answered, but never planned: there is nothing to say about predictions.
        let entries = [entry(behavior: .stayed, at: now, in: context)]

        let stats = makeViewModel().exposureStats(entries)

        #expect(stats.predictionsMissed == nil)
        #expect(stats.stayed != nil)
        #expect(!stats.isEmpty)
    }

    @Test("With no exposures at all the whole block reports empty")
    func fullyEmpty() {
        let stats = makeViewModel().exposureStats([])
        #expect(stats.isEmpty)
    }

    @Test("The window matches the launcher subtitle, so the two never disagree")
    func sameWindowAsLauncher() throws {
        let context = try makeContext()
        var entries: [ExposureLogEntry] = []
        for day in 0..<ExerciseStatus.ratioWindow {
            entries.append(entry(behavior: .stayed, at: daysAgo(day), in: context))
        }
        for day in ExerciseStatus.ratioWindow..<(ExerciseStatus.ratioWindow + 5) {
            entries.append(entry(behavior: .leftEarly, at: daysAgo(day), in: context))
        }

        let stats = makeViewModel().exposureStats(entries)

        #expect(stats.stayed?.total == ExerciseStatus.ratioWindow)
        #expect(stats.stayed?.done == ExerciseStatus.ratioWindow)
    }
}

// MARK: - Feed

@Suite("History · session feed")
@MainActor
struct HistoryFeedTests {

    @Test("All four logs land in one feed, newest day first")
    func mergesAllSources() throws {
        let context = try makeContext()
        let exposure = ExposureLogEntry(
            createdAt: daysAgo(2), situation: "lift", anxiety: 7,
            behavior: .stayed, safetyBehaviors: []
        )
        let breathing = BreathingSessionEntry(
            createdAt: daysAgo(1), pattern: .box, plannedDurationSeconds: 600
        )
        let pmr = PMRSessionEntry(
            createdAt: now, step: .sevenGroups, plannedDurationSeconds: 900
        )
        let ba = BALogEntry(
            createdAt: now, activityID: nil, activityTitle: "Walk",
            effort: .easy, energy: .almostNone, forecast: nil
        )
        context.insert(exposure)
        context.insert(breathing)
        context.insert(pmr)
        context.insert(ba)

        let days = makeViewModel().feed(
            exposures: [exposure], breathing: [breathing], pmr: [pmr], activation: [ba]
        )

        #expect(days.count == 3)
        #expect(days.first?.id == calendar.startOfDay(for: now))
        #expect(days.first?.items.count == 2)
        #expect(days.map(\.id) == days.map(\.id).sorted(by: >))
    }

    @Test("Situational exposures are marked and planned ones are not")
    func situationalBadge() throws {
        let context = try makeContext()
        let situational = ExposureLogEntry(
            createdAt: now, situation: "s", anxiety: 5,
            behavior: .stayed, safetyBehaviors: []
        )
        let planned = ExposureLogEntry(
            createdAt: daysAgo(1), situation: "p", anxiety: 5,
            behavior: .stayed, safetyBehaviors: []
        )
        planned.confidenceRaw = PredictionConfidence.likely.rawValue
        context.insert(situational)
        context.insert(planned)

        let days = makeViewModel().feed(
            exposures: [situational, planned], breathing: [], pmr: [], activation: []
        )

        let items = days.flatMap(\.items)
        #expect(items.filter(\.isSituational).count == 1)
    }

    @Test("A session that ended early is stated, never hidden")
    func earlyExitIsRecorded() throws {
        let context = try makeContext()
        let entry = ExposureLogEntry(
            createdAt: now, situation: "s", anxiety: 8,
            behavior: .leftEarly, safetyBehaviors: []
        )
        context.insert(entry)

        let days = makeViewModel().feed(
            exposures: [entry], breathing: [], pmr: [], activation: []
        )

        let detail = try #require(days.first?.items.first?.detail)
        #expect(detail.contains(ExposureBehavior.leftEarly.title.lowercased()))
    }

    @Test("An open BA activity reads as open, not as a failure")
    func openActivity() throws {
        let context = try makeContext()
        let entry = BALogEntry(
            createdAt: now, activityID: nil, activityTitle: "Walk",
            effort: .easy, energy: .almostNone, forecast: nil
        )
        context.insert(entry)

        let days = makeViewModel().feed(
            exposures: [], breathing: [], pmr: [], activation: [entry]
        )

        let detail = try #require(days.first?.items.first?.detail)
        #expect(detail.contains(String(localized: "still open")))
        #expect(!detail.contains(String(localized: "couldn't")))
    }

    @Test("Empty everywhere means an empty feed, not a day with no rows")
    func emptyFeed() {
        let days = makeViewModel().feed(
            exposures: [], breathing: [], pmr: [], activation: []
        )
        #expect(days.isEmpty)
    }
}

// MARK: - Medals

@Suite("History · the medal")
@MainActor
struct HistoryMedalTests {

    @Test("A finished step earns a medal dated to the first session on it")
    func medalDate() throws {
        let context = try makeContext()
        let first = PMRSessionEntry(
            createdAt: daysAgo(5), step: .sevenGroups, plannedDurationSeconds: 900
        )
        first.actualDurationSeconds = 900
        let second = PMRSessionEntry(
            createdAt: now, step: .sevenGroups, plannedDurationSeconds: 900
        )
        second.actualDurationSeconds = 900
        context.insert(first)
        context.insert(second)

        let days = makeViewModel().feed(
            exposures: [], breathing: [], pmr: [first, second], activation: []
        )

        let medals = days.flatMap(\.items).filter { if case .medal = $0 { true } else { false } }
        #expect(medals.count == 1)
        // Dated to the day it was earned, not to the latest session.
        #expect(calendar.isDate(medals[0].date, inSameDayAs: daysAgo(5)))
    }

    @Test("A session cut short earns nothing, and is not punished either")
    func earlyExitEarnsNoMedal() throws {
        let context = try makeContext()
        let entry = PMRSessionEntry(
            createdAt: now, step: .sevenGroups, plannedDurationSeconds: 900
        )
        entry.actualDurationSeconds = 120
        context.insert(entry)

        let days = makeViewModel().feed(
            exposures: [], breathing: [], pmr: [entry], activation: []
        )

        let medals = days.flatMap(\.items).filter { if case .medal = $0 { true } else { false } }
        #expect(medals.isEmpty)
        // The session itself is still in the feed — it happened (§1.5).
        #expect(days.flatMap(\.items).count == 1)
    }
}

// MARK: - Export

@Suite("History · export")
@MainActor
struct HistoryExportTests {

    @Test("Every log type reaches the file")
    func allSourcesExported() throws {
        let context = try makeContext()
        let exposure = ExposureLogEntry(
            createdAt: now, situation: "lift", anxiety: 7,
            behavior: .stayed, safetyBehaviors: ["phone"]
        )
        let breathing = BreathingSessionEntry(
            createdAt: now, pattern: .box, plannedDurationSeconds: 600
        )
        let pmr = PMRSessionEntry(
            createdAt: now, step: .sevenGroups, plannedDurationSeconds: 900
        )
        let ba = BALogEntry(
            createdAt: now, activityID: nil, activityTitle: "Walk",
            effort: .easy, energy: .almostNone, forecast: nil
        )
        context.insert(exposure)
        context.insert(breathing)
        context.insert(pmr)
        context.insert(ba)

        let payload = HistoryExport.payload(
            exposures: [exposure], breathing: [breathing],
            relaxation: [pmr], activation: [ba], now: now
        )
        let data = try HistoryExport.data(for: payload)
        let json = try #require(String(data: data, encoding: .utf8))

        #expect(payload.exposures.count == 1)
        #expect(payload.breathing.count == 1)
        #expect(payload.relaxation.count == 1)
        #expect(payload.activation.count == 1)
        #expect(json.contains("lift"))
        #expect(json.contains("Walk"))
        // Spelled out for whoever opens the file without the spec.
        #expect(json.contains("situational"))
    }

    @Test("An empty store still produces a valid file")
    func emptyExport() throws {
        let payload = HistoryExport.payload(
            exposures: [], breathing: [], relaxation: [], activation: [], now: now
        )
        let data = try HistoryExport.data(for: payload)

        #expect(!data.isEmpty)
        #expect(try JSONSerialization.jsonObject(with: data) is [String: Any])
    }
}
