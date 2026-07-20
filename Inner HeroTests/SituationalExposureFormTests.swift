//
//  SituationalExposureFormTests.swift
//  Inner HeroTests
//
//  Coverage for the situational exposure form (spec §11.1): model rawValue
//  contract, form validation, chip derivation, and persistence.
//

import Foundation
import Testing
import SwiftData
@testable import Inner_Hero

// MARK: - Helpers

private func makeContext() throws -> ModelContext {
    let container = try ModelContainer(
        for: ExposureLogEntry.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    return ModelContext(container)
}

private func entry(
    daysAgo: Int,
    situation: String,
    safety: [String] = []
) -> ExposureLogEntry {
    ExposureLogEntry(
        createdAt: Date(timeIntervalSinceReferenceDate: 1_000_000)
            .addingTimeInterval(TimeInterval(-daysAgo * 86_400)),
        situation: situation,
        anxiety: 5,
        behavior: .stayed,
        safetyBehaviors: safety
    )
}

// MARK: - Model

@Suite("ExposureLogEntry model")
struct ExposureLogEntryTests {

    @Test("Behavior rawValues are a persistence contract")
    func behaviorRawValuesAreStable() {
        #expect(ExposureBehavior.stayed.rawValue == "stayed")
        #expect(ExposureBehavior.wantedToLeaveButStayed.rawValue == "wantedToLeaveButStayed")
        #expect(ExposureBehavior.leftEarly.rawValue == "leftEarly")
        #expect(ExposureBehavior.allCases.count == 3)
    }

    @Test("Behavior round-trips through the raw storage field")
    func behaviorRoundTrips() {
        let entry = entry(daysAgo: 0, situation: "Metro")
        #expect(entry.behavior == .stayed)
        entry.behaviorRaw = "somethingUnknown"
        #expect(entry.behavior == nil)
    }
}

// MARK: - Suggestions

@Suite("Situation suggestions")
struct SituationSuggestionTests {

    @MainActor
    @Test("Distinct, newest first, capped, blanks skipped")
    func suggestionDerivation() {
        let entries = [
            entry(daysAgo: 5, situation: "Metro ride"),
            entry(daysAgo: 1, situation: "Phone call"),
            entry(daysAgo: 3, situation: "Metro ride"),   // duplicate, older
            entry(daysAgo: 2, situation: "   "),          // blank — skipped
            entry(daysAgo: 4, situation: "  Elevator  "), // trimmed
        ]
        let suggestions = SituationalExposureFormViewModel.situationSuggestions(from: entries)
        #expect(suggestions == ["Phone call", "Metro ride", "Elevator"])
    }

    @MainActor
    @Test("Limit is applied")
    func suggestionLimit() {
        let entries = (0..<10).map { entry(daysAgo: $0, situation: "Situation \($0)") }
        let suggestions = SituationalExposureFormViewModel.situationSuggestions(from: entries, limit: 6)
        #expect(suggestions.count == 6)
        #expect(suggestions.first == "Situation 0")
    }
}

// MARK: - Safety chip options

@Suite("Safety behavior chips")
struct SafetyChipOptionTests {

    @MainActor
    @Test("Defaults first, custom ranked by frequency, capped")
    func chipDerivation() {
        let defaults = ["Breathing", "Phone"]
        let entries = [
            entry(daysAgo: 1, situation: "a", safety: ["Water", "Music"]),
            entry(daysAgo: 2, situation: "b", safety: ["Water"]),
            entry(daysAgo: 3, situation: "c", safety: ["Breathing"]), // default — not duplicated
        ]
        let options = SituationalExposureFormViewModel.safetyBehaviorOptions(
            history: entries, defaults: defaults, cap: 3
        )
        #expect(options == ["Breathing", "Phone", "Water"])
    }

    @MainActor
    @Test("Recency breaks frequency ties")
    func recencyBreaksTies() {
        let entries = [
            entry(daysAgo: 1, situation: "a", safety: ["Newer"]),
            entry(daysAgo: 5, situation: "b", safety: ["Older"]),
        ]
        let options = SituationalExposureFormViewModel.safetyBehaviorOptions(
            history: entries, defaults: [], cap: 10
        )
        #expect(options == ["Newer", "Older"])
    }
}

// MARK: - Form view model

@MainActor
@Suite("Situational exposure form")
struct SituationalExposureFormViewModelTests {

    private func filledModel() -> SituationalExposureFormViewModel {
        let model = SituationalExposureFormViewModel()
        model.situation = "  Metro ride  "
        model.behavior = .wantedToLeaveButStayed
        model.isNothingSelected = true
        return model
    }

    @Test("Save requires situation, behavior and an explicit safety answer")
    func validation() {
        let model = SituationalExposureFormViewModel()
        #expect(!model.canSave)

        model.situation = "Metro"
        #expect(!model.canSave)

        model.behavior = .stayed
        #expect(!model.canSave) // safety question not answered yet

        model.toggleNothing()
        #expect(model.canSave)

        model.situation = "   "
        #expect(!model.canSave)
    }

    @Test("'Nothing' and concrete chips are mutually exclusive")
    func nothingIsExclusive() {
        let model = SituationalExposureFormViewModel()
        model.toggleSafetyBehavior("Phone")
        model.toggleSafetyBehavior("Breathing")
        #expect(model.selectedSafetyBehaviors == ["Phone", "Breathing"])

        model.toggleNothing()
        #expect(model.isNothingSelected)
        #expect(model.selectedSafetyBehaviors.isEmpty)

        model.toggleSafetyBehavior("Phone")
        #expect(!model.isNothingSelected)
        #expect(model.selectedSafetyBehaviors == ["Phone"])
    }

    @Test("Custom chip is added once, selected, and rejects blanks")
    func customChips() {
        let model = SituationalExposureFormViewModel()
        model.configure(history: [])

        #expect(!model.addCustomSafetyBehavior("   "))
        #expect(model.addCustomSafetyBehavior("  Water  "))
        #expect(model.safetyBehaviorOptions.contains("Water"))
        #expect(model.selectedSafetyBehaviors.contains("Water"))

        let countBefore = model.safetyBehaviorOptions.count
        #expect(model.addCustomSafetyBehavior("Water"))
        #expect(model.safetyBehaviorOptions.count == countBefore)
    }

    @Test("Entry carries trimmed fields; 'nothing' stores an empty array")
    func entryAssembly() {
        let model = filledModel()
        model.note = "   "
        let now = Date(timeIntervalSinceReferenceDate: 42)

        let entry = try? #require(model.makeEntry(now: now))
        #expect(entry?.createdAt == now)
        #expect(entry?.situation == "Metro ride")
        #expect(entry?.anxiety == SituationalExposureFormViewModel.defaultAnxiety)
        #expect(entry?.behavior == .wantedToLeaveButStayed)
        #expect(entry?.safetyBehaviors == [])
        #expect(entry?.note == nil)
    }

    @Test("Selected chips are stored in on-screen order")
    func chipOrderPreserved() {
        let model = filledModel()
        model.configure(history: [])
        model.toggleSafetyBehavior(String(localized: "Phone"))
        model.toggleSafetyBehavior(String(localized: "Breathing"))

        let entry = model.makeEntry(now: .now)
        #expect(entry?.safetyBehaviors == [
            String(localized: "Breathing"),
            String(localized: "Phone"),
        ])
    }

    @Test("Draft detection guards the discard dialog")
    func draftDetection() {
        let model = SituationalExposureFormViewModel()
        #expect(!model.hasDraft)

        model.anxiety = 7
        #expect(model.hasDraft)

        model.anxiety = SituationalExposureFormViewModel.defaultAnxiety
        model.note = "n"
        #expect(model.hasDraft)
    }

    @Test("Save persists the entry to the store")
    func savePersists() throws {
        let context = try makeContext()
        let model = filledModel()

        try model.save(in: context)

        let saved = try context.fetch(FetchDescriptor<ExposureLogEntry>())
        #expect(saved.count == 1)
        #expect(saved.first?.situation == "Metro ride")
    }

    @Test("Save without a valid form writes nothing")
    func invalidSaveWritesNothing() throws {
        let context = try makeContext()
        let model = SituationalExposureFormViewModel()

        try model.save(in: context)

        let saved = try context.fetch(FetchDescriptor<ExposureLogEntry>())
        #expect(saved.isEmpty)
    }
}
