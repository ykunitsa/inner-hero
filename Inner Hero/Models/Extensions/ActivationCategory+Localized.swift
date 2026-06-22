import SwiftUI

extension ActivationCategory {
    /// Returns the localized title for preset categories; falls back to the stored title for user-created ones.
    var localizedTitle: String {
        guard let key = predefinedKey else { return title }
        return PresetActivationLookup.categoryTitle(forKey: key)
    }

    /// Category accent color parsed from `colorHex`, falling back to the app accent.
    var color: Color {
        Color(hex: colorHex) ?? AppColors.accent
    }
}
