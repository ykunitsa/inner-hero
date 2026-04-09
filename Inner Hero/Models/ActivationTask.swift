import Foundation
import SwiftData

// MARK: - EffortLevel

// Storage contract: rawValues are persisted in SwiftData. NEVER rename rawValue strings — only add new cases.
enum EffortLevel: String, Codable, CaseIterable {
    case low    = "low"
    case medium = "medium"
    case high   = "high"
}

// MARK: - ActivationTask Model

@Model
final class ActivationTask {
    @Attribute(.unique) var id: UUID
    var categoryId: UUID
    /// Stable key for preset tasks (e.g. "self_care_01"). Nil for user-created.
    var predefinedKey: String?
    var title: String
    var hint: String?
    var pleasureTag: Bool
    var masteryTag: Bool
    var effortLevelRaw: String      // EffortLevel.rawValue
    var suggestedMinutes: Int?
    var sfSymbol: String
    var isPreset: Bool
    var isHiddenByUser: Bool
    var sortOrder: Int
    var createdAt: Date

    init(
        id: UUID = UUID(),
        categoryId: UUID,
        predefinedKey: String? = nil,
        title: String,
        hint: String? = nil,
        pleasureTag: Bool = false,
        masteryTag: Bool = false,
        effortLevel: EffortLevel = .low,
        suggestedMinutes: Int? = nil,
        sfSymbol: String = "checkmark.circle",
        isPreset: Bool = false,
        isHiddenByUser: Bool = false,
        sortOrder: Int = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.categoryId = categoryId
        self.predefinedKey = predefinedKey
        self.title = title
        self.hint = hint
        self.pleasureTag = pleasureTag
        self.masteryTag = masteryTag
        self.effortLevelRaw = effortLevel.rawValue
        self.suggestedMinutes = suggestedMinutes
        self.sfSymbol = sfSymbol
        self.isPreset = isPreset
        self.isHiddenByUser = isHiddenByUser
        self.sortOrder = sortOrder
        self.createdAt = createdAt
    }

    var effortLevel: EffortLevel {
        get { EffortLevel(rawValue: effortLevelRaw) ?? .low }
        set { effortLevelRaw = newValue.rawValue }
    }
}
