import SwiftUI

// MARK: - ActivityPill
// Compact header pill shown on PreSession, ActiveSession, SchedulePicker, and SessionDetail screens.

struct ActivityPill: View {
    let task: ActivationTask
    let category: ActivationCategory?

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: task.listDisplaySFSymbol(category: category))
                .font(.system(size: IconSize.glyph, weight: .medium))
                .foregroundStyle(categoryColor)
                .iconContainer(
                    size: IconSize.action,
                    backgroundColor: categoryColor.opacity(Opacity.mediumBackground),
                    cornerRadius: CornerRadius.sm
                )

            VStack(alignment: .leading, spacing: Spacing.tight) {
                Text(task.localizedTitle)
                    .appFont(.h3)
                    .foregroundStyle(TextColors.primary)

                Text(subtitleText)
                    .appFont(.small)
                    .foregroundStyle(TextColors.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(Spacing.sm)
        .cardStyle(cornerRadius: CornerRadius.md, padding: 0)
    }

    private var categoryColor: Color {
        category?.color ?? AppColors.accent
    }

    private var subtitleText: String {
        var parts: [String] = []
        if let cat = category { parts.append(cat.localizedTitle) }
        parts.append(task.effortLevel.localizedName)
        return parts.joined(separator: " · ")
    }
}
