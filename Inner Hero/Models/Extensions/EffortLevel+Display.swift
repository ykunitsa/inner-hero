import Foundation

extension EffortLevel {
    var localizedName: String {
        switch self {
        case .low:    return String(localized: "Low")
        case .medium: return String(localized: "Moderate")
        case .high:   return String(localized: "High")
        }
    }
}
