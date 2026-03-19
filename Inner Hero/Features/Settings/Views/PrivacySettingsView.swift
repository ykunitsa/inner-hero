import SwiftUI

struct PrivacySettingsView: View {
    @AppStorage(AppStorageKeys.appLockEnabled) private var appLockEnabled: Bool = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    SectionLabel(text: String(localized: "Security"))

                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "faceid")
                            .font(.system(size: IconSize.glyph, weight: .medium))
                            .foregroundStyle(AppColors.positive)
                            .iconContainer(
                                size: IconSize.card,
                                backgroundColor: AppColors.positive.opacity(Opacity.softBackground),
                                cornerRadius: CornerRadius.sm
                            )
                            .accessibilityHidden(true)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(String(localized: "App lock (Face ID)"))
                                .appFont(.bodyMedium)
                                .foregroundStyle(TextColors.primary)
                            Text(String(localized: "Require Face ID on launch"))
                                .appFont(.small)
                                .foregroundStyle(TextColors.secondary)
                        }

                        Spacer()

                        Toggle("", isOn: $appLockEnabled)
                            .labelsHidden()
                            .tint(AppColors.primary)
                    }
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xs)
                    .cardStyle(cornerRadius: CornerRadius.lg, padding: 0)
                }

                // Footer
                Text(String(localized: "When enabled, the app will ask for identity verification only when launching."))
                    .appFont(.small)
                    .foregroundStyle(TextColors.secondary)
                    .padding(.horizontal, Spacing.xxs)
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.xxl)
        }
        .homeBackground()
        .navigationTitle(String(localized: "Privacy"))
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    NavigationStack {
        PrivacySettingsView()
    }
}
