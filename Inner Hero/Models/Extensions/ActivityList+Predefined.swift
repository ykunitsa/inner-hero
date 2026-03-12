import Foundation

extension ActivityList {
    var localizedTitle: String {
        guard let predefinedKey,
              let key = PredefinedActivationListKey(rawValue: predefinedKey) else {
            return title
        }
        return PredefinedActivationLists.data(for: key).title
    }

    var localizedActivities: [String] {
        guard let predefinedKey,
              let key = PredefinedActivationListKey(rawValue: predefinedKey) else {
            return activities
        }
        return PredefinedActivationLists.data(for: key).activities
    }
}
