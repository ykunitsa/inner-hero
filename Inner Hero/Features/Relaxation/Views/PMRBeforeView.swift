import SwiftUI

/// The "before" screen of the PMR flow (spec §5): confirm the step and start.
///
/// Quieter than its breathing counterpart on purpose. Breathing puts both of its
/// parameters on this screen because they fit; the five PMR steps need a
/// description and a length each, which does not, and the spec asks for
/// "сменить" → a list. So the fast path here is a single tap on "Start", and the
/// choice lives one quiet step away (principle 1.2).
struct PMRBeforeView: View {
    @Bindable var viewModel: PMRFlowViewModel
    /// Drives the `sessions == 0` rule (principle 1.7) — an explanation before
    /// the first session, nothing afterwards. Derived from the session count,
    /// never from a "has seen" flag.
    let hasSessions: Bool
    let onClose: () -> Void
    let onStart: () -> Void

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Spacer(minLength: Spacing.sm)
            stepBlock
            Spacer(minLength: Spacing.sm)
            stepSection
            suggestionLine
            listeningLine
        }
        .padding(.horizontal, Spacing.sm)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .top) { header }
        .safeAreaInset(edge: .bottom) { startButton }
        .formBackground()
        .ignoresSafeArea(.container, edges: .bottom)
    }

    // MARK: Header

    private var header: some View {
        ZStack {
            Text(String(localized: "Relaxation"))
                .appFont(.h3)
                .foregroundStyle(TextColors.primary)
                .lineLimit(1)
                .padding(.horizontal, TouchTarget.minimum + Spacing.xs)
            HStack {
                Spacer()
                CircleButton(systemImage: "xmark", background: AppColors.cardBackground) {
                    onClose()
                }
                .accessibilityLabel(String(localized: "Close"))
            }
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.top, Spacing.sm)
        .padding(.bottom, Spacing.xs)
        .pinnedHeaderBackground()
    }

    // MARK: Step

    private var stepBlock: some View {
        VStack(spacing: Spacing.xxs) {
            Image(systemName: "figure.mind.and.body")
                .appFont(.h2)
                .foregroundStyle(AppColors.positive)
                .frame(width: IconSize.hero, height: IconSize.hero)
                .background(
                    Circle().fill(AppColors.positive.opacity(Opacity.softBackground))
                )
                .accessibilityHidden(true)

            Text(viewModel.step.title)
                .appFont(.h2)
                .foregroundStyle(TextColors.primary)

            // Computed from the script, never a hardcoded number: tuning the
            // timings moves this label with the exercise.
            Text(minutesText)
                .appFont(.small)
                .foregroundStyle(TextColors.secondary)

            Text(viewModel.step.summary)
                .appFont(.small)
                .foregroundStyle(TextColors.tertiary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, Spacing.md)

            if !hasSessions {
                Text(
                    String(
                        localized: "Tense the muscles, then let them go. Letting go is the part being trained."
                    )
                )
                .appFont(.small)
                .foregroundStyle(TextColors.tertiary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.xs)
            }
        }
        .frame(maxWidth: .infinity)
        .animation(AppAnimation.fast, value: viewModel.step)
    }

    /// The ladder, on the screen it belongs to. The row is bounded by the
    /// screen edges rather than by a "Change" button — the default is still the
    /// last step used, so doing nothing and tapping "Start" remains the fast
    /// path (principle 1.2), but switching is now one tap instead of three.
    private var stepSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            SectionLabel(text: String(localized: "Step"))
            PMRStepCards(selection: $viewModel.step)
        }
    }

    // MARK: Lines

    /// The ladder rule as a line the user may take or ignore. It never changes
    /// the step by itself (principle 1.8), and there is no placeholder when it
    /// has nothing to say.
    @ViewBuilder
    private var suggestionLine: some View {
        if let suggestion = viewModel.suggestion {
            Button {
                viewModel.applySuggestion()
                HapticFeedback.light()
            } label: {
                HStack(spacing: Spacing.xxs) {
                    Image(systemName: suggestionGlyph(suggestion))
                        .appFont(.bodyMedium)
                        .accessibilityHidden(true)
                    Text(suggestionText(suggestion))
                        .appFont(.small)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
                .foregroundStyle(AppColors.accent)
                .padding(Spacing.xs)
                .frame(maxWidth: .infinity, minHeight: TouchTarget.minimum)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                        .fill(AppColors.accent.opacity(Opacity.softBackground))
                )
            }
            .buttonStyle(.plain)
            .transition(.opacity)
        }
    }

    /// The exercise is carried entirely by the voice, so this is a setup
    /// condition, not a tip.
    private var listeningLine: some View {
        Text(String(localized: "Headphones or a quiet place. The voice will guide you."))
            .appFont(.small)
            .foregroundStyle(TextColors.tertiary)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, Spacing.md)
    }

    private var startButton: some View {
        PrimaryButton(title: String(localized: "Start")) { onStart() }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.lg)
            .pinnedFooterBackground()
    }

    // MARK: Copy

    private var minutesText: String {
        String(
            format: String(localized: "~%@ min"),
            PMRLadder.minutesLabel(duration: viewModel.step.estimatedDuration)
        )
    }

    private func suggestionGlyph(_ suggestion: PMRLadder.Suggestion) -> String {
        switch suggestion {
        case .stepDown: "arrow.down"
        case .stepUp: "arrow.up"
        }
    }

    private func suggestionText(_ suggestion: PMRLadder.Suggestion) -> String {
        switch suggestion {
        case .stepDown(let step):
            String(
                format: String(localized: "Five in a row you managed to relax. Try %@?"),
                step.title
            )
        case .stepUp(let step):
            String(
                format: String(localized: "Twice in a row you didn't. Back to %@?"),
                step.title
            )
        }
    }
}

#Preview {
    PMRBeforeView(
        viewModel: PMRFlowViewModel(),
        hasSessions: false,
        onClose: {},
        onStart: {}
    )
}
