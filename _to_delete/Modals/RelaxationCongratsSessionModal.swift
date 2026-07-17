import SwiftUI

// MARK: - Relaxation Congrats Session Modal

struct RelaxationCongratsSessionModal: View {
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Icon + title + subtitle
            VStack(spacing: Spacing.md) {
                Image(systemName: "sparkles")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(AppColors.positive)
                    .iconContainer(
                        size: IconSize.hero,
                        backgroundColor: AppColors.positiveLight,
                        cornerRadius: CornerRadius.pill
                    )
                    .accessibilityHidden(true)

                VStack(spacing: Spacing.xxxs) {
                    Text("Well done!")
                        .appFont(.h1)
                        .foregroundStyle(TextColors.primary)
                        .multilineTextAlignment(.center)

                    Text("You completed a relaxation exercise—that's self-care.")
                        .appFont(.body)
                        .foregroundStyle(TextColors.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.top, Spacing.xxl)
            .padding(.bottom, Spacing.md)

            // Achievements section
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("What you achieved")
                    .appFont(.h3)
                    .foregroundStyle(TextColors.primary)

                tipRow(icon: "hand.raised.fill",
                       text: "You noticed the tension and allowed it to leave.")
                tipRow(icon: "arrow.counterclockwise",
                       text: "Regularly returning to calm matters more than perfection.")
                tipRow(icon: "heart.circle.fill",
                       text: "Let your body feel a little lighter—step by step.")
            }
            .cardStyle()
            .padding(.horizontal, Spacing.lg)

            Spacer()

            PrimaryButton(title: "Great", systemImage: "checkmark", color: AppColors.positive) {
                onDone()
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.lg)
            .accessibilityLabel("Close")
        }
        .pageBackground()
    }

    private func tipRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.xxs) {
            Image(systemName: icon)
                .font(.system(size: IconSize.glyph))
                .foregroundStyle(AppColors.positive)
                .frame(width: 22, alignment: .center)
                .padding(.top, 1)
                .accessibilityHidden(true)

            Text(LocalizedStringKey(text))
                .appFont(.body)
                .foregroundStyle(TextColors.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    RelaxationCongratsSessionModal(onDone: { })
        .padding()
}
