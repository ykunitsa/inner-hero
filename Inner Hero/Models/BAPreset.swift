import Foundation
import SwiftData

/// The starting activity store (spec §6: "~15 занятий на первом запуске").
///
/// The spec calls this "рыба, которую правят" — a draft to be edited. That is the
/// whole design: an empty store on first launch would ask the user to invent
/// fifteen activities before the exercise can be used once, and inventing things
/// is exactly what a person low on energy cannot do.
///
/// **The draft is balanced, not just graded.** Clinical BA materials sort
/// activities into three kinds — routine, necessary and pleasurable — and are
/// explicit that *each* difficulty level should hold some of each, because a week
/// made only of chores and a week made only of treats both fail. The seed list
/// below therefore holds two of each kind in every basket.
///
/// The kind that matters most and is easiest to forget is **necessary**: bills,
/// appointments, paperwork. Their cost grows while they are avoided, which is
/// exactly what makes them hard to start and worth having on the shelf.
nonisolated enum BAPreset {

    static let activities: [(title: String, effort: BAEffort, kind: BAKind)] = [
        // Easy — minutes, nobody else involved, nothing to schedule.
        (String(localized: "Wash the dishes"), .easy, .routine),
        (String(localized: "Take a shower"), .easy, .routine),
        (String(localized: "Open the post"), .easy, .necessary),
        (String(localized: "Take the rubbish out"), .easy, .necessary),
        (String(localized: "Step out on the balcony"), .easy, .pleasurable),
        (String(localized: "Text a friend"), .easy, .pleasurable),

        // Medium — a chunk of the day, or a small appointment with the world.
        (String(localized: "Cook a meal"), .medium, .routine),
        (String(localized: "Do the laundry"), .medium, .routine),
        (String(localized: "Pay a bill"), .medium, .necessary),
        (String(localized: "Book an appointment"), .medium, .necessary),
        (String(localized: "Go for a walk"), .medium, .pleasurable),
        (String(localized: "Put on music and sit with it"), .medium, .pleasurable),

        // Hard — leaving the house, other people, or a task that has been growing.
        (String(localized: "Go to the gym"), .hard, .routine),
        (String(localized: "Clean one room properly"), .hard, .routine),
        (String(localized: "Do the weekly food shop"), .hard, .necessary),
        (String(localized: "Sort out the paperwork"), .hard, .necessary),
        (String(localized: "Meet a friend"), .hard, .pleasurable),
        (String(localized: "Call someone close"), .hard, .pleasurable),
    ]

    /// Seeds the store once, ever.
    ///
    /// Guarded by a flag rather than by "is the store empty": a user who deletes
    /// every preset line has made a decision, and re-seeding on the next launch
    /// would quietly overrule it. The flag records a one-time data migration, not
    /// anything about what the user has seen — the `sessions == 0` rule
    /// (principle 1.7) still runs off the log count alone.
    ///
    /// It is cleared whenever the store itself is deleted (`StoreBootstrap`),
    /// because a flag describing the contents of a store must not outlive it.
    @MainActor
    static func seedIfNeeded(in context: ModelContext, defaults: UserDefaults = .standard) {
        guard !defaults.bool(forKey: AppStorageKeys.hasSeededBAPreset) else { return }

        for activity in activities {
            context.insert(
                BAActivity(
                    title: activity.title,
                    effort: activity.effort,
                    kind: activity.kind
                )
            )
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
