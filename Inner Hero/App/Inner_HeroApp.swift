import SwiftUI
import SwiftData

@main
struct Inner_HeroApp: App {
    @AppStorage(AppStorageKeys.hasCompletedOnboarding) private var hasCompletedOnboarding = false
    @AppStorage(AppStorageKeys.themeMode) private var themeModeRawValue: String = ThemeMode.system.rawValue

    @State private var notificationManager = NotificationManager()
    @State private var articlesStore = ArticlesStore()

    private let modelContainer: ModelContainer

    init() {
        StoreBootstrap.wipeLegacyStoreIfNeeded()
        modelContainer = StoreBootstrap.makeContainer()
    }

    var body: some Scene {
        WindowGroup {
            AppLockGateView {
                RootAppView(hasCompletedOnboarding: hasCompletedOnboarding)
            }
            .environment(notificationManager)
            .environment(articlesStore)
            .preferredColorScheme((ThemeMode(rawValue: themeModeRawValue) ?? .system).preferredColorScheme)
        }
        .modelContainer(modelContainer)
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

// MARK: - Store Bootstrap

/// Creates the SwiftData container for the 2.0 models.
///
/// Pre-release phase (CLAUDE.md): no versioned schemas — the legacy 1.x store
/// is wiped once on first 2.0 launch, and a store that no longer opens after
/// an in-place model edit is recreated from scratch.
private enum StoreBootstrap {
    static let schema = Schema([
        ExposureLogEntry.self,
        BreathingSessionEntry.self,
        PMRSessionEntry.self,
    ])

    static func wipeLegacyStoreIfNeeded() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: AppStorageKeys.hasWipedLegacyStore) else { return }
        deleteDefaultStore()
        defaults.set(true, forKey: AppStorageKeys.hasWipedLegacyStore)
    }

    static func makeContainer() -> ModelContainer {
        do {
            return try ModelContainer(for: schema)
        } catch {
            deleteDefaultStore()
            do {
                return try ModelContainer(for: schema)
            } catch {
                fatalError("Failed to create ModelContainer even after a store reset: \(error)")
            }
        }
    }

    private static func deleteDefaultStore() {
        let storeURL = URL.applicationSupportDirectory.appending(path: "default.store")
        for suffix in ["", "-shm", "-wal"] {
            let url = URL(filePath: storeURL.path() + suffix)
            try? FileManager.default.removeItem(at: url)
        }
    }
}
