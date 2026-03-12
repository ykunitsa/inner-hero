import SwiftUI
import SwiftData

@main
struct Inner_HeroApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("hasLoadedSampleData") private var hasLoadedSampleData = false
    @AppStorage(AppStorageKeys.themeMode) private var themeModeRawValue: String = ThemeMode.system.rawValue

    @State private var notificationManager = NotificationManager()
    @State private var isLoadingInitialData = true
    @State private var articlesStore = ArticlesStore()
    
    var sharedModelContainer: ModelContainer = {
        do {
            return try ModelContainer(
                for: Exposure.self,
                ExposureSessionResult.self,
                ExposureStep.self,
                BreathingSessionResult.self,
                RelaxationSessionResult.self,
                GroundingSessionResult.self,
                ActivityList.self,
                BehavioralActivationSession.self,
                ExerciseAssignment.self,
                ExerciseCompletion.self,
                FavoriteExercise.self,
                migrationPlan: AppMigrationPlan.self
            )
        } catch {
            #if DEBUG
            fatalError("Could not create ModelContainer: \(error)")
            #else
            print("⚠️ ModelContainer failed (\(error)); using in-memory fallback.")
            do {
                let config = ModelConfiguration(isStoredInMemoryOnly: true)
                return try ModelContainer(
                    for: Exposure.self,
                    ExposureSessionResult.self,
                    ExposureStep.self,
                    BreathingSessionResult.self,
                    RelaxationSessionResult.self,
                    GroundingSessionResult.self,
                    ActivityList.self,
                    BehavioralActivationSession.self,
                    ExerciseAssignment.self,
                    ExerciseCompletion.self,
                    FavoriteExercise.self,
                    configurations: [config]
                )
            } catch {
                fatalError("In-memory ModelContainer fallback failed: \(error)")
            }
            #endif
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            AppInitializerView(loadTask: { await appLoadTask() }, isLoading: $isLoadingInitialData) {
                AppLockGateView {
                    RootAppView(hasCompletedOnboarding: hasCompletedOnboarding)
                }
                .environment(notificationManager)
                .preferredColorScheme((ThemeMode(rawValue: themeModeRawValue) ?? .system).preferredColorScheme)
                .environment(articlesStore)
            }
        }
        .modelContainer(sharedModelContainer)
    }

    @MainActor
    private func appLoadTask() async {
        _ = await notificationManager.requestAuthorization()
        await loadSampleDataIfNeeded()
    }
    
    // MARK: - Sample Data Loading
    
    @MainActor
    private func loadSampleDataIfNeeded() async {
        guard !hasLoadedSampleData else { return }
        
        do {
            let context = sharedModelContainer.mainContext
            
            if try SampleDataLoader.isDatabaseEmpty(context) {
                try SampleDataLoader.loadPredefinedExposures(into: context)
                
                let exposures = try context.fetch(FetchDescriptor<Exposure>())
                try SampleDataLoader.loadSampleSessions(for: exposures, into: context)
                
                try SampleDataLoader.loadPredefinedActivationLists(into: context)
                
                hasLoadedSampleData = true
                print("✅ Test data loaded successfully")
            } else {
                hasLoadedSampleData = true
            }
        } catch {
            print("⚠️ Error loading test data: \(error)")
        }
    }
}

private struct AppInitializerView<Content: View>: View {
    let loadTask: () async -> Void
    @Binding var isLoading: Bool
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else {
                content()
            }
        }
        .task {
            await loadTask()
            isLoading = false
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
