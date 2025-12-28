import Foundation
import SwiftData

// MARK: - ActivityList Model

@Model
final class ActivityList {
    @Attribute(.unique) var id: UUID
    var title: String
    var activities: [String]
    var isPredefined: Bool
    
    init(
        id: UUID = UUID(),
        title: String,
        activities: [String] = [],
        isPredefined: Bool = false
    ) {
        self.id = id
        self.title = title
        self.activities = activities
        self.isPredefined = isPredefined
    }
}

