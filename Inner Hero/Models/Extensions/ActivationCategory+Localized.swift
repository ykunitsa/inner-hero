import Foundation

extension ActivationCategory {
    /// Returns the localized title for preset categories; falls back to the stored title for user-created ones.
    var localizedTitle: String {
        guard let key = predefinedKey else { return title }
        return PresetActivationLookup.categoryTitle(forKey: key)
    }
}
