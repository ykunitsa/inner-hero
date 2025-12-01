import SwiftUI
import SwiftData

struct MainTabView: View {
    @State private var selectedTab: Tab = .exposures
    
    enum Tab {
        case exposures
        case history
        case profile
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ExposuresListView()
                .tag(Tab.exposures)
                .tabItem {
                    Label {
                        Text("Экспозиции")
                    } icon: {
                        Image(systemName: "leaf.circle.fill")
                    }
                }
                .accessibilityLabel("Экспозиции")
            
            AllSessionsHistoryView()
                .tag(Tab.history)
                .tabItem {
                    Label {
                        Text("История")
                    } icon: {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                    }
                }
                .accessibilityLabel("История сеансов")
            
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
        .tint(.teal)
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: Exposure.self, inMemory: true)
}
