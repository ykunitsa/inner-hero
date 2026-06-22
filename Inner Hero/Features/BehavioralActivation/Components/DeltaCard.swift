import SwiftUI

// MARK: - DeltaCard
// Shows mood before and after with emoji and a coloured delta badge.
// Live-updating: when moodAfter changes the right column animates.

struct DeltaCard: View {
    let moodBefore: Int?
    let moodAfter: Int?

    private var delta: Int? {
        guard let b = moodBefore, let a = moodAfter else { return nil }
        return a - b
    }

    private var afterColor: Color {
        guard let d = delta else { return TextColors.primary }
        if d > 0 { return AppColors.positive }
        if d < 0 { return AppColors.State.error }
        return AppColors.gray400
    }

    var body: some View {
        HStack(spacing: 0) {
            columnView(label: String(localized: "Before"), value: moodBefore, color: TextColors.primary, showDelta: false)

            Rectangle()
                .fill(AppColors.gray200)
                .frame(width: BorderWidth.hairline)
                .padding(.vertical, Spacing.sm)

            columnView(label: String(localized: "After"), value: moodAfter, color: afterColor, showDelta: true)
        }
        .frame(maxWidth: .infinity)
        .cardStyle(cornerRadius: CornerRadius.md, padding: 0)
    }

    @ViewBuilder
    private func columnView(label: String, value: Int?, color: Color, showDelta: Bool) -> some View {
        VStack(spacing: Spacing.xxxs) {
            Text(label)
                .appFont(.caption)
                .foregroundStyle(color)

            ZStack {
                if let v = value {
                    Text(Mood.emoji(for: v))
                        .font(.system(size: IconSize.emptyState))
                        .id(v)
                        .transition(
                            .asymmetric(
                                insertion: .scale(scale: 0.6).combined(with: .opacity),
                                removal:   .scale(scale: 0.6).combined(with: .opacity)
                            )
                        )
                } else {
                    Text("😶")
                        .font(.system(size: IconSize.emptyState))
                        .opacity(0.3)
                        .id(-1)
                }
            }
            .frame(height: MoodLayout.emojiWellHeight)
            .animation(AppAnimation.standard, value: value)

            if showDelta {
                deltaBadgeView
            } else {
                Color.clear.frame(height: MoodLayout.deltaPlaceholderHeight)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.sm)
    }

    @ViewBuilder
    private var deltaBadgeView: some View {
        if let d = delta {
            let symbol = d > 0 ? "↑" : (d < 0 ? "↓" : "→")
            let prefix  = d > 0 ? "+" : ""
            let bgColor: Color = d > 0 ? AppColors.positive : (d < 0 ? AppColors.State.error : AppColors.gray400)

            Text("\(prefix)\(d) \(symbol)")
                .appFont(.smallMedium)
                .foregroundStyle(.white)
                .padding(.horizontal, Spacing.xxs)
                .padding(.vertical, 3)
                .background(Capsule().fill(bgColor))
                .transition(.scale.combined(with: .opacity))
                .animation(AppAnimation.spring, value: d)
        } else {
            Color.clear.frame(height: MoodLayout.deltaPlaceholderHeight)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: Spacing.sm) {
        DeltaCard(moodBefore: 4, moodAfter: 7)
        DeltaCard(moodBefore: 6, moodAfter: 4)
        DeltaCard(moodBefore: 5, moodAfter: nil)
    }
    .padding()
    .pageBackground()
}
