//
//  Inner_HeroApp.swift
//  Inner Hero
//
//  Created by Yauheni Kunitsa on 21.10.25.
//

import SwiftUI
import SwiftData

@main
struct Inner_HeroApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("hasLoadedSampleData") private var hasLoadedSampleData = false
    
    var sharedModelContainer: ModelContainer = {
        do {
            return try ModelContainer(for: Exposure.self, SessionResult.self, Step.self)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    init() {
        // Автоматическая загрузка тестовых данных при первом запуске
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
    
    /// Загрузить примеры данных при первом запуске
    private func loadSampleDataIfNeeded() {
        // Загружать только один раз или в DEBUG режиме
        #if DEBUG
        let shouldLoad = !hasLoadedSampleData
        #else
        let shouldLoad = false // В релизной версии не загружать автоматически
        #endif
        
        guard shouldLoad else { return }
        
        do {
            let context = sharedModelContainer.mainContext
            
            // Проверить, что база данных пустая
            if try SampleDataLoader.isDatabaseEmpty(context) {
                // Загрузить экспозиции из JSON
                try SampleDataLoader.loadSampleExposures(into: context)
                
                // Опционально: создать примеры сеансов для тестирования графиков
                let exposures = try context.fetch(FetchDescriptor<Exposure>())
                try SampleDataLoader.loadSampleSessions(for: exposures, into: context)
                
                hasLoadedSampleData = true
                print("✅ Тестовые данные загружены успешно")
            }
        } catch {
            print("⚠️ Ошибка загрузки тестовых данных: \(error)")
        }
    }
}
