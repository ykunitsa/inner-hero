import Foundation
import SwiftData

// MARK: - ActivityList Model

@Model
final class ActivityList {
    @Attribute(.unique) var id: UUID
    var title: String
    var predefinedKey: String? = nil
    var activities: [String]
    var isPredefined: Bool
    
    init(
        id: UUID = UUID(),
        title: String,
        predefinedKey: String? = nil,
        activities: [String] = [],
        isPredefined: Bool = false
    ) {
        self.id = id
        self.title = title
        self.predefinedKey = predefinedKey
        self.activities = activities
        self.isPredefined = isPredefined
    }
}

