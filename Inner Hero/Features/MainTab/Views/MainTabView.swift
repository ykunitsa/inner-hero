import SwiftUI

struct MainTabView: View {
    /// Which tab the app opens on. Normally Today; right after onboarding it is
    /// Exercises, because §7 sends "Start" there and §8 has the articles waiting
    /// at the doors.
    var initialTab: AppTab = .today

    @State private var selectedTab: AppTab
    @State private var router = NavigationRouter()

    init(initialTab: AppTab = .today) {
        self.initialTab = initialTab
        _selectedTab = State(initialValue: initialTab)
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView(path: router.path(for: .today))
                .environment(router)
                .environment(\.currentAppTab, .today)
                .tag(AppTab.today)
                .tabItem { Image(systemName: "sun.max") }
                .accessibilityLabel("Today")

            ExercisesView(path: router.path(for: .exercises))
                .environment(router)
                .environment(\.currentAppTab, .exercises)
                .tag(AppTab.exercises)
                .tabItem { Image(systemName: "figure.mind.and.body") }
                .accessibilityLabel("Exercises")

            HistoryView(path: router.path(for: .history))
                .environment(router)
                .environment(\.currentAppTab, .history)
                .tag(AppTab.history)
                .tabItem { Image(systemName: "clock.arrow.circlepath") }
                .accessibilityLabel("History")

            KnowledgeCenterView(path: router.path(for: .knowledge))
                .environment(router)
                .environment(\.currentAppTab, .knowledge)
                .tag(AppTab.knowledge)
                .tabItem { Image(systemName: "book.pages") }
                .accessibilityLabel("Knowledge center")
        }
        .tint(AppColors.primary)
        // `\.navigationRouter` is a separate EnvironmentKey from Observable injection;
        // programmatic pushes read it from the environment.
        .environment(\.navigationRouter, router)
    }
}

#Preview {
    MainTabView()
        .environment(ArticlesStore())
}
