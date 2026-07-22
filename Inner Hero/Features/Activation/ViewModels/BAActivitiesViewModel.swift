import Foundation
import SwiftData

/// The activity store (spec §6): the door opened on a good day.
///
/// Everything here is deliberately dull. Adding is a line and a basket, deleting
/// is a swipe, and there is no editing, no ordering, no tagging — the store earns
/// its keep by being fast to fill, not by being well organised.
@Observable
@MainActor
final class BAActivitiesViewModel {

    var draftTitle = ""
    var draftEffort: BAEffort = .easy

    var trimmedDraftTitle: String {
        draftTitle.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var canAdd: Bool { !trimmedDraftTitle.isEmpty }

    func add(in context: ModelContext, now: Date = Date()) throws {
        guard canAdd else { return }
        context.insert(
            BAActivity(title: trimmedDraftTitle, effort: draftEffort, createdAt: now)
        )
        try context.save()
        // The basket is kept for the next line: filling the store means adding
        // several at once, and re-picking "easy" every time is the kind of
        // repeated choice codex §2 exists to remove.
        draftTitle = ""
    }

    func delete(_ activity: BAActivity, in context: ModelContext) throws {
        context.delete(activity)
        try context.save()
    }

    /// Baskets in ladder order, skipping the empty ones — an empty section header
    /// would be a label with nothing under it, not information.
    nonisolated func grouped(_ activities: [BAActivity]) -> [(basket: BAEffort, items: [BAActivity])] {
        BALadder.baskets.compactMap { basket in
            let items = activities.filter { $0.effort == basket }
            return items.isEmpty ? nil : (basket, items)
        }
    }
}
