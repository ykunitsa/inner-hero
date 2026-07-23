import SwiftData
import SwiftUI

struct MainTabView: View {
    /// Which tab the app opens on. Normally Today; right after onboarding it is
    /// Exercises, because §7 sends "Start" there and §8 has the articles waiting
    /// at the doors.
    var initialTab: AppTab = .today

    @State private var selectedTab: AppTab
    @State private var router = NavigationRouter()

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var modelContext
    @Environment(NotificationManager.self) private var notificationManager

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

            // Third, next to Exercises: the schedule is about them. History and
            // Knowledge keep the places they had.
            ScheduleView(path: router.path(for: .schedule))
                .environment(router)
                .environment(\.currentAppTab, .schedule)
                .tag(AppTab.schedule)
                .tabItem { Image(systemName: "calendar") }
                .accessibilityLabel("Schedule")

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
        // The schedule's reminders are re-laid on every foreground, not only when
        // the Schedule tab is visited. A one-off whose moment has passed, a
        // timezone the phone crossed, a permission granted in iOS Settings — all
        // of them land here, and the re-sync is idempotent, so paying for it on
        // every activation is cheaper than tracking which of them happened.
        .task(id: scenePhase) {
            guard scenePhase == .active else { return }
            let items = (try? modelContext.fetch(FetchDescriptor<ScheduleItem>())) ?? []
            await ScheduleReminderService.sync(items, via: notificationManager)
        }
    }
}

#Preview {
    MainTabView()
        .environment(ArticlesStore())
}
