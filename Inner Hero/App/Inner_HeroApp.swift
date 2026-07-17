import SwiftUI

@main
struct Inner_HeroApp: App {
    @AppStorage(AppStorageKeys.hasCompletedOnboarding) private var hasCompletedOnboarding = false
    @AppStorage(AppStorageKeys.themeMode) private var themeModeRawValue: String = ThemeMode.system.rawValue

    @State private var notificationManager = NotificationManager()
    @State private var articlesStore = ArticlesStore()

    // NOTE (redesign 2.0): the SwiftData ModelContainer returns with the new
    // ExposureLogEntry model. The legacy on-disk store is wiped once at that point.

    var body: some Scene {
        WindowGroup {
            AppLockGateView {
                RootAppView(hasCompletedOnboarding: hasCompletedOnboarding)
            }
            .environment(notificationManager)
            .environment(articlesStore)
            .preferredColorScheme((ThemeMode(rawValue: themeModeRawValue) ?? .system).preferredColorScheme)
        }
    }
}

private struct RootAppView: View {
    let hasCompletedOnboarding: Bool

    var body: some View {
        if hasCompletedOnboarding {
            MainTabView()
        } else {
            OnboardingView()
        }
    }
}
