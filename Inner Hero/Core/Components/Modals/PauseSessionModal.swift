import SwiftUI

// MARK: - Pause Session Modal

struct PauseSessionModal: View {
    let onResume: () -> Void
    let onEnd: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Title + subtitle
            VStack(spacing: Spacing.xxxs) {
                Text("You're doing great!")
                    .appFont(.h1)
                    .foregroundStyle(TextColors.primary)
                    .multilineTextAlignment(.center)

                Text("Take a moment. You can continue when you're ready.")
                    .appFont(.body)
                    .foregroundStyle(TextColors.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, Spacing.xxl)
            .padding(.bottom, Spacing.md)

            // Supportive messages — single card with header
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("While you pause")
                    .appFont(.h3)
                    .foregroundStyle(TextColors.primary)

                tipRow(icon: "pause.circle.fill", text: "Take a short break")
                tipRow(icon: "wind",              text: "Breathe and reset")
                tipRow(icon: "sparkles",          text: "Progress over perfection")
            }
            .cardStyle()
            .padding(.horizontal, Spacing.lg)

            Spacer()

            // Action buttons
            HStack(spacing: Spacing.xs) {
                Button(action: onResume) {
                    HStack(spacing: Spacing.xxs) {
                        Image(systemName: "play.fill")
                            .font(.system(size: IconSize.glyph, weight: .semibold))
                            .accessibilityHidden(true)
                        Text("Continue")
                            .appFont(.buttonPrimary)
                    }
                    .foregroundStyle(TextColors.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Capsule().fill(AppColors.gray100))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Continue session")
                .accessibilityHint("Double-tap to return to session")

                PrimaryButton(title: "Finish", systemImage: "flag.checkered", color: AppColors.primary) {
                    onEnd()
                }
                .accessibilityLabel("Finish for today")
                .accessibilityHint("Double-tap to end session without saving")
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.lg)
        }
        .pageBackground()
    }

    private func tipRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.xxs) {
            Image(systemName: icon)
                .font(.system(size: IconSize.glyph))
                .foregroundStyle(AppColors.primary)
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
