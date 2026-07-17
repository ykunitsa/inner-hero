import SwiftUI

struct AnxietyProgressChart: View {
    let anxietyBefore: Int
    let anxietyAfter: Int

    private var delta: Int { anxietyBefore - anxietyAfter }

    private var deltaColor: Color {
        if delta > 0 { return AppColors.positive }
        if delta < 0 { return AppColors.primary }
        return AppColors.State.warning
    }

    private var deltaIcon: String {
        if delta > 0 { return "arrow.down.circle.fill" }
        if delta < 0 { return "arrow.up.circle.fill" }
        return "minus.circle.fill"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Label(String(localized: "Anxiety dynamics"), systemImage: "chart.line.uptrend.xyaxis")
                .appFont(.h3)
                .foregroundStyle(TextColors.primary)
                .accessibilityAddTraits(.isHeader)

            HStack(alignment: .bottom, spacing: 0) {
                barColumn(
                    label: String(localized: "Before"),
                    value: anxietyBefore,
                    color: AppColors.primary
                )

                Spacer()

                deltaColumn

                Spacer()

                barColumn(
                    label: String(localized: "After"),
                    value: anxietyAfter,
                    color: AppColors.anxietyColor(for: anxietyAfter)
                )
            }
            .padding(Spacing.sm)
            .frame(height: 180)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                    .fill(AppColors.gray100)
            )

            HStack {
                Text("0 — \(String(localized: "No anxiety"))")
                    .appFont(.caption)
                    .foregroundStyle(TextColors.tertiary)
                Spacer()
                Text("10 — \(String(localized: "Maximum"))")
                    .appFont(.caption)
                    .foregroundStyle(TextColors.tertiary)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(String(format: String(localized: "Anxiety dynamics from %lld to %lld"), anxietyBefore, anxietyAfter))
    }

    private func barColumn(label: String, value: Int, color: Color) -> some View {
        VStack(spacing: Spacing.xxs) {
            Text("\(value)")
                .appFont(.h2)
                .foregroundStyle(color)
                .monospacedDigit()

            GeometryReader { geo in
                VStack(spacing: 0) {
                    Spacer()
                    RoundedRectangle(cornerRadius: CornerRadius.sm, style: .continuous)
                        .fill(color.opacity(Opacity.prominentBackground))
                        .overlay(alignment: .bottom) {
                            RoundedRectangle(cornerRadius: CornerRadius.sm, style: .continuous)
                                .fill(color)
                                .frame(height: geo.size.height * CGFloat(value) / 10.0)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm, style: .continuous))
                        .animation(AppAnimation.slow, value: value)
                }
            }

            Text(label)
                .appFont(.smallMedium)
                .foregroundStyle(TextColors.secondary)
        }
        .frame(width: 72)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    private var deltaColumn: some View {
        VStack(spacing: Spacing.xxxs) {
            Image(systemName: deltaIcon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(deltaColor)

            let deltaText = delta == 0 ? "0" : "\(abs(delta))"
            Text(deltaText)
                .appFont(.bodyMedium)
                .foregroundStyle(deltaColor)
                .monospacedDigit()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(delta > 0 ? "Decreased by \(abs(delta))" : (delta < 0 ? "Increased by \(abs(delta))" : "No change"))
    }
}
