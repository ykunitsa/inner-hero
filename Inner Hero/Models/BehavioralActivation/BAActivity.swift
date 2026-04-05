import Foundation
import SwiftData

@Model
final class BAActivity {
    @Attribute(.unique) var id: UUID
    var title: String
    var lifeValueRaw: String
    var predefinedKey: String?
    var createdAt: Date
    @Relationship(deleteRule: .nullify, inverse: \BASession.activity) var sessions: [BASession] = []

    // MARK: - Computed: LifeValue

    var lifeValue: LifeValue {
        LifeValue(rawValue: lifeValueRaw) ?? .rest
    }

    // MARK: - Computed: Identity

    var isCustom: Bool { predefinedKey == nil }

    var localizedTitle: String {
        guard let key = predefinedKey else { return title }
        return Bundle.main.localizedString(
            forKey: "predefined.ba.\(key)",
            value: title,
            table: nil
        )
    }

    // MARK: - Computed: Stats

    var timesUsed: Int {
        sessions.filter { $0.status == .completed }.count
    }

    var averageMoodDelta: Double? {
        let deltas = sessions
            .filter { $0.status == .completed }
            .compactMap { session -> Double? in
                guard let after = session.moodAfter else { return nil }
                return Double(after - session.moodBefore)
            }
        guard !deltas.isEmpty else { return nil }
        return deltas.reduce(0, +) / Double(deltas.count)
    }

    // MARK: - Init

    init(
        id: UUID = UUID(),
        title: String,
        lifeValueRaw: String,
        predefinedKey: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.lifeValueRaw = lifeValueRaw
        self.predefinedKey = predefinedKey
        self.createdAt = createdAt
    }
}
