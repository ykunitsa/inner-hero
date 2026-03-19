import SwiftUI
import SwiftData

struct ActivationCardView: View {
    let activation: ActivityList

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            header
            if !activation.localizedActivities.isEmpty {
                activitiesPreview
            }
            footer
        }
        .cardStyle(cornerRadius: CornerRadius.lg, padding: Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center, spacing: Spacing.xs) {
            Image(systemName: "figure.walk")
                .font(.system(size: IconSize.glyph, weight: .semibold))
                .foregroundStyle(AppColors.positive)
                .iconContainer(
                    size: IconSize.card,
                    backgroundColor: AppColors.positive.opacity(Opacity.softBackground),
                    cornerRadius: CornerRadius.sm
                )
                .accessibilityHidden(true)

            Text(activation.localizedTitle)
                .appFont(.h3)
                .foregroundStyle(TextColors.primary)
                .multilineTextAlignment(.leading)

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppColors.gray400)
        }
    }

    // MARK: - Activities preview (first 2, comma-separated)

    private var activitiesPreview: some View {
        Text(activation.localizedActivities.prefix(2).joined(separator: ", "))
            .appFont(.body)
            .foregroundStyle(TextColors.secondary)
            .lineLimit(1)
            .truncationMode(.tail)
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: Spacing.xs) {
            // Activity count tag
            let count = activation.localizedActivities.count
            Text(activitiesCountLabel(count))
                .appFont(.smallMedium)
                .foregroundStyle(AppColors.positive)
                .padding(.horizontal, Spacing.xxs)
                .padding(.vertical, Spacing.xxxs)
                .background(Capsule().fill(AppColors.positive.opacity(Opacity.subtleBackground)))

            // Predefined badge
            if activation.isPredefined {
                Text(String(localized: "Predefined"))
                    .appFont(.smallMedium)
                    .foregroundStyle(TextColors.tertiary)
                    .padding(.horizontal, Spacing.xxs)
                    .padding(.vertical, Spacing.xxxs)
                    .background(
                        Capsule().fill(AppColors.gray200)
                    )
            }
        }
    }

    // MARK: - Helpers

    private func activitiesCountLabel(_ count: Int) -> String {
        String(format: String(localized: "%d activities"), count)
    }
}
