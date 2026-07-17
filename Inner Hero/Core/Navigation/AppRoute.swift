import Foundation

// MARK: - App Route

/// Centralized navigation routes. Rebuilt from scratch for the 2.0 redesign —
/// routes come back one by one as each new screen lands.
enum AppRoute: Hashable {
    case articleDetail(articleId: String)
    case settings
    case settingsAppearance
    case settingsPrivacy
}
