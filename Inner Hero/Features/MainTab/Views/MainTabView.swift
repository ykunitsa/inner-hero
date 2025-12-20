import SwiftUI
import SwiftData

#if canImport(UIKit)
import UIKit
#endif

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
        .tint(.blue)
        .onAppear {
            configureTabBarAppearance()
        }
    }
    
    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        
        // Background color matching the gradient background
        appearance.backgroundColor = UIColor(red: 0.95, green: 0.97, blue: 1.0, alpha: 1.0)
        
        // Selected item color (blue)
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor.systemBlue
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor.systemBlue
        ]
        
        // Unselected item color (secondary text color)
        let unselectedColor = UIColor(red: 0.45, green: 0.48, blue: 0.54, alpha: 1.0) // TextColors.secondary
        appearance.stackedLayoutAppearance.normal.iconColor = unselectedColor
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: unselectedColor
        ]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: Exposure.self, inMemory: true)
}
