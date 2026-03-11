import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            Form {
                Section("Settings") {
                    NavigationLink {
                        AppearanceSettingsView()
                    } label: {
                        Label(String(localized: "Appearance"), systemImage: "paintbrush")
                    }
                    
                    NavigationLink {
                        PrivacySettingsView()
                    } label: {
                        Label(String(localized: "Privacy"), systemImage: "lock.shield")
                    }
                    
                    NavigationLink {
                        DataSettingsView()
                    } label: {
                        Label("Data", systemImage: "tray.full")
                    }
                }
                
                Section(String(localized: "Support")) {
                    NavigationLink {
                        AboutView()
                    } label: {
                        Label(String(localized: "About"), systemImage: "info.circle")
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    SettingsView()
}


