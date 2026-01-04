import SwiftUI
import SwiftData

struct MainTabView: View {
    @State private var selectedTab: Tab = .home
    
    enum Tab {
        case home
        case exercises
        case profile
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tag(Tab.home)
                .tabItem {
                    Label {
                        Text("Сводка")
                    } icon: {
                        Image(systemName: "heart.circle")
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
            
            ProfileView()
                .tag(Tab.profile)
                .tabItem {
                    Label {
                        Text("Профиль")
                    } icon: {
                        Image(systemName: "person.circle.fill")
                    }
                }
                .accessibilityLabel("Профиль")
        }
        .tint(.blue)
    }
}

#Preview {
    MainTabView()
}
