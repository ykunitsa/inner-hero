import SwiftUI

enum ThemeMode: String, CaseIterable, Identifiable {
    case system
    case light
    case dark
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .system: String(localized: "System")
        case .light: String(localized: "Light")
        case .dark: String(localized: "Dark")
        }
    }
    
    var preferredColorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

enum AppStorageKeys {
    static let themeMode = "settings.themeMode"
    static let remindersEnabled = "settings.remindersEnabled"
    static let appLockEnabled = "settings.appLockEnabled"
    static let hasCompletedOnboarding = "hasCompletedOnboarding"
    static let hasLoadedSampleData = "hasLoadedSampleData"
}


