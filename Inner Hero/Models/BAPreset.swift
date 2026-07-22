import Foundation
import SwiftData

/// The starting activity store (spec §6: "~15 занятий на первом запуске").
///
/// The spec calls this "рыба, которую правят" — a draft to be edited. That is the
/// whole design: an empty store on first launch would ask the user to invent
/// fifteen activities before the exercise can be used once, and inventing things
/// is exactly what a person low on energy cannot do.
///
/// Baskets are assigned by how much *initiative* each one takes, not by minutes
/// or by how worthy it sounds. Anything involving another person answering is at
/// least medium, because the cost is no longer under the user's control.
nonisolated enum BAPreset {

    static let activities: [(title: String, effort: BAEffort)] = [
        (String(localized: "Step out on the balcony"), .easy),
        (String(localized: "Wash the dishes"), .easy),
        (String(localized: "Text a friend"), .easy),
        (String(localized: "Take a shower"), .easy),
        (String(localized: "Make the bed"), .easy),
        (String(localized: "Water the plants"), .easy),

        (String(localized: "Put on music and sit with it"), .medium),
        (String(localized: "Cook a meal"), .medium),
        (String(localized: "Go for a walk"), .medium),
        (String(localized: "Tidy the desk"), .medium),
        (String(localized: "Go to the shop"), .medium),
        (String(localized: "Do the laundry"), .medium),

        (String(localized: "Call someone close"), .hard),
        (String(localized: "Go to the gym"), .hard),
        (String(localized: "Meet a friend"), .hard),
    ]

    /// Seeds the store once, ever.
    ///
    /// Guarded by a flag rather than by "is the store empty": a user who deletes
    /// every preset line has made a decision, and re-seeding on the next launch
    /// would quietly overrule it. The flag records a one-time data migration, not
    /// anything about what the user has seen — the `sessions == 0` rule
    /// (principle 1.7) still runs off the log count alone.
    @MainActor
    static func seedIfNeeded(in context: ModelContext, defaults: UserDefaults = .standard) {
        guard !defaults.bool(forKey: AppStorageKeys.hasSeededBAPreset) else { return }

        for activity in activities {
            context.insert(BAActivity(title: activity.title, effort: activity.effort))
        }
        // The flag is only set if the write actually landed: a failed save must
        // leave the app able to try again, not with an empty store it believes is
        // seeded.
        do {
            try context.save()
            defaults.set(true, forKey: AppStorageKeys.hasSeededBAPreset)
        } catch {
            context.rollback()
        }
    }
}
