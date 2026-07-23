import SwiftData
import SwiftUI
import WidgetKit

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
    @Environment(DeepLinkInbox.self) private var deepLinks

    /// The setting, not the current lock state: what the widgets are allowed to
    /// carry does not change while the phone is unlocked in the user's hand.
    @AppStorage(AppStorageKeys.appLockEnabled) private var appLockEnabled = false

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
            guard scenePhase == .active else {
                // Leaving is the moment worth writing: while the app is in front,
                // nobody is looking at the home screen.
                if scenePhase == .background { writeWidgetSnapshot() }
                return
            }
            let items = (try? modelContext.fetch(FetchDescriptor<ScheduleItem>())) ?? []
            await ScheduleReminderService.sync(items, via: notificationManager)
            writeWidgetSnapshot()
        }
        // A link arrives from outside; the flows themselves live on Today, so the
        // tab moves here and the screen underneath takes it from the inbox.
        .task(id: deepLinks.pending) { routeToToday() }
    }

    private func routeToToday() {
        guard deepLinks.pending != nil else { return }
        router.popToRoot(in: .today)
        selectedTab = .today
    }

    /// Rebuilds what the widgets read, then asks WidgetKit to redraw.
    ///
    /// Idempotent and cheap, for the same reason the reminder re-sync is: paying for
    /// it on every transition costs less than tracking which of a dozen possible
    /// edits happened.
    private func writeWidgetSnapshot() {
        let snapshot = WidgetSnapshotBuilder.build(
            schedule: (try? modelContext.fetch(FetchDescriptor<ScheduleItem>())) ?? [],
            breathing: (try? modelContext.fetch(FetchDescriptor<BreathingSessionEntry>())) ?? [],
            pmr: (try? modelContext.fetch(FetchDescriptor<PMRSessionEntry>())) ?? [],
            activation: (try? modelContext.fetch(FetchDescriptor<BALogEntry>())) ?? [],
            isLocked: appLockEnabled
        )
        WidgetSnapshotStore().write(snapshot)
        WidgetCenter.shared.reloadAllTimelines()
    }
}

#Preview {
    MainTabView()
        .environment(ArticlesStore())
        .environment(DeepLinkInbox())
}
