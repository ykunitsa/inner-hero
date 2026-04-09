import Foundation

// MARK: - PresetActivationLookup
// Runtime localization for preset ActivationCategory and ActivationTask.
// Keys map to entries in Localizable.xcstrings.

enum PresetActivationLookup {

    // MARK: - Category

    static func categoryTitle(forKey key: String) -> String {
        localizedString("predefined.activation.category.\(key).title")
    }

    // MARK: - Task

    static func taskTitle(forKey key: String) -> String {
        localizedString("predefined.activation.task.\(key).title")
    }

    static func taskHint(forKey key: String) -> String? {
        let value = localizedString("predefined.activation.task.\(key).hint")
        return value == "predefined.activation.task.\(key).hint" ? nil : value
    }

    // MARK: - Private

    private static func localizedString(_ key: String) -> String {
        Bundle.main.localizedString(forKey: key, value: nil, table: nil)
    }
}
