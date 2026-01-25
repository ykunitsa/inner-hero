import SwiftUI
import SwiftData

struct MainTabView: View {
    @State private var selectedTab: Tab = .home
    
    enum Tab {
        case home
        case schedule
        case knowledge
        case exercises
        case settings
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tag(Tab.home)
                .tabItem {
                    Label {
                        Text("Сводка")
                    } icon: {
                        Image(systemName: "heart.gauge.open")
                    }
                }
                .accessibilityLabel("Сводка")

            ExercisesView()
                .tag(Tab.exercises)
                .tabItem {
                    Label {
                        Text("Упражнения")
                    } icon: {
                        Image(systemName: "figure.mind.and.body")
                    }
                }
                .accessibilityLabel("Упражнения")
            
            ScheduleTabView()
                .tag(Tab.schedule)
                .tabItem {
                    Label {
                        Text("Расписание")
                    } icon: {
                        Image(systemName: "calendar")
                    }
                }
                .accessibilityLabel("Расписание")
            
            KnowledgeCenterView()
                .tag(Tab.knowledge)
                .tabItem {
                    Label {
                        Text("Центр знаний")
                    } icon: {
                        Image(systemName: "book.pages")
                    }
                }
                .accessibilityLabel("Центр знаний")
            
            SettingsView()
                .tag(Tab.settings)
                .tabItem {
                    Label {
                        Text("Настройки")
                    } icon: {
                        Image(systemName: "gear")
                    }
                }
                .accessibilityLabel("Настройки")
        }
        .tint(.blue)
    }
}

#Preview {
    MainTabView()
}
