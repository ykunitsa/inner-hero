import SwiftUI

struct PrivacySettingsView: View {
    @AppStorage(AppStorageKeys.appLockEnabled) private var appLockEnabled: Bool = false
    
    var body: some View {
        Form {
            Section {
                Toggle(String(localized: "App lock (Face ID)"), isOn: $appLockEnabled)
            } footer: {
                Text(String(localized: "When enabled, the app will ask for identity verification only when launching."))
            }
        }
        .navigationTitle(String(localized: "Privacy"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        PrivacySettingsView()
    }
}


