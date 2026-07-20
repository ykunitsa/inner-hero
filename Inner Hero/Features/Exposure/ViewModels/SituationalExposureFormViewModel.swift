import Foundation
import Observation
import SwiftData

/// Logic of the situational exposure form (spec §3, situational entry).
/// The view stays thin: all validation, chip derivation and entry assembly
/// live here.
@Observable @MainActor
final class SituationalExposureFormViewModel {

    // MARK: Form state

    var situation = ""
    var anxiety = SituationalExposureFormViewModel.defaultAnxiety
    var behavior: ExposureBehavior?
    var selectedSafetyBehaviors: Set<String> = []
    var isNothingSelected = false
    var note = ""

    /// Chips derived from past entries; filled by `configure(history:)`.
    private(set) var situationSuggestions: [String] = []
    private(set) var safetyBehaviorOptions: [String] = []

    // MARK: Constants

    /// Slider starts mid-scale: minimizes average thumb travel and avoids
    /// anchoring to either end.
    nonisolated static let defaultAnxiety = 5

    nonisolated static var defaultSafetyBehaviors: [String] {
        [
            String(localized: "Breathing"),
            String(localized: "Phone"),
            String(localized: "Distraction"),
            String(localized: "Left early"),
        ]
    }

    nonisolated static let suggestionLimit = 6
    nonisolated static let safetyChipCap = 10

    // MARK: Derived chips (pure, testable)

    /// Recent distinct situations, newest first — suggestion chips.
    nonisolated static func situationSuggestions(
        from entries: [ExposureLogEntry],
        limit: Int = suggestionLimit
    ) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        for entry in entries.sorted(by: { $0.createdAt > $1.createdAt }) {
            let text = entry.situation.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty, seen.insert(text).inserted else { continue }
            result.append(text)
            if result.count == limit { break }
        }
        return result
    }

    /// Safety-behavior chip set: defaults first, then custom chips from past
    /// entries ranked by frequency (recency breaks ties), capped so the set
    /// never grows unbounded. Rarely used custom chips drop out of display;
    /// the data in old entries is untouched.
    nonisolated static func safetyBehaviorOptions(
        history entries: [ExposureLogEntry],
        defaults: [String] = defaultSafetyBehaviors,
        cap: Int = safetyChipCap
    ) -> [String] {
        let defaultSet = Set(defaults)
        var frequency: [String: Int] = [:]
        var lastUsed: [String: Date] = [:]
        for entry in entries {
            for chip in entry.safetyBehaviors {
                let text = chip.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !text.isEmpty, !defaultSet.contains(text) else { continue }
                frequency[text, default: 0] += 1
                lastUsed[text] = max(lastUsed[text] ?? .distantPast, entry.createdAt)
            }
        }
        let custom = frequency.keys.sorted {
            if frequency[$0] != frequency[$1] { return frequency[$0]! > frequency[$1]! }
            return lastUsed[$0]! > lastUsed[$1]!
        }
        return Array((defaults + custom).prefix(max(cap, defaults.count)))
    }

    // MARK: Configuration

    func configure(history entries: [ExposureLogEntry]) {
        situationSuggestions = Self.situationSuggestions(from: entries)
        safetyBehaviorOptions = Self.safetyBehaviorOptions(history: entries)
    }

    // MARK: Intents

    func applySuggestion(_ text: String) {
        situation = text
    }

    /// "Nothing" is mutually exclusive with concrete behaviors.
    func toggleNothing() {
        isNothingSelected.toggle()
        if isNothingSelected {
            selectedSafetyBehaviors.removeAll()
        }
    }

    func toggleSafetyBehavior(_ text: String) {
        if selectedSafetyBehaviors.contains(text) {
            selectedSafetyBehaviors.remove(text)
        } else {
            selectedSafetyBehaviors.insert(text)
            isNothingSelected = false
        }
    }

    /// Adds a user-authored chip and selects it. Returns false for blank or
    /// duplicate input (duplicates are selected instead of re-added).
    @discardableResult
    func addCustomSafetyBehavior(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        if !safetyBehaviorOptions.contains(trimmed) {
            safetyBehaviorOptions.append(trimmed)
        }
        selectedSafetyBehaviors.insert(trimmed)
        isNothingSelected = false
        return true
    }

    // MARK: Validation & saving

    var trimmedSituation: String {
        situation.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Safety question must be answered explicitly — otherwise "skipped" and
    /// "nothing" are indistinguishable and the future "without safety
    /// behaviors" share lies.
    var isSafetyAnswered: Bool {
        isNothingSelected || !selectedSafetyBehaviors.isEmpty
    }

    var canSave: Bool {
        !trimmedSituation.isEmpty && behavior != nil && isSafetyAnswered
    }

    /// Anything worth protecting from an accidental swipe-down.
    var hasDraft: Bool {
        !trimmedSituation.isEmpty
            || behavior != nil
            || isSafetyAnswered
            || !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || anxiety != Self.defaultAnxiety
    }

    func makeEntry(now: Date = Date()) -> ExposureLogEntry? {
        guard canSave, let behavior else { return nil }
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        // Keep the on-screen chip order in the stored array.
        let safety = isNothingSelected
            ? []
            : safetyBehaviorOptions.filter(selectedSafetyBehaviors.contains)
        return ExposureLogEntry(
            createdAt: now,
            situation: trimmedSituation,
            anxiety: anxiety,
            behavior: behavior,
            safetyBehaviors: safety,
            note: trimmedNote.isEmpty ? nil : trimmedNote
        )
    }

    func save(in context: ModelContext, now: Date = Date()) throws {
        guard let entry = makeEntry(now: now) else { return }
        context.insert(entry)
        try context.save()
    }
}
