import Foundation

extension ActivationTask {
    /// Returns the localized title for preset tasks; falls back to the stored title for user-created ones.
    var localizedTitle: String {
        guard let key = predefinedKey else { return title }
        return PresetActivationLookup.taskTitle(forKey: key)
    }

    /// Returns the localized hint for preset tasks; falls back to the stored hint for user-created ones.
    var localizedHint: String? {
        guard let key = predefinedKey else { return hint }
        return PresetActivationLookup.taskHint(forKey: key)
    }
}
