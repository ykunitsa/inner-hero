import SwiftUI

struct AppearanceSettingsView: View {
    @AppStorage(AppStorageKeys.themeMode) private var themeModeRawValue: String = ThemeMode.system.rawValue

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    SectionLabel(text: String(localized: "Theme"))

                    VStack(spacing: 0) {
                        ForEach(Array(ThemeMode.allCases.enumerated()), id: \.element.id) { index, mode in
                            themeRow(mode)
                            if index < ThemeMode.allCases.count - 1 {
                                Divider()
                                    .padding(.leading, Spacing.sm + IconSize.card + Spacing.xs)
                            }
                        }
                    }
                    .cardStyle(cornerRadius: CornerRadius.lg, padding: 0)
                }
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.xxl)
        }
        .homeBackground()
        .navigationTitle(String(localized: "Appearance"))
        .navigationBarTitleDisplayMode(.large)
    }

    private func themeRow(_ mode: ThemeMode) -> some View {
        let isSelected = themeModeRawValue == mode.rawValue

        return Button {
            themeModeRawValue = mode.rawValue
            HapticFeedback.selection()
        } label: {
            HStack(spacing: Spacing.xs) {
                Image(systemName: modeIcon(mode))
                    .font(.system(size: IconSize.glyph, weight: .medium))
                    .foregroundStyle(isSelected ? AppColors.accent : AppColors.gray400)
                    .iconContainer(
                        size: IconSize.card,
                        backgroundColor: (isSelected ? AppColors.accent : AppColors.gray400).opacity(Opacity.softBackground),
                        cornerRadius: CornerRadius.sm
                    )
                    .accessibilityHidden(true)

                Text(mode.title)
                    .appFont(.bodyMedium)
                    .foregroundStyle(TextColors.primary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(AppColors.accent)
                }
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func modeIcon(_ mode: ThemeMode) -> String {
        switch mode {
        case .system: return "circle.lefthalf.filled"
        case .light:  return "sun.max.fill"
        case .dark:   return "moon.fill"
        }
    }
}

#Preview {
    NavigationStack {
        AppearanceSettingsView()
    }
}
