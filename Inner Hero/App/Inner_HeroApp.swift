import SwiftUI
import SwiftData

@main
struct Inner_HeroApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("hasLoadedSampleData") private var hasLoadedSampleData = false
    
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
            if hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .modelContainer(sharedModelContainer)
    }
    
    // MARK: - Sample Data Loading
    
    private func loadSampleDataIfNeeded() {
        #if DEBUG
        let shouldLoad = !hasLoadedSampleData
        #else
        let shouldLoad = false
        #endif
        
        guard shouldLoad else { return }
        
        do {
            let context = sharedModelContainer.mainContext
            
            if try SampleDataLoader.isDatabaseEmpty(context) {
                try SampleDataLoader.loadSampleExposures(into: context)
                
                let exposures = try context.fetch(FetchDescriptor<Exposure>())
                try SampleDataLoader.loadSampleSessions(for: exposures, into: context)
                
                // Load predefined activation lists
                try SampleDataLoader.loadPredefinedActivationLists(into: context)
                
                hasLoadedSampleData = true
                print("✅ Тестовые данные загружены успешно")
            }
        } catch {
            print("⚠️ Ошибка загрузки тестовых данных: \(error)")
        }
    }
}
