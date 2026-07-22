//
//  BAFlowTests.swift
//  Inner HeroTests
//
//  Coverage for the BA flow view model (spec §6): what is written and when, what
//  deliberately leaves no trace, and that every exit keeps what was recorded.
//

import Foundation
import SwiftData
import Testing
@testable import Inner_Hero

// MARK: - Helpers

private func makeContext() throws -> ModelContext {
    let container = try ModelContainer(
        for: BAActivity.self, BALogEntry.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    return ModelContext(container)
}

/// A fixed origin, so every offset in these tests is exact.
private let start = Date(timeIntervalSinceReferenceDate: 1_000_000)

private func activity(_ title: String, _ effort: BAEffort) -> BAActivity {
    BAActivity(title: title, effort: effort, createdAt: start)
}

/// Deterministic draw, so "which card came up" is never the thing under test.
@MainActor
private func makeViewModel() -> BAFlowViewModel {
    BAFlowViewModel(pick: { $0.first })
}

// MARK: - Picking

@Suite("BA flow: picking a card")
@MainActor
struct BAPickerTests {

    @Test("The card comes from the basket the energy answer selected")
    func picksFromTheRightBasket() {
        let activities = [activity("Dishes", .easy), activity("Gym", .hard)]
        let viewModel = makeViewModel()

        viewModel.answerEnergy(.enough, activities: activities)

        #expect(viewModel.basket == .hard)
        #expect(viewModel.candidate?.title == "Gym")
    }

    @Test("Reshuffling does not hand back the same card")
    func reshuffleAvoidsRepeat() {
        let activities = [activity("Balcony", .easy), activity("Dishes", .easy)]
        let viewModel = makeViewModel()

        viewModel.answerEnergy(.almostNone, activities: activities)
        #expect(viewModel.candidate?.title == "Balcony")

        viewModel.shuffleCandidate(from: activities)
        #expect(viewModel.candidate?.title == "Dishes")
    }

    @Test("With one activity in the basket there is nothing to reshuffle to")
    func singleActivityStays() {
        let activities = [activity("Balcony", .easy)]
        let viewModel = makeViewModel()

        viewModel.answerEnergy(.almostNone, activities: activities)
        viewModel.shuffleCandidate(from: activities)

        #expect(viewModel.candidate?.title == "Balcony")
        // The "Something else" button is not offered at all in this state.
        #expect(viewModel.canShuffle == false)
    }

    @Test("An empty basket yields no card")
    func emptyBasket() {
        let viewModel = makeViewModel()

        viewModel.answerEnergy(.enough, activities: [activity("Dishes", .easy)])

        #expect(viewModel.candidate == nil)
        #expect(viewModel.hasCandidate == false)
    }

    @Test("Going back to the question clears the card and the forecast")
    func returnToEnergyClears() {
        let activities = [activity("Dishes", .easy)]
        let viewModel = makeViewModel()

        viewModel.answerEnergy(.almostNone, activities: activities)
        viewModel.forecast = .maybe
        viewModel.returnToEnergy()

        #expect(viewModel.stage == .energy)
        #expect(viewModel.candidate == nil)
        #expect(viewModel.forecast == nil)
    }
}

// MARK: - Committing

@Suite("BA flow: committing")
@MainActor
struct BACommitTests {

    @Test("\"I'll go\" writes an open entry before anything happens")
    func commitInsertsOpenEntry() throws {
        let context = try makeContext()
        let activities = [activity("Walk", .medium)]
        let viewModel = makeViewModel()

        viewModel.answerEnergy(.little, activities: activities)
        viewModel.forecast = .unlikely
        try viewModel.commit(in: context, now: start)

        let entries = try context.fetch(FetchDescriptor<BALogEntry>())
        #expect(entries.count == 1)

        let entry = try #require(entries.first)
        #expect(entry.activityTitle == "Walk")
        #expect(entry.effort == .medium)
        #expect(entry.energy == .little)
        #expect(entry.forecast == .unlikely)
        #expect(entry.createdAt == start)
        // Nothing has happened in the world yet, and the record says so.
        #expect(entry.isOpen)
        #expect(entry.answeredAt == nil)
        #expect(entry.pleasure == nil)
        #expect(entry.mastery == nil)
    }

    @Test("A skipped forecast is stored as no forecast, not as a default")
    func forecastStaysOptional() throws {
        let context = try makeContext()
        let viewModel = makeViewModel()

        viewModel.answerEnergy(.almostNone, activities: [activity("Dishes", .easy)])
        try viewModel.commit(in: context, now: start)

        let entry = try #require(try context.fetch(FetchDescriptor<BALogEntry>()).first)
        #expect(entry.forecast == nil)
    }

    @Test("\"Not now\" leaves no trace")
    func notNowWritesNothing() throws {
        let context = try makeContext()
        let viewModel = makeViewModel()

        // The user answers, sees a card, sets a forecast — and walks away. Spec
        // §6: closing here writes nothing at all, energy answer included.
        viewModel.answerEnergy(.almostNone, activities: [activity("Dishes", .easy)])
        viewModel.forecast = .definitely

        #expect(try context.fetch(FetchDescriptor<BALogEntry>()).isEmpty)
    }

    @Test("Committing without a card does nothing")
    func noCandidateNoEntry() throws {
        let context = try makeContext()
        let viewModel = makeViewModel()

        viewModel.answerEnergy(.enough, activities: [])
        let entry = try viewModel.commit(in: context, now: start)

        #expect(entry == nil)
        #expect(try context.fetch(FetchDescriptor<BALogEntry>()).isEmpty)
    }
}

// MARK: - The tail

@Suite("BA flow: answering the tail")
@MainActor
struct BATailTests {

    /// The state the app is in when BA is opened with something still hanging.
    private func openEntry(in context: ModelContext) throws -> BALogEntry {
        let entry = BALogEntry(
            createdAt: start,
            activityID: nil,
            activityTitle: "Walk",
            effort: .medium,
            energy: .little,
            forecast: .unlikely
        )
        context.insert(entry)
        try context.save()
        return entry
    }

    @Test("An open activity takes precedence over the energy question")
    func openEntryOpensTheTail() throws {
        let context = try makeContext()
        let entry = try openEntry(in: context)
        let viewModel = makeViewModel()

        viewModel.configure(openEntry: entry, history: [entry])

        #expect(viewModel.stage == .tail)
        #expect(viewModel.entry?.activityTitle == "Walk")
    }

    @Test("\"Did it\" records the outcome and moves to the ratings")
    func doneMovesToAfter() throws {
        let context = try makeContext()
        let entry = try openEntry(in: context)
        let viewModel = makeViewModel()
        viewModel.configure(openEntry: entry, history: [entry])

        try viewModel.answer(.done, in: context, now: start + 3600)

        #expect(entry.outcome == .done)
        #expect(entry.answeredAt == start + 3600)
        #expect(entry.isOpen == false)
        #expect(viewModel.stage == .after)
    }

    @Test("\"Couldn't\" is recorded as data, with no ratings asked")
    func couldNotIsData() throws {
        let context = try makeContext()
        let entry = try openEntry(in: context)
        let viewModel = makeViewModel()
        viewModel.configure(openEntry: entry, history: [entry])

        try viewModel.answer(.couldNot, in: context, now: start + 3600)

        #expect(entry.outcome == .couldNot)
        #expect(entry.isOpen == false)
        // No sliders on this path — scoring something that did not happen is not
        // a question worth asking (principle 1.5).
        #expect(entry.pleasure == nil)
        #expect(entry.mastery == nil)
        #expect(viewModel.stage != .after)
    }

    @Test("An already answered activity cannot be answered twice")
    func answeringIsIdempotent() throws {
        let context = try makeContext()
        let entry = try openEntry(in: context)
        let viewModel = makeViewModel()
        viewModel.configure(openEntry: entry, history: [entry])

        try viewModel.answer(.done, in: context, now: start + 3600)
        try viewModel.answer(.couldNot, in: context, now: start + 7200)

        #expect(entry.outcome == .done)
        #expect(entry.answeredAt == start + 3600)
    }
}

// MARK: - Ratings

@Suite("BA flow: ratings")
@MainActor
struct BAAfterTests {

    private func answeredEntry(in context: ModelContext) throws -> BALogEntry {
        let entry = BALogEntry(
            createdAt: start,
            activityID: nil,
            activityTitle: "Walk",
            effort: .medium,
            energy: .little,
            forecast: .unlikely
        )
        context.insert(entry)
        try context.save()
        return entry
    }

    @Test("Untouched sliders save nothing")
    func untouchedSlidersSaveNil() throws {
        let context = try makeContext()
        let entry = try answeredEntry(in: context)
        let viewModel = makeViewModel()
        viewModel.configure(openEntry: entry, history: [entry])
        try viewModel.answer(.done, in: context, now: start)

        try viewModel.saveAfter(in: context)

        // A slider parked at its midpoint looks exactly like a deliberate 5.
        #expect(entry.pleasure == nil)
        #expect(entry.mastery == nil)
    }

    @Test("Touched sliders save their value")
    func touchedSlidersSave() throws {
        let context = try makeContext()
        let entry = try answeredEntry(in: context)
        let viewModel = makeViewModel()
        viewModel.configure(openEntry: entry, history: [entry])
        try viewModel.answer(.done, in: context, now: start)

        viewModel.setPleasure(6)
        viewModel.setMastery(8)
        viewModel.note = "  windy  "
        try viewModel.saveAfter(in: context)

        #expect(entry.pleasure == 6)
        #expect(entry.mastery == 8)
        #expect(entry.note == "windy")
    }

    @Test("A blank note is stored as no note")
    func blankNoteIsNil() throws {
        let context = try makeContext()
        let entry = try answeredEntry(in: context)
        let viewModel = makeViewModel()
        viewModel.configure(openEntry: entry, history: [entry])
        try viewModel.answer(.done, in: context, now: start)

        viewModel.note = "   \n "
        try viewModel.saveAfter(in: context)

        #expect(entry.note == nil)
    }

    @Test("The store nudge appears at 6 and not below")
    func refillThreshold() throws {
        let context = try makeContext()
        let entry = try answeredEntry(in: context)
        let viewModel = makeViewModel()
        viewModel.configure(openEntry: entry, history: [entry])
        try viewModel.answer(.done, in: context, now: start)

        #expect(viewModel.shouldSuggestRefill == false)

        viewModel.setPleasure(5)
        #expect(viewModel.shouldSuggestRefill == false)

        viewModel.setPleasure(6)
        #expect(viewModel.shouldSuggestRefill)
    }

    @Test("Either rating can trigger the nudge")
    func refillOnMastery() throws {
        let context = try makeContext()
        let entry = try answeredEntry(in: context)
        let viewModel = makeViewModel()
        viewModel.configure(openEntry: entry, history: [entry])
        try viewModel.answer(.done, in: context, now: start)

        viewModel.setPleasure(2)
        viewModel.setMastery(9)

        #expect(viewModel.shouldSuggestRefill)
    }

    @Test("The forecast comparison waits for a rating and never invents one")
    func forecastComparison() throws {
        let context = try makeContext()
        let entry = try answeredEntry(in: context)
        let viewModel = makeViewModel()
        viewModel.configure(openEntry: entry, history: [entry])
        try viewModel.answer(.done, in: context, now: start)

        #expect(viewModel.forecastComparison == nil)

        viewModel.setPleasure(6)
        let comparison = try #require(viewModel.forecastComparison)
        #expect(comparison.forecast == .unlikely)
        #expect(comparison.rating == 6)
    }
}

// MARK: - The "planned" line

@Suite("BA flow: when it was planned")
struct BAPlannedTextTests {

    private let calendar = Calendar(identifier: .gregorian)

    private func text(daysLater days: Int) -> String {
        BAFlowViewModel.plannedText(
            createdAt: start,
            now: start + TimeInterval(days) * 24 * 3600 + 3600,
            calendar: calendar
        )
    }

    /// Asserted as "three distinct phrasings" rather than by matching words: the
    /// strings are localized, and a test that greps for "yesterday" would pass or
    /// fail on the runner's language rather than on the logic.
    @Test("Today, yesterday and older each get their own phrasing")
    func threeBranches() {
        let today = text(daysLater: 0)
        let yesterday = text(daysLater: 1)
        let older = text(daysLater: 5)

        #expect(today != yesterday)
        #expect(yesterday != older)
        #expect(today != older)
    }

    @Test("Older tails state a date instead of counting days")
    func olderStatesADate() {
        // Never "5 days ago": an overdue number is a reproach, not information
        // (codex §8). The day-of-month is what distinguishes this branch.
        let older = text(daysLater: 5)
        let day = start.formatted(.dateTime.day())

        #expect(older.contains(day))
    }
}
