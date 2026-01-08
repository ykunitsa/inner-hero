import SwiftUI

struct PrivacySettingsView: View {
    @AppStorage(AppStorageKeys.appLockEnabled) private var appLockEnabled: Bool = false
    
    var body: some View {
        Form {
            Section {
                Toggle("Блокировка приложения (Face ID)", isOn: $appLockEnabled)
            } footer: {
                Text("При включении приложение будет запрашивать подтверждение личности только при запуске.")
            }
        }
        .navigationTitle("Конфиденциальность")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        PrivacySettingsView()
    }
}


