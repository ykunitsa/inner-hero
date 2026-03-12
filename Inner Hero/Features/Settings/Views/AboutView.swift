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
            
            Section("Information") {
                infoRow(title: "Version", value: shortVersion)
                infoRow(title: "Build", value: buildNumber)
            }
            
            Section("Support") {
                let email = "coder.ekunitsa@gmail.com"
                Text("If you found an issue or want to suggest an improvement—write to us.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                
                if let mailURL = URL(string: "mailto:\(email)") {
                    Link(String(format: NSLocalizedString("Contact support: %@", comment: ""), email), destination: mailURL)
                } else {
                    Text(email)
                        .font(.callout.weight(.semibold))
                }
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var shortVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }
    
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
    }
    
    private var versionString: String {
        String(
            format: NSLocalizedString("Version %1$@ (%2$@)", comment: ""),
            shortVersion,
            buildNumber
        )
    }
    
    private func infoRow(title: LocalizedStringKey, value: String) -> some View {
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


