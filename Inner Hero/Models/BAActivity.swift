import Foundation
import SwiftData

// MARK: - Effort

/// The effort basket an activity belongs to (spec §6).
///
/// Deliberately **not** minutes. "Twenty minutes" is a promise about the world;
/// "easy" is a statement about what it costs *you*, and on a bad day only the
/// second one can be answered honestly.
///
/// Pleasantness and mastery are not here either: the spec is explicit that those
/// are computed from the log, never tagged by hand. A person filling the store on
/// a good day is a poor judge of what will land on a bad one.
nonisolated enum BAEffort: String, CaseIterable, Comparable {
    // Persisted rawValues — never rename (CLAUDE.md).
    case easy
    case medium
    case hard

    var title: String {
        switch self {
        case .easy: String(localized: "Easy")
        case .medium: String(localized: "Medium")
        case .hard: String(localized: "Hard")
        }
    }

    /// How long to wait before the single quiet reminder (spec §6: "одно тихое
    /// напоминание через время корзины").
    ///
    /// The spec gives no numbers. These are chosen so the reminder lands *after*
    /// the activity would plausibly be over rather than during it: a nudge that
    /// arrives mid-walk asks a question the user cannot answer yet, and teaches
    /// them to ignore the next one.
    var reminderDelay: TimeInterval {
        switch self {
        case .easy: 60 * 60
        case .medium: 3 * 60 * 60
        case .hard: 6 * 60 * 60
        }
    }

    /// Ladder order: easy is the bottom rung.
    private var rank: Int {
        switch self {
        case .easy: 0
        case .medium: 1
        case .hard: 2
        }
    }

    static func < (lhs: BAEffort, rhs: BAEffort) -> Bool {
        lhs.rank < rhs.rank
    }
}

// MARK: - Kind

/// What sort of activity this is (clinical BA: routine / necessary /
/// pleasurable).
///
/// Orthogonal to `BAEffort`: effort says how much it costs today, kind says what
/// it does for you. Clinical BA materials are explicit that a healthy week needs
/// all three, and that each difficulty level should hold some of each — a shelf
/// of nothing but chores and a shelf of nothing but treats both fail.
///
/// This is **not** the pleasantness the spec forbids tagging by hand (§6). That
/// rule is about rating *how good it was*, which only the log can answer after the
/// fact. This is a stable property of the activity itself, known when it is
/// written down.
nonisolated enum BAKind: String, CaseIterable {
    // Persisted rawValues — never rename (CLAUDE.md).
    case routine
    case necessary
    case pleasurable

    var title: String {
        switch self {
        case .routine: String(localized: "Routine")
        case .necessary: String(localized: "Necessary")
        case .pleasurable: String(localized: "Pleasant")
        }
    }

    /// Glyph only, one muted colour for all three at the call site. Three
    /// *different* colours would be three new colour meanings in a system where
    /// colour carries roles, and on a list of one's own life they would read as a
    /// verdict — the same reason the 0–10 scale is deliberately colourless.
    var glyph: String {
        switch self {
        case .routine: "repeat"
        case .necessary: "checklist"
        case .pleasurable: "heart"
        }
    }
}

// MARK: - Activity

/// One line in the activity store (spec §6).
///
/// A string, a basket and a kind. The store is filled on a good day and spent on a
/// bad one, so every field here is a question asked at the wrong moment — the
/// spec's "строка + корзина, всё" is a constraint, not a starting point.
///
/// `kind` is a deliberate third field, added past that constraint: without it the
/// shelf cannot show whether it has drifted into all-chores or all-treats, which
/// is the balance clinical BA asks the user to keep. It is affordable only
/// because the store is the *strength* door — nothing on the "Одно дело" path
/// leads here, so the cost is never paid on a bad day.
///
/// Note what is **absent**: no relationship to the log. `BALogEntry` snapshots the
/// title instead, so deleting an activity never rewrites what already happened.
@Model
final class BAActivity {
    var title: String
    var effortRaw: String
    /// Defaulted **in the declaration**, not just in `init`. A new mandatory
    /// attribute with no default cannot be migrated into an existing store —
    /// CoreData fails with "missing attribute values on mandatory destination
    /// attribute" and, because the failure repeats on the retry, the container
    /// never opens at all. Pre-release we edit models in place (CLAUDE.md), so
    /// every non-optional property added later needs a default here.
    var kindRaw: String = BAKind.routine.rawValue
    var createdAt: Date

    init(
        title: String,
        effort: BAEffort,
        kind: BAKind = .routine,
        createdAt: Date = Date()
    ) {
        self.title = title
        self.effortRaw = effort.rawValue
        self.kindRaw = kind.rawValue
        self.createdAt = createdAt
    }

    var effort: BAEffort? {
        BAEffort(rawValue: effortRaw)
    }

    var kind: BAKind? {
        BAKind(rawValue: kindRaw)
    }
}
