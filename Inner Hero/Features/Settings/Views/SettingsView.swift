import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            Form {
                Section("Настройки") {
                    NavigationLink {
                        AppearanceSettingsView()
                    } label: {
                        Label("Внешний вид", systemImage: "paintbrush")
                    }
                    
                    NavigationLink {
                        PrivacySettingsView()
                    } label: {
                        Label("Конфиденциальность", systemImage: "lock.shield")
                    }
                    
                    NavigationLink {
                        DataSettingsView()
                    } label: {
                        Label("Данные", systemImage: "tray.full")
                    }
                }
                
                Section("Поддержка") {
                    NavigationLink {
                        AboutView()
                    } label: {
                        Label("О приложении", systemImage: "info.circle")
                    }
                }
            }
            .navigationTitle("Настройки")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    SettingsView()
}


