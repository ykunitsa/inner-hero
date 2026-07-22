import Foundation
import SwiftData

// MARK: - Energy

/// The answer to the one question BA asks about state (spec §6).
///
/// This is the *only* place the app asks how the user is doing, and it asks in
/// order to pick a basket — not to classify the day. The spec is explicit:
/// "Приложение НЕ определяет хороший/плохой день". Which door to walk through is
/// the human's call; this answer only decides which shelf to reach for.
nonisolated enum BAEnergy: String, CaseIterable {
    // Persisted rawValues — never rename (CLAUDE.md).
    case almostNone
    /// Spelled `little` rather than `some`: a case named `some` on a type that is
    /// routinely used as `BAEnergy?` collides with `Optional.some` at every call
    /// site. The rawValue is what's persisted, and it stays `"some"`.
    case little = "some"
    case enough

    var title: String {
        switch self {
        case .almostNone: String(localized: "Almost none")
        case .little: String(localized: "Some")
        case .enough: String(localized: "Enough")
        }
    }

    /// Energy maps one-to-one onto the effort baskets. The mapping is the whole
    /// reason the question is asked, which is also why the user is never shown a
    /// basket picker: that would be the same choice twice (principle 1.2).
    var basket: BAEffort {
        switch self {
        case .almostNone: .easy
        case .little: .medium
        case .enough: .hard
        }
    }
}

// MARK: - Forecast

/// "Как думаешь, зайдёт?" — captured **before**, one tap, never reconstructed
/// afterwards (principle 1.6).
///
/// Optional by construction: `forecastRaw` stays nil when the question is
/// skipped. A pre-seeded default would write a prediction nobody made, which is
/// the exact failure principle 1.6 exists to prevent — and §12 still lists the
/// question itself as removable if it proves to be friction.
nonisolated enum BAForecast: String, CaseIterable {
    // Persisted rawValues — never rename (CLAUDE.md).
    case definitely
    case maybe
    case unlikely
    case notAtAll

    var title: String {
        switch self {
        case .definitely: String(localized: "Definitely")
        case .maybe: String(localized: "Maybe")
        case .unlikely: String(localized: "Unlikely")
        case .notAtAll: String(localized: "Not at all")
        }
    }
}

// MARK: - Outcome

/// How the open activity was closed (spec §6).
///
/// Both cases are data. "Couldn't" is written to the log exactly like "did it" —
/// if the only way out were a cancel, failed attempts would vanish and the log
/// would quietly describe a person who always follows through (principle 1.5).
nonisolated enum BAOutcome: String, CaseIterable {
    // Persisted rawValues — never rename (CLAUDE.md).
    case done
    case couldNot
}

// MARK: - Log Entry

/// One BA activity the user committed to (spec §6).
///
/// Inserted the moment "I'll go" is tapped — before anything happens in the
/// world — like every other exercise in the app. The entry *is* the open tail:
/// while `outcomeRaw` is nil it shows up on Today and first thing inside BA, and
/// it never expires on its own.
///
/// "Not now" inserts nothing at all (spec §6: "закрывает БЕЗ следа"), so a
/// reshuffled card that never turned into a commitment leaves no record. One
/// consequence worth knowing: the energy answer is only stored alongside a
/// commitment, so the free "state graph" the spec mentions is biased toward the
/// moments that led somewhere.
@Model
final class BALogEntry {
    // MARK: Before

    /// When the user committed — "собирался вчера в 16:40".
    var createdAt: Date
    /// Which store row this came from, for the "Что работает" aggregation in
    /// §11.6. Optional and non-owning: the activity may be deleted later.
    var activityID: UUID?
    /// Snapshotted so history stays truthful after the store is edited.
    var activityTitle: String
    var effortRaw: String
    var energyRaw: String
    /// Nil when the forecast question was skipped.
    var forecastRaw: String?

    // MARK: After

    /// Nil while the activity is still open. Nil is *not* a failure.
    var outcomeRaw: String?
    var answeredAt: Date?
    /// 0–10, both nil unless the outcome was "done" and the sliders were touched.
    var pleasure: Int?
    var mastery: Int?
    var note: String?

    /// Identifier for the single reminder, so answering can cancel it. Stored
    /// rather than derived from `persistentModelID`, which is not guaranteed to
    /// hash to the same value across launches — and a reminder that cannot be
    /// cancelled would nag about an activity already answered.
    var reminderToken: UUID

    init(
        createdAt: Date,
        activityID: UUID?,
        activityTitle: String,
        effort: BAEffort,
        energy: BAEnergy,
        forecast: BAForecast?,
        reminderToken: UUID = UUID()
    ) {
        self.createdAt = createdAt
        self.reminderToken = reminderToken
        self.activityID = activityID
        self.activityTitle = activityTitle
        self.effortRaw = effort.rawValue
        self.energyRaw = energy.rawValue
        self.forecastRaw = forecast?.rawValue
    }

    var effort: BAEffort? { BAEffort(rawValue: effortRaw) }
    var energy: BAEnergy? { BAEnergy(rawValue: energyRaw) }
    var forecast: BAForecast? { forecastRaw.flatMap(BAForecast.init(rawValue:)) }
    var outcome: BAOutcome? { outcomeRaw.flatMap(BAOutcome.init(rawValue:)) }

    /// The tail. Drives the row on Today, the branch on entering BA, and the
    /// one-open-activity invariant.
    var isOpen: Bool { outcomeRaw == nil }

    var reminderID: String { "ba.tail.\(reminderToken.uuidString)" }
}
