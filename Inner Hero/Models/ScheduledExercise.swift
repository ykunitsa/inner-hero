import Foundation

/// Which exercise a schedule entry points at (spec §1.10: the shared layer is
/// scheduling and logging).
///
/// This enum is an **identifier and nothing else**. Principle 1.10 exists because
/// the previous version died of a shared "exercise template" — so the boundary is
/// hard: a rawValue, a title, a glyph. No `beforeView`, no `steps`, no `var flow`.
/// Which screen to open stays a `switch` at the call site, the way `ExercisesView`
/// and `HistoryView` already do it. A `some View` inside this enum is the warning
/// sign that the template is growing back.
///
/// Lives in its own file, apart from `ScheduleItem`, because the widget extension
/// needs the identifier and must not compile a `@Model` — and therefore the store's
/// schema — into itself (§11.7).
nonisolated enum ScheduledExercise: String, CaseIterable, Identifiable {
    // Persisted rawValues — never rename (CLAUDE.md).
    case exposure
    case breathing
    case relaxation
    case activation

    var id: String { rawValue }

    /// The same titles the launcher uses (spec §2.2) — one vocabulary for one
    /// exercise, so a schedule row, its tile and its widget never disagree.
    var title: String {
        switch self {
        case .exposure: String(localized: "Exposures")
        case .breathing: String(localized: "Breathing")
        case .relaxation: String(localized: "Relaxation")
        case .activation: String(localized: "Behavioral Activation")
        }
    }

    var icon: String {
        switch self {
        case .exposure: "leaf"
        case .breathing: "wind"
        case .relaxation: "figure.mind.and.body"
        case .activation: "figure.walk"
        }
    }

    /// The corrective phrase shown while `sessions == 0` (spec §1.7, §2.2).
    ///
    /// Kept next to the identifier rather than inside `ExercisesView` because the
    /// widgets show the same phrase at the same moment: the launcher tile and the
    /// home-screen tile are one statement about one exercise, and two copies of it
    /// would drift.
    var correctivePhrase: String {
        switch self {
        // The exercise's success criterion, not marketing.
        case .exposure: String(localized: "Success is staying, not calming down")
        // Breathing is applied relaxation — a skill trained on a schedule, not
        // something reached for when the anxiety is already peaking.
        case .breathing: String(localized: "Training, not first aid")
        // In PMR the release phase is the skill; tensing is only there to make the
        // contrast findable.
        case .relaxation: String(localized: "Letting go is the part you train")
        // BA inverts the order people expect — you do not wait to feel like it, the
        // feeling follows the doing.
        case .activation: String(localized: "Action comes before the wish")
        }
    }
}
