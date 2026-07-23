//
//  ExerciseStatusTests.swift
//  Inner HeroTests
//
//  Coverage for the launcher subtitles (spec §2.2) and the `sessions == 0`
//  rule behind them (§1.7).
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

/// A fixed clock. Every relative-day assertion is anchored here rather than to
/// `Date()`, so the suite behaves the same at 23:59 as at noon.
private let calendar = Calendar(identifier: .gregorian)
private let now = DateComponents(
    calendar: calendar, year: 2026, month: 7, day: 22, hour: 12
).date!

private func daysAgo(_ days: Int) -> Date {
    calendar.date(byAdding: .day, value: -days, to: now)!
}

// MARK: - The sessions == 0 boundary

@Suite("Exercise status · the sessions == 0 rule")
@MainActor
struct ExerciseStatusEmptyTests {

    @Test("With no sessions every exercise returns nil, so the tile keeps its corrective phrase")
    func emptyReturnsNil() {
        #expect(ExerciseStatus.exposure([], now: now, calendar: calendar) == nil)
        #expect(ExerciseStatus.breathing([]) == nil)
        #expect(ExerciseStatus.pmr([], now: now, calendar: calendar) == nil)
        #expect(ExerciseStatus.activation([], now: now, calendar: calendar) == nil)
    }

    @Test("One session is enough to switch a tile over to state")
    func oneSessionFlipsTheRule() throws {
        let context = try makeContext()
        let entry = BreathingSessionEntry(
            createdAt: now, pattern: .box, plannedDurationSeconds: 600
        )
        context.insert(entry)

        #expect(ExerciseStatus.breathing([entry]) != nil)
    }
}

// MARK: - Relative day

@Suite("Exercise status · relative day")
struct RelativeDayTests {

    @Test("Same day reads as today")
    func today() {
        let morning = calendar.date(byAdding: .hour, value: -6, to: now)!
        #expect(ExerciseStatus.relativeDay(morning, now: now, calendar: calendar)
                == String(localized: "today"))
    }

    @Test("The previous calendar day reads as yesterday, even 25 hours back")
    func yesterday() {
        #expect(ExerciseStatus.relativeDay(daysAgo(1), now: now, calendar: calendar)
                == String(localized: "yesterday"))
    }

    @Test("Two to six days back names the weekday")
    func weekdayWindow() {
        // 2026-07-22 is a Wednesday; three days back is the Sunday.
        let result = ExerciseStatus.relativeDay(daysAgo(3), now: now, calendar: calendar)
        #expect(result != String(localized: "today"))
        #expect(result != String(localized: "yesterday"))
        #expect(!result.contains("7"))  // not a numeric date
    }

    @Test("Seven days back falls through to an absolute date")
    func beyondTheWeek() {
        let result = ExerciseStatus.relativeDay(daysAgo(7), now: now, calendar: calendar)
        #expect(result.contains("15"))
    }

    @Test("A future date shows a plain date, never a countdown")
    func futureDate() {
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!
        let result = ExerciseStatus.relativeDay(tomorrow, now: now, calendar: calendar)
        #expect(result.contains("23"))
    }
}

// MARK: - Exposures

@Suite("Exercise status · exposures")
@MainActor
struct ExposureStatusTests {

    private func entry(
        _ behavior: ExposureBehavior?,
        at date: Date,
        in context: ModelContext
    ) -> ExposureLogEntry {
        let entry = ExposureLogEntry(
            createdAt: date,
            situation: "s",
            anxiety: 5,
            behavior: behavior ?? .stayed,
            safetyBehaviors: []
        )
        // A situational entry always has a behaviour; a planned one that was
        // never answered does not. `nil` models the latter.
        entry.behaviorRaw = behavior?.rawValue
        context.insert(entry)
        return entry
    }

    @Test("The fraction counts everything that is not leaving early")
    func stayedFraction() throws {
        let context = try makeContext()
        let entries = [
            entry(.stayed, at: now, in: context),
            entry(.wantedToLeaveButStayed, at: daysAgo(1), in: context),
            entry(.leftEarly, at: daysAgo(2), in: context),
        ]

        let result = try #require(ExerciseStatus.exposure(entries, now: now, calendar: calendar))

        // Wanting to leave and staying is staying — that is the exercise.
        #expect(result.contains("2"))
        #expect(result.contains("3"))
        #expect(result.contains(String(localized: "today")))
    }

    @Test("Entries with no behaviour recorded stay out of the denominator")
    func unansweredExcluded() throws {
        let context = try makeContext()
        let entries = [
            entry(.stayed, at: now, in: context),
            entry(nil, at: daysAgo(1), in: context),
        ]

        let result = try #require(ExerciseStatus.exposure(entries, now: now, calendar: calendar))

        // "1 of 1", not "1 of 2": an unanswered entry is not a failure.
        #expect(result.contains("1"))
        #expect(!result.contains("2"))
    }

    @Test("The fraction only looks at the last ten sessions")
    func rollingWindow() throws {
        let context = try makeContext()
        var entries: [ExposureLogEntry] = []
        // Ten recent stays...
        for day in 0..<10 {
            entries.append(entry(.stayed, at: daysAgo(day), in: context))
        }
        // ...and five older walk-outs that must not drag the number down.
        for day in 10..<15 {
            entries.append(entry(.leftEarly, at: daysAgo(day), in: context))
        }

        let result = try #require(ExerciseStatus.exposure(entries, now: now, calendar: calendar))

        #expect(result.contains("10"))
        #expect(!result.contains("15"))
    }

    @Test("With a date but no answered session the subtitle is just the day")
    func dateOnly() throws {
        let context = try makeContext()
        let entries = [entry(nil, at: now, in: context)]

        let result = try #require(ExerciseStatus.exposure(entries, now: now, calendar: calendar))

        #expect(result == String(localized: "today"))
    }
}

// MARK: - Breathing, PMR, BA

@Suite("Exercise status · ladder positions")
@MainActor
struct LadderSubtitleTests {

    @Test("Breathing shows the pattern and the planned step, not the actual length")
    func breathing() throws {
        let context = try makeContext()
        let old = BreathingSessionEntry(
            createdAt: daysAgo(3), pattern: .rhythmic, plannedDurationSeconds: 300
        )
        let recent = BreathingSessionEntry(
            createdAt: now, pattern: .box, plannedDurationSeconds: 600
        )
        // A session cut short must not read as a step the user never took.
        recent.actualDurationSeconds = 120
        context.insert(old)
        context.insert(recent)

        let result = try #require(ExerciseStatus.breathing([old, recent]))

        #expect(result.contains(BreathingPattern.box.title))
        #expect(result.contains("10"))
        #expect(!result.contains(BreathingPattern.rhythmic.title))
    }

    @Test("PMR shows the step and when it was")
    func pmr() throws {
        let context = try makeContext()
        let entry = PMRSessionEntry(
            createdAt: now, step: .sevenGroups, plannedDurationSeconds: 900
        )
        context.insert(entry)

        let result = try #require(ExerciseStatus.pmr([entry], now: now, calendar: calendar))

        #expect(result.contains(PMRStep.sevenGroups.title))
        #expect(result.contains(String(localized: "today")))
    }

    @Test("BA shows the effort basket and when it was")
    func activation() throws {
        let context = try makeContext()
        let entry = BALogEntry(
            createdAt: daysAgo(1),
            activityID: nil,
            activityTitle: "Walk",
            effort: .easy,
            energy: .almostNone,
            forecast: nil
        )
        context.insert(entry)

        let result = try #require(ExerciseStatus.activation([entry], now: now, calendar: calendar))

        #expect(result.contains(BAEffort.easy.title))
        #expect(result.contains(String(localized: "yesterday")))
    }

    @Test("The newest entry wins regardless of array order")
    func newestWins() throws {
        let context = try makeContext()
        let older = PMRSessionEntry(
            createdAt: daysAgo(5), step: .sixteenGroups, plannedDurationSeconds: 1500
        )
        let newer = PMRSessionEntry(
            createdAt: now, step: .fourGroups, plannedDurationSeconds: 600
        )
        context.insert(older)
        context.insert(newer)

        // Deliberately unsorted — the view's @Query has no sort descriptor.
        let result = try #require(ExerciseStatus.pmr([older, newer], now: now, calendar: calendar))

        #expect(result.contains(PMRStep.fourGroups.title))
    }
}

// MARK: - Article ids

@Suite("Exercise status · article doors")
@MainActor
struct ExerciseArticleTests {

    @Test("Every door id resolves against the shipped articles")
    func idsResolve() {
        let all = ArticlesStore().allArticles
        let ids = [
            ExerciseArticle.exposure,
            ExerciseArticle.breathing,
            ExerciseArticle.relaxation,
            ExerciseArticle.activation,
        ]

        for id in ids {
            #expect(all.contains { $0.id == id }, "No article for door id \(id)")
        }
    }
}
