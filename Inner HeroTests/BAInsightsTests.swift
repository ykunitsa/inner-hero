//
//  BAInsightsTests.swift
//  Inner HeroTests
//
//  Coverage for "Что работает" (spec §6): the forecast-vs-outcome comparison,
//  the insight threshold, and the closing line.
//

import Foundation
import SwiftData
import Testing
@testable import Inner_Hero

private func makeContext() throws -> ModelContext {
    let container = try ModelContainer(
        for: BAActivity.self, BALogEntry.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    return ModelContext(container)
}

private let calendar = Calendar(identifier: .gregorian)
private let now = DateComponents(
    calendar: calendar, year: 2026, month: 7, day: 22, hour: 12
).date!

@MainActor
private func entry(
    _ title: String,
    forecast: BAForecast?,
    outcome: BAOutcome?,
    pleasure: Int?,
    activityID: UUID? = nil,
    in context: ModelContext
) -> BALogEntry {
    let entry = BALogEntry(
        createdAt: now,
        activityID: activityID,
        activityTitle: title,
        effort: .easy,
        energy: .almostNone,
        forecast: forecast
    )
    entry.outcomeRaw = outcome?.rawValue
    entry.pleasure = pleasure
    context.insert(entry)
    return entry
}

// MARK: - Comparison

@Suite("What works · forecast comparison")
@MainActor
struct BAInsightComparisonTests {

    @Test("Beating the forecast means clearly better, not a rounding artefact")
    func expectationBands() {
        // "Maybe" promises a 6; a 6 is the forecast coming true, not beating it.
        #expect(BAInsights.expectedPleasure(.maybe) == 6)
        #expect(BAInsights.expectedPleasure(.notAtAll) < BAInsights.expectedPleasure(.unlikely))
        #expect(BAInsights.expectedPleasure(.unlikely) < BAInsights.expectedPleasure(.maybe))
        #expect(BAInsights.expectedPleasure(.maybe) < BAInsights.expectedPleasure(.definitely))
    }

    @Test("A rating equal to the forecast does not count as better")
    func equalIsNotBetter() throws {
        let context = try makeContext()
        let entries = [
            entry("Walk", forecast: .maybe, outcome: .done, pleasure: 6, in: context),
            entry("Walk", forecast: .maybe, outcome: .done, pleasure: 7, in: context),
        ]

        let rows = BAInsights.rows(entries)

        #expect(rows.first?.rated == 2)
        #expect(rows.first?.beatForecast == 1)
    }

    @Test("Entries with no forecast are excluded — there is nothing to beat")
    func noForecastExcluded() throws {
        let context = try makeContext()
        let entries = [
            entry("Walk", forecast: nil, outcome: .done, pleasure: 9, in: context),
            entry("Walk", forecast: .unlikely, outcome: .done, pleasure: 9, in: context),
        ]

        let rows = BAInsights.rows(entries)

        #expect(rows.first?.rated == 1)
    }

    @Test("An activity that couldn't be done is not rated against its forecast")
    func couldNotExcluded() throws {
        let context = try makeContext()
        let entries = [
            entry("Walk", forecast: .unlikely, outcome: .couldNot, pleasure: nil, in: context),
            entry("Walk", forecast: .unlikely, outcome: .done, pleasure: 8, in: context),
        ]

        let rows = BAInsights.rows(entries)

        #expect(rows.first?.rated == 1)
        #expect(rows.first?.beatForecast == 1)
    }

    @Test("An open activity contributes nothing yet")
    func openExcluded() throws {
        let context = try makeContext()
        let entries = [entry("Walk", forecast: .maybe, outcome: nil, pleasure: nil, in: context)]

        #expect(BAInsights.rows(entries).isEmpty)
        #expect(BAInsights.summary(BAInsights.rows(entries)) == nil)
    }
}

// MARK: - Grouping

@Suite("What works · grouping")
@MainActor
struct BAInsightGroupingTests {

    @Test("Entries group by store row, so a renamed activity keeps its history")
    func groupsByActivityID() throws {
        let context = try makeContext()
        let id = UUID()
        let entries = [
            entry("Walk", forecast: .unlikely, outcome: .done, pleasure: 8,
                  activityID: id, in: context),
            entry("Walk to the park", forecast: .unlikely, outcome: .done, pleasure: 9,
                  activityID: id, in: context),
        ]

        let rows = BAInsights.rows(entries)

        #expect(rows.count == 1)
        #expect(rows.first?.rated == 2)
    }

    @Test("Without a store row the title groups instead, so history is not lost")
    func fallsBackToTitle() throws {
        let context = try makeContext()
        let entries = [
            entry("Walk", forecast: .unlikely, outcome: .done, pleasure: 8, in: context),
            entry("Walk", forecast: .unlikely, outcome: .done, pleasure: 9, in: context),
            entry("Dishes", forecast: .maybe, outcome: .done, pleasure: 9, in: context),
        ]

        let rows = BAInsights.rows(entries)

        #expect(rows.count == 2)
    }

    @Test("Rows are ordered by surprise, and the order is stable")
    func stableOrder() throws {
        let context = try makeContext()
        let entries = [
            entry("Dishes", forecast: .maybe, outcome: .done, pleasure: 9, in: context),
            entry("Walk", forecast: .unlikely, outcome: .done, pleasure: 8, in: context),
            entry("Walk", forecast: .unlikely, outcome: .done, pleasure: 9, in: context),
        ]

        let first = BAInsights.rows(entries).map(\.title)
        let second = BAInsights.rows(entries.reversed()).map(\.title)

        #expect(first == ["Walk", "Dishes"])
        #expect(first == second)
    }
}

// MARK: - The insight card

@Suite("What works · the insight")
@MainActor
struct BAInsightCardTests {

    @Test("Below the minimum the app stays silent")
    func belowThreshold() throws {
        let context = try makeContext()
        var entries: [BALogEntry] = []
        for _ in 0..<(BAInsights.minimumRatings - 1) {
            entries.append(
                entry("Walk", forecast: .notAtAll, outcome: .done, pleasure: 9, in: context)
            )
        }

        let rows = BAInsights.rows(entries)

        // The table still shows the data; only the card holds its tongue.
        #expect(!rows.isEmpty)
        #expect(BAInsights.insight(rows) == nil)
    }

    @Test("A majority beating the forecast earns the card")
    func majorityEarnsCard() throws {
        let context = try makeContext()
        var entries: [BALogEntry] = []
        for _ in 0..<3 {
            entries.append(
                entry("Walk", forecast: .notAtAll, outcome: .done, pleasure: 9, in: context)
            )
        }
        entries.append(
            entry("Walk", forecast: .notAtAll, outcome: .done, pleasure: 0, in: context)
        )

        let insight = try #require(BAInsights.insight(BAInsights.rows(entries)))

        #expect(insight.title == "Walk")
        #expect(insight.beatForecast == 3)
        #expect(insight.rated == 4)
    }

    @Test("Enough ratings but no majority earns nothing")
    func noMajorityNoCard() throws {
        let context = try makeContext()
        let entries = [
            entry("Walk", forecast: .notAtAll, outcome: .done, pleasure: 9, in: context),
            entry("Walk", forecast: .notAtAll, outcome: .done, pleasure: 0, in: context),
            entry("Walk", forecast: .notAtAll, outcome: .done, pleasure: 0, in: context),
        ]

        #expect(BAInsights.insight(BAInsights.rows(entries)) == nil)
    }
}

// MARK: - The closing line

@Suite("What works · the closing line")
@MainActor
struct BAInsightSummaryTests {

    @Test("The line totals every activity")
    func totalsEverything() throws {
        let context = try makeContext()
        let entries = [
            entry("Walk", forecast: .notAtAll, outcome: .done, pleasure: 9, in: context),
            entry("Dishes", forecast: .definitely, outcome: .done, pleasure: 4, in: context),
        ]

        let summary = try #require(BAInsights.summary(BAInsights.rows(entries)))

        #expect(summary.rated == 2)
        #expect(summary.beatForecast == 1)
    }

    @Test("Nothing rated means no line at all, never a zero")
    func silentWhenEmpty() {
        #expect(BAInsights.summary([]) == nil)
    }
}
