import SwiftUI
import SwiftData

@main
struct Inner_HeroApp: App {
    @AppStorage(AppStorageKeys.hasCompletedOnboarding) private var hasCompletedOnboarding = false
    @AppStorage(AppStorageKeys.themeMode) private var themeModeRawValue: String = ThemeMode.system.rawValue

    @State private var notificationManager = NotificationManager()
    @State private var articlesStore = ArticlesStore()

    private let modelContainer: ModelContainer
    /// Whether onboarding was already behind us when this launch started.
    ///
    /// Spec §7 sends "Start" to the Exercises tab, not Today: that is where the
    /// articles stand at the doors while `sessions == 0` (§8). Captured at
    /// launch rather than stored as another flag — finishing onboarding rebuilds
    /// `RootAppView`, and this is the only thing that has to remember why.
    private let wasOnboardedAtLaunch: Bool

    init() {
        StoreBootstrap.wipeLegacyStoreIfNeeded()
        modelContainer = StoreBootstrap.makeContainer()
        // The BA store has to exist before the first "Одно дело" card is drawn;
        // an empty shelf is not a state that screen can do anything useful with.
        BAPreset.seedIfNeeded(in: modelContainer.mainContext)
        wasOnboardedAtLaunch = UserDefaults.standard.bool(
            forKey: AppStorageKeys.hasCompletedOnboarding
        )
    }

    var body: some Scene {
        WindowGroup {
            AppLockGateView {
                RootAppView(
                    hasCompletedOnboarding: hasCompletedOnboarding,
                    initialTab: wasOnboardedAtLaunch ? .today : .exercises
                )
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
    let initialTab: AppTab

    var body: some View {
        if hasCompletedOnboarding {
            MainTabView(initialTab: initialTab)
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
        BAActivity.self,
        BALogEntry.self,
        ScheduleItem.self,
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

        // Flags that describe the *contents* of the store have to die with it —
        // but only if it actually died. The BA seed flag means "this store has
        // been seeded"; clearing it while the file survives seeds the preset a
        // second time into a store that already has it, and the user opens
        // "Занятия" to every line twice. Deletion can fail (an open handle, a
        // store CoreData is mid-recovery on), so the flag follows the file rather
        // than the intention.
        guard !FileManager.default.fileExists(atPath: storeURL.path()) else { return }
        UserDefaults.standard.removeObject(forKey: AppStorageKeys.hasSeededBAPreset)
    }
}
