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

// MARK: - Activity

/// One line in the activity store (spec §6).
///
/// A string and a basket, and nothing else. The store is filled on a good day and
/// spent on a bad one, so every field added here is a question asked at the wrong
/// moment — the spec's "строка + корзина, всё" is a constraint, not a starting
/// point.
///
/// Note what is **absent**: no relationship to the log. `BALogEntry` snapshots the
/// title instead, so deleting an activity never rewrites what already happened.
@Model
final class BAActivity {
    var title: String
    var effortRaw: String
    var createdAt: Date

    init(title: String, effort: BAEffort, createdAt: Date = Date()) {
        self.title = title
        self.effortRaw = effort.rawValue
        self.createdAt = createdAt
    }

    var effort: BAEffort? {
        BAEffort(rawValue: effortRaw)
    }
}
