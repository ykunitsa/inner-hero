import Foundation
import SwiftData

// MARK: - ActivationCategory Model

@Model
final class ActivationCategory {
    @Attribute(.unique) var id: UUID
    /// Stable key for preset categories (e.g. "self_care"). Nil for user-created.
    var predefinedKey: String?
    var title: String
    var sfSymbol: String
    var colorHex: String
    var sortOrder: Int
    var isPreset: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        predefinedKey: String? = nil,
        title: String,
        sfSymbol: String,
        colorHex: String,
        sortOrder: Int,
        isPreset: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.predefinedKey = predefinedKey
        self.title = title
        self.sfSymbol = sfSymbol
        self.colorHex = colorHex
        self.sortOrder = sortOrder
        self.isPreset = isPreset
        self.createdAt = createdAt
    }
}
