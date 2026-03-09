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
                        Text("Summary")
                    } icon: {
                        Image(systemName: "heart.gauge.open")
                    }
                }
                .accessibilityLabel("Summary")

            ExercisesView()
                .tag(Tab.exercises)
                .tabItem {
                    Label {
                        Text("Exercises")
                    } icon: {
                        Image(systemName: "figure.mind.and.body")
                    }
                }
                .accessibilityLabel("Exercises")
            
            ScheduleTabView()
                .tag(Tab.schedule)
                .tabItem {
                    Label {
                        Text("Schedule")
                    } icon: {
                        Image(systemName: "calendar")
                    }
                }
                .accessibilityLabel("Schedule")
            
            KnowledgeCenterView()
                .tag(Tab.knowledge)
                .tabItem {
                    Label {
                        Text("Knowledge center")
                    } icon: {
                        Image(systemName: "book.pages")
                    }
                }
                .accessibilityLabel("Knowledge center")
            
            SettingsView()
                .tag(Tab.settings)
                .tabItem {
                    Label {
                        Text("Settings")
                    } icon: {
                        Image(systemName: "gear")
                    }
                }
                .accessibilityLabel("Settings")
        }
        .tint(.blue)
    }
}

#Preview {
    MainTabView()
}
