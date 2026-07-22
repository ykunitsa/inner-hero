//
//  BAStoreTests.swift
//  Inner HeroTests
//
//  Coverage for the BA activity store (spec §6): the seeded preset and the
//  add/delete/group rules behind the "Занятия" screen.
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

/// A defaults suite of its own per test, so the seeding flag never leaks between
/// them or into the real app domain.
private func makeDefaults(_ name: String) throws -> UserDefaults {
    let defaults = try #require(UserDefaults(suiteName: "ba.tests.\(name)"))
    defaults.removePersistentDomain(forName: "ba.tests.\(name)")
    return defaults
}

// MARK: - Preset

@Suite("BA preset")
@MainActor
struct BAPresetTests {

    @Test("The store is seeded on first launch")
    func seedsOnce() throws {
        let context = try makeContext()
        let defaults = try makeDefaults(#function)

        BAPreset.seedIfNeeded(in: context, defaults: defaults)

        let activities = try context.fetch(FetchDescriptor<BAActivity>())
        #expect(activities.count == BAPreset.activities.count)
        #expect(activities.count >= 15)
    }

    @Test("Seeding does not run twice")
    func doesNotReseed() throws {
        let context = try makeContext()
        let defaults = try makeDefaults(#function)

        BAPreset.seedIfNeeded(in: context, defaults: defaults)
        BAPreset.seedIfNeeded(in: context, defaults: defaults)

        let activities = try context.fetch(FetchDescriptor<BAActivity>())
        #expect(activities.count == BAPreset.activities.count)
    }

    @Test("A store emptied by the user is not refilled")
    func deletedPresetStaysDeleted() throws {
        let context = try makeContext()
        let defaults = try makeDefaults(#function)

        BAPreset.seedIfNeeded(in: context, defaults: defaults)
        for activity in try context.fetch(FetchDescriptor<BAActivity>()) {
            context.delete(activity)
        }
        try context.save()

        // Deleting every line is a decision; re-seeding would overrule it.
        BAPreset.seedIfNeeded(in: context, defaults: defaults)

        #expect(try context.fetch(FetchDescriptor<BAActivity>()).isEmpty)
    }

    @Test("Every basket has something in it")
    func coversAllBaskets() {
        // An empty basket would mean an energy answer that leads to a dead end on
        // the very first run.
        for basket in BALadder.baskets {
            #expect(BAPreset.activities.contains { $0.effort == basket })
        }
    }
}

// MARK: - Store editing

@Suite("BA store: editing")
@MainActor
struct BAActivitiesTests {

    @Test("Adding writes the trimmed line")
    func addTrims() throws {
        let context = try makeContext()
        let viewModel = BAActivitiesViewModel()

        viewModel.draftTitle = "  Go for a walk  "
        viewModel.draftEffort = .medium
        try viewModel.add(in: context)

        let activities = try context.fetch(FetchDescriptor<BAActivity>())
        #expect(activities.count == 1)
        #expect(activities.first?.title == "Go for a walk")
        #expect(activities.first?.effort == .medium)
    }

    @Test("A blank line is not an activity")
    func blankIsRejected() throws {
        let context = try makeContext()
        let viewModel = BAActivitiesViewModel()

        viewModel.draftTitle = "   \n "
        #expect(viewModel.canAdd == false)
        try viewModel.add(in: context)

        #expect(try context.fetch(FetchDescriptor<BAActivity>()).isEmpty)
    }

    @Test("The basket is kept for the next line, the text is not")
    func draftResets() throws {
        let context = try makeContext()
        let viewModel = BAActivitiesViewModel()

        viewModel.draftTitle = "Dishes"
        viewModel.draftEffort = .hard
        try viewModel.add(in: context)

        #expect(viewModel.draftTitle.isEmpty)
        // Filling the store is a burst of several lines; re-picking the basket
        // each time is the repeated choice codex §2 removes.
        #expect(viewModel.draftEffort == .hard)
    }

    @Test("Deleting removes the line")
    func delete() throws {
        let context = try makeContext()
        let viewModel = BAActivitiesViewModel()
        let activity = BAActivity(title: "Dishes", effort: .easy)
        context.insert(activity)
        try context.save()

        try viewModel.delete(activity, in: context)

        #expect(try context.fetch(FetchDescriptor<BAActivity>()).isEmpty)
    }

    @Test("Grouping follows the ladder and skips empty baskets")
    func grouping() {
        let viewModel = BAActivitiesViewModel()
        let activities = [
            BAActivity(title: "Gym", effort: .hard),
            BAActivity(title: "Dishes", effort: .easy),
            BAActivity(title: "Balcony", effort: .easy),
        ]

        let groups = viewModel.grouped(activities)

        #expect(groups.map(\.basket) == [.easy, .hard])
        #expect(groups.first?.items.count == 2)
    }

    @Test("Deleting an activity does not rewrite what already happened")
    func historyKeepsItsSnapshot() throws {
        let context = try makeContext()
        let viewModel = BAActivitiesViewModel()
        let activity = BAActivity(title: "Walk", effort: .medium)
        context.insert(activity)
        let entry = BALogEntry(
            createdAt: Date(timeIntervalSinceReferenceDate: 0),
            activityID: nil,
            activityTitle: activity.title,
            effort: .medium,
            energy: .little,
            forecast: nil
        )
        context.insert(entry)
        try context.save()

        try viewModel.delete(activity, in: context)

        // The log snapshots the title instead of holding a relationship, so
        // editing the store never edits history.
        #expect(entry.activityTitle == "Walk")
        #expect(try context.fetch(FetchDescriptor<BALogEntry>()).count == 1)
    }
}
