import SwiftUI

struct AppearanceSettingsView: View {
    @AppStorage(AppStorageKeys.themeMode) private var themeModeRawValue: String = ThemeMode.system.rawValue
    
    var body: some View {
        Form {
            Section(String(localized: "Theme")) {
                Picker(selection: $themeModeRawValue) {
                    ForEach(ThemeMode.allCases) { mode in
                        Text(mode.title).tag(mode.rawValue)
                    }
                } label: {
                    EmptyView()
                }
                .labelsHidden()
                .pickerStyle(.inline)
            }
        }
        .navigationTitle(String(localized: "Appearance"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        AppearanceSettingsView()
    }
}


