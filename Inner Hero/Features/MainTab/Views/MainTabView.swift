import SwiftUI
import SwiftData

struct MainTabView: View {
    @State private var selectedTab: AppTab = .home
    @State private var scheduleViewModel = ScheduleViewModel()
    @State private var router = NavigationRouter()

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(path: router.path(for: .home))
                .environment(router)
                .environment(\.currentAppTab, .home)
                .environment(\.scheduleViewModel, scheduleViewModel)
                .tag(AppTab.home)
                .tabItem { Image(systemName: "sparkles") }
                .accessibilityLabel("Summary")

            ExercisesView(path: router.path(for: .exercises))
                .environment(router)
                .environment(\.currentAppTab, .exercises)
                .environment(\.scheduleViewModel, scheduleViewModel)
                .tag(AppTab.exercises)
                .tabItem { Image(systemName: "figure.mind.and.body") }
                .accessibilityLabel("Exercises")

            ScheduleTabView(path: router.path(for: .schedule))
                .environment(router)
                .environment(\.currentAppTab, .schedule)
                .environment(\.scheduleViewModel, scheduleViewModel)
                .tag(AppTab.schedule)
                .tabItem { Image(systemName: "calendar") }
                .accessibilityLabel("Schedule")

            KnowledgeCenterView(path: router.path(for: .knowledge))
                .environment(router)
                .environment(\.currentAppTab, .knowledge)
                .environment(\.scheduleViewModel, scheduleViewModel)
                .tag(AppTab.knowledge)
                .tabItem { Image(systemName: "book.pages") }
                .accessibilityLabel("Knowledge center")

            SettingsView(path: router.path(for: .settings))
                .environment(router)
                .environment(\.currentAppTab, .settings)
                .tag(AppTab.settings)
                .tabItem { Image(systemName: "person.circle") }
                .accessibilityLabel("Profile")
        }
        .tint(AppColors.primary)
    }
}

#Preview {
    MainTabView()
}
