import SwiftUI

// MARK: - ActivityRow
// List row for ActivationTask in the Activities tab.

struct ActivityRow: View {
    let task: ActivationTask
    let category: ActivationCategory?
    var plannedTime: Date? = nil

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: task.listDisplaySFSymbol(category: category))
                .font(.system(size: IconSize.glyph, weight: .medium))
                .foregroundStyle(categoryColor)
                .iconContainer(
                    size: IconSize.card,
                    backgroundColor: categoryColor.opacity(Opacity.subtleBorder),
                    cornerRadius: CornerRadius.sm
                )

            VStack(alignment: .leading, spacing: Spacing.xxxs) {
                Text(task.localizedTitle)
                    .appFont(.h3)
                    .foregroundStyle(TextColors.primary)

                if let hint = task.localizedHint {
                    Text(hint)
                        .appFont(.small)
                        .foregroundStyle(TextColors.secondary)
                        .lineLimit(1)
                }

                HStack(spacing: Spacing.xxxs) {
                    if task.pleasureTag {
                        AppBadge(text: "P", style: .accent)
                            .accessibilityLabel(String(localized: "Pleasure"))
                    }
                    if task.masteryTag {
                        AppBadge(text: "M", style: .success)
                            .accessibilityLabel(String(localized: "Mastery"))
                    }
                    AppBadge(text: task.effortLevel.localizedName, style: .neutral)
                    if let time = plannedTime {
                        AppBadge(
                            text: time.formatted(.dateTime.hour().minute()),
                            style: .warning,
                            systemImage: "clock"
                        )
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, Spacing.xs)
        .padding(.horizontal, Spacing.sm)
    }

    private var categoryColor: Color {
        category?.color ?? AppColors.accent
    }
}

// MARK: - LogRow
// Compact row for completed/abandoned sessions in the Journal tab.

struct LogRow: View {
    let session: ActivationSession
    let task: ActivationTask?
    let category: ActivationCategory?

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: task.map { $0.listDisplaySFSymbol(category: category) } ?? category?.sfSymbol ?? "sparkles")
                .font(.system(size: IconSize.glyph, weight: .medium))
                .foregroundStyle(categoryColor)
                .iconContainer(
                    size: IconSize.card,
                    backgroundColor: categoryColor.opacity(Opacity.subtleBorder),
                    cornerRadius: CornerRadius.sm
                )

            VStack(alignment: .leading, spacing: Spacing.xxxs) {
                Text(task?.localizedTitle ?? "—")
                    .appFont(.h3)
                    .foregroundStyle(TextColors.primary)

                Text(subtitleText)
                    .appFont(.small)
                    .foregroundStyle(TextColors.secondary)
            }

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: Spacing.xxxs) {
                if let delta = session.moodDelta {
                    let symbol = delta > 0 ? "↑" : (delta < 0 ? "↓" : "→")
                    let prefix = delta > 0 ? "+" : ""
                    Text("\(prefix)\(delta) \(symbol)")
                        .appFont(.smallMedium)
                        .foregroundStyle(delta > 0 ? AppColors.positive : (delta < 0 ? AppColors.State.error : AppColors.gray400))
                }
                if let before = session.moodBefore, let after = session.moodAfter {
                    Text("\(Mood.emoji(for: before)) → \(Mood.emoji(for: after))")
                        .appFont(.buttonSmall)
                }
            }
        }
        .padding(.vertical, Spacing.xs)
        .padding(.horizontal, Spacing.sm)
    }

    private var categoryColor: Color {
        category?.color ?? AppColors.accent
    }

    private var subtitleText: String {
        var parts: [String] = []
        if let cat = category { parts.append(cat.localizedTitle) }
        if let completedAt = session.completedAt {
            parts.append(completedAt.formatted(.dateTime.hour().minute()))
        }
        if let minutes = session.actualMinutes {
            parts.append(String(format: String(localized: "%lld min"), Int64(minutes)))
        }
        return parts.joined(separator: " · ")
    }
}
