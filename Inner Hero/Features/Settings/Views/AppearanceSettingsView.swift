import SwiftUI

struct AppearanceSettingsView: View {
    @AppStorage(AppStorageKeys.themeMode) private var themeModeRawValue: String = ThemeMode.system.rawValue
    
    var body: some View {
        Form {
            Section("Тема") {
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
        .navigationTitle("Внешний вид")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        AppearanceSettingsView()
    }
}


