import SwiftUI
import SwiftData

@main
struct Inner_HeroApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("hasLoadedSampleData") private var hasLoadedSampleData = false
    @AppStorage(AppStorageKeys.themeMode) private var themeModeRawValue: String = ThemeMode.system.rawValue
    
    @StateObject private var articlesStore = ArticlesStore()
    
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
                FavoriteExercise.self
            )
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    init() {
        loadSampleDataIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            AppLockGateView {
                RootAppView(hasCompletedOnboarding: hasCompletedOnboarding)
            }
            .preferredColorScheme((ThemeMode(rawValue: themeModeRawValue) ?? .system).preferredColorScheme)
            .environmentObject(articlesStore)
        }
        .modelContainer(sharedModelContainer)
    }
    
    // MARK: - Sample Data Loading
    
    private func loadSampleDataIfNeeded() {
        let shouldLoad = !hasLoadedSampleData
        
        guard shouldLoad else { return }
        
        do {
            let context = sharedModelContainer.mainContext
            
            if try SampleDataLoader.isDatabaseEmpty(context) {
                try SampleDataLoader.loadPredefinedExposures(into: context)
                
                let exposures = try context.fetch(FetchDescriptor<Exposure>())
                try SampleDataLoader.loadSampleSessions(for: exposures, into: context)
                
                // Load predefined activation lists
                try SampleDataLoader.loadPredefinedActivationLists(into: context)
                
                hasLoadedSampleData = true
                print("✅ Тестовые данные загружены успешно")
            } else {
                hasLoadedSampleData = true
            }
        } catch {
            print("⚠️ Ошибка загрузки тестовых данных: \(error)")
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
