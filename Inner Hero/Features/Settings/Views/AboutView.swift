import SwiftUI

struct AboutView: View {
    var body: some View {
        Form {
            Section {
                HStack(spacing: 12) {
                    Image(systemName: "leaf.circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.blue)
                        .accessibilityHidden(true)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Inner Hero")
                            .font(.title3.weight(.semibold))
                        Text(versionString)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 6)
            }
            
            Section("Информация") {
                infoRow(title: "Версия", value: shortVersion)
                infoRow(title: "Сборка", value: buildNumber)
            }
            
            Section("Поддержка") {
                let email = "support@innerhero.app"
                Text("Если вы нашли проблему или хотите предложить улучшение — напишите нам.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                
                if let mailURL = URL(string: "mailto:\(email)") {
                    Link("Написать в поддержку: \(email)", destination: mailURL)
                } else {
                    Text(email)
                        .font(.callout.weight(.semibold))
                }
            }
        }
        .navigationTitle("О приложении")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var shortVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }
    
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
    }
    
    private var versionString: String {
        "Версия \(shortVersion) (\(buildNumber))"
    }
    
    private func infoRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    NavigationStack {
        AboutView()
    }
}


