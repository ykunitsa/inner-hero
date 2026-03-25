import SwiftUI

struct OnboardingView: View {
    @AppStorage(AppStorageKeys.hasCompletedOnboarding) private var hasCompletedOnboarding = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                heroSection
                    .padding(.top, Spacing.xxxl)
                    .padding(.bottom, Spacing.xl)

                contentSection
                    .padding(.horizontal, Spacing.sm)

                continueButton
                    .padding(.horizontal, Spacing.sm)
                    .padding(.top, Spacing.xl)
                    .padding(.bottom, Spacing.xxl)
            }
        }
        .homeBackground()
        .scrollDismissesKeyboard(.interactively)
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: Spacing.md) {
            RoundedRectangle(cornerRadius: CornerRadius.xl, style: .continuous)
                .fill(AppColors.primaryLight)
                .frame(width: 96, height: 96)
                .overlay {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundStyle(AppColors.primary)
                }
                .accessibilityHidden(true)

            VStack(spacing: Spacing.xxxs) {
                Text("Inner Hero")
                    .appFont(.display)
                    .foregroundStyle(TextColors.primary)

                Text(String(localized: "CBT Tools for daily practice"))
                    .appFont(.body)
                    .foregroundStyle(TextColors.secondary)
            }
        }
    }

    // MARK: - Content

    private var contentSection: some View {
        VStack(spacing: Spacing.sm) {
            welcomeCard
            warningCard
        }
    }

    private var welcomeCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "sparkles")
                    .font(.system(size: IconSize.glyph, weight: .medium))
                    .foregroundStyle(AppColors.primary)
                    .iconContainer(
                        size: IconSize.card,
                        backgroundColor: AppColors.primaryLight,
                        cornerRadius: CornerRadius.sm
                    )
                    .accessibilityHidden(true)

                Text(String(localized: "Welcome"))
                    .appFont(.h3)
                    .foregroundStyle(TextColors.primary)
            }

            Text(String(localized: "Inner Hero helps you practice exposure therapy for anxiety. Create scenarios, run sessions, and track your progress."))
                .appFont(.body)
                .foregroundStyle(TextColors.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var warningCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: IconSize.glyph, weight: .medium))
                    .foregroundStyle(AppColors.State.warning)
                    .iconContainer(
                        size: IconSize.card,
                        backgroundColor: AppColors.State.warning.opacity(Opacity.softBackground),
                        cornerRadius: CornerRadius.sm
                    )
                    .accessibilityHidden(true)

                Text(String(localized: "Important notice"))
                    .appFont(.h3)
                    .foregroundStyle(TextColors.primary)
            }

            VStack(alignment: .leading, spacing: Spacing.xs) {
                warningRow(
                    icon: "xmark.circle",
                    text: String(localized: "This app **does not replace** professional psychotherapy or medical care.")
                )

                warningRow(
                    icon: "person.fill.questionmark",
                    text: String(localized: "If you experience serious symptoms of anxiety or other mental health conditions, please contact a qualified professional.")
                )

                warningRow(
                    icon: "plus.circle",
                    text: String(localized: "Use this app as an additional tool as part of a comprehensive approach to your mental health care.")
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous)
                .strokeBorder(AppColors.State.warning.opacity(Opacity.emphasizedBorder), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }

    private func warningRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.xxs) {
            Image(systemName: icon)
                .font(.system(size: IconSize.glyph - 2))
                .foregroundStyle(AppColors.State.warning.opacity(0.8))
                .frame(width: 22, alignment: .center)
                .padding(.top, 1)
                .accessibilityHidden(true)

            Text(text)
                .appFont(.body)
                .foregroundStyle(TextColors.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Continue Button

    private var continueButton: some View {
        PrimaryButton(
            title: String(localized: "Continue"),
            systemImage: "arrow.right",
            color: AppColors.primary
        ) {
            HapticFeedback.success()
            withAnimation(reduceMotion ? .none : AppAnimation.standard) {
                hasCompletedOnboarding = true
            }
        }
        .accessibilityLabel(String(localized: "Continue"))
        .accessibilityHint(String(localized: "Finish onboarding and go to the app"))
    }
}

#Preview {
    OnboardingView()
}
