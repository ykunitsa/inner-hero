import SwiftUI

struct SettingsView: View {
    @Binding var path: NavigationPath

    var body: some View {
        NavigationStack(path: $path) {
            Form {
                Section("Settings") {
                    NavigationLink(value: AppRoute.settingsAppearance) {
                        Label(String(localized: "Appearance"), systemImage: "paintbrush")
                    }
                    
                    NavigationLink(value: AppRoute.settingsPrivacy) {
                        Label(String(localized: "Privacy"), systemImage: "lock.shield")
                    }
                    
                    NavigationLink(value: AppRoute.settingsData) {
                        Label("Data", systemImage: "tray.full")
                    }
                }
                
                Section(String(localized: "Support")) {
                    NavigationLink(value: AppRoute.settingsAbout) {
                        Label(String(localized: "About"), systemImage: "info.circle")
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
        .navigationDestination(for: AppRoute.self) { route in
            AppRouteView(route: route)
        }
    }
}

#Preview {
    SettingsView(path: .constant(NavigationPath()))
}


