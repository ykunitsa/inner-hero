import SwiftUI

/// Settings, reachable from the gear on the Today tab (no separate tab in 2.0).
/// Data export/reset returns together with the new log models.
struct SettingsView: View {
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {

                // App card
                appCard

                // Preferences
                settingsSection(title: String(localized: "Preferences")) {
                    navRow(
                        icon: "paintbrush.fill",
                        iconColor: AppColors.accent,
                        title: String(localized: "Appearance"),
                        route: AppRoute.settingsAppearance
                    )
                    rowDivider
                    navRow(
                        icon: "lock.shield.fill",
                        iconColor: AppColors.positive,
                        title: String(localized: "Privacy"),
                        route: AppRoute.settingsPrivacy
                    )
                }

                // Spec §7: the crisis section shown during onboarding stays
                // here afterwards — that screen promises it, and this is where
                // the promise is kept. Above "About" on purpose: it is not
                // trivia about the app.
                settingsSection(title: String(localized: "If things get really bad")) {
                    linkRow(
                        icon: "phone.arrow.up.right.fill",
                        iconColor: AppColors.accent,
                        title: String(localized: "Find a helpline in your country"),
                        subtitle: "findahelpline.com",
                        url: CrisisHelplineLink.url
                    )
                    rowDivider
                    // A full sentence, not a label/value row: "Immediate danger
                    // — Emergency number" is terse to the point of ambiguity,
                    // and this is the one place in the app where a reader must
                    // not have to work out what is meant.
                    Text(
                        String(
                            localized: "If there is immediate danger, call your country's emergency number."
                        )
                    )
                    .appFont(.small)
                    .foregroundStyle(TextColors.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xs)
                }

                // About
                settingsSection(title: String(localized: "About")) {
                    infoRow(
                        icon: "info.circle.fill",
                        iconColor: AppColors.gray400,
                        title: String(localized: "Version"),
                        value: "\(appVersion) (\(buildNumber))"
                    )
                    rowDivider
                    let email = "coder.ekunitsa@gmail.com"
                    if let mailURL = URL(string: "mailto:\(email)") {
                        linkRow(
                            icon: "envelope.fill",
                            iconColor: AppColors.accent,
                            title: String(localized: "Contact support"),
                            subtitle: email,
                            url: mailURL
                        )
                    }
                }
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.xxl)
        }
        .homeBackground()
        .navigationTitle(String(localized: "Settings"))
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - App Card

    private var appCard: some View {
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
                    .appFont(.h3)
                    .foregroundStyle(TextColors.primary)
                Text("v\(appVersion) (\(buildNumber))")
                    .appFont(.small)
                    .foregroundStyle(TextColors.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .cardStyle(cornerRadius: CornerRadius.lg, padding: 0)
    }

    // MARK: - Section builder

    private func settingsSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            SectionLabel(text: title)
            VStack(spacing: 0) {
                content()
            }
            .cardStyle(cornerRadius: CornerRadius.lg, padding: 0)
        }
    }

    private var rowDivider: some View {
        Divider()
            .padding(.leading, Spacing.sm + IconSize.card + Spacing.xs)
    }

    // MARK: - Row types

    private func navRow(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String? = nil,
        route: AppRoute
    ) -> some View {
        NavigationLink(value: route) {
            rowContent(icon: icon, iconColor: iconColor, title: title,
                       subtitle: subtitle, trailing: .chevron)
        }
        .buttonStyle(.plain)
    }

    private func linkRow(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String? = nil,
        url: URL
    ) -> some View {
        Link(destination: url) {
            rowContent(icon: icon, iconColor: iconColor, title: title,
                       subtitle: subtitle, trailing: .external)
        }
        .buttonStyle(.plain)
    }

    private func infoRow(
        icon: String,
        iconColor: Color,
        title: String,
        value: String
    ) -> some View {
        rowContent(icon: icon, iconColor: iconColor, title: title,
                   trailing: .value(value))
    }

    // MARK: - Shared row content

    private enum RowTrailing {
        case chevron
        case external
        case value(String)
        case none
    }

    private func rowContent(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String? = nil,
        trailing: RowTrailing = .chevron
    ) -> some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: IconSize.glyph - 1, weight: .medium))
                .foregroundStyle(iconColor)
                .iconContainer(
                    size: IconSize.card,
                    backgroundColor: iconColor.opacity(Opacity.softBackground),
                    cornerRadius: CornerRadius.sm
                )
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .appFont(.bodyMedium)
                    .foregroundStyle(TextColors.primary)
                if let subtitle {
                    Text(subtitle)
                        .appFont(.small)
                        .foregroundStyle(TextColors.secondary)
                }
            }

            Spacer(minLength: 0)

            switch trailing {
            case .chevron:
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppColors.gray400)
            case .external:
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppColors.gray400)
            case .value(let text):
                Text(text)
                    .appFont(.small)
                    .foregroundStyle(TextColors.secondary)
                    .monospacedDigit()
            case .none:
                EmptyView()
            }
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SettingsView()
    }
}
