import SwiftUI

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {

                // App card
                HStack(spacing: Spacing.sm) {
                    RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [AppColors.primary, AppColors.primary.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: IconSize.hero, height: IconSize.hero)
                        .overlay {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 26, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Inner Hero")
                            .appFont(.h2)
                            .foregroundStyle(TextColors.primary)
                        Text(String(localized: "CBT Tools for daily practice"))
                            .appFont(.small)
                            .foregroundStyle(TextColors.secondary)
                    }
                }
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
                .cardStyle(cornerRadius: CornerRadius.lg, padding: 0)

                // Version info
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    SectionLabel(text: String(localized: "Information"))

                    VStack(spacing: 0) {
                        infoRow(label: String(localized: "Version"), value: shortVersion)
                        Divider().padding(.leading, Spacing.sm)
                        infoRow(label: String(localized: "Build"), value: buildNumber)
                    }
                    .cardStyle(cornerRadius: CornerRadius.lg, padding: 0)
                }

                // Support
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    SectionLabel(text: String(localized: "Support"))

                    let email = "coder.ekunitsa@gmail.com"
                    if let mailURL = URL(string: "mailto:\(email)") {
                        Link(destination: mailURL) {
                            HStack(spacing: Spacing.xs) {
                                Image(systemName: "envelope.fill")
                                    .font(.system(size: IconSize.glyph, weight: .medium))
                                    .foregroundStyle(AppColors.accent)
                                    .iconContainer(
                                        size: IconSize.card,
                                        backgroundColor: AppColors.accent.opacity(Opacity.softBackground),
                                        cornerRadius: CornerRadius.sm
                                    )
                                    .accessibilityHidden(true)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(String(localized: "Contact support"))
                                        .appFont(.bodyMedium)
                                        .foregroundStyle(TextColors.primary)
                                    Text(email)
                                        .appFont(.small)
                                        .foregroundStyle(TextColors.secondary)
                                }

                                Spacer()

                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(AppColors.gray400)
                            }
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, Spacing.xs)
                            .cardStyle(cornerRadius: CornerRadius.lg, padding: 0)
                        }
                        .buttonStyle(.plain)
                    }

                    Text(String(localized: "If you found an issue or want to suggest an improvement — write to us."))
                        .appFont(.small)
                        .foregroundStyle(TextColors.secondary)
                        .padding(.horizontal, Spacing.xxs)
                }
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.xxl)
        }
        .homeBackground()
        .navigationTitle(String(localized: "About"))
        .navigationBarTitleDisplayMode(.large)
    }

    private var shortVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .appFont(.bodyMedium)
                .foregroundStyle(TextColors.primary)
            Spacer()
            Text(value)
                .appFont(.body)
                .foregroundStyle(TextColors.secondary)
                .monospacedDigit()
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
    }
}

#Preview {
    NavigationStack {
        AboutView()
    }
}
