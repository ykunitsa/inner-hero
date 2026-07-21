import SwiftUI

/// The "before" screen of the breathing flow (spec §4): confirm or change two
/// parameters and start. Both come seeded from the last session, so doing
/// nothing and tapping "Start" is the fast path.
struct BreathingBeforeView: View {
    @Bindable var viewModel: BreathingFlowViewModel
    let onClose: () -> Void
    let onStart: () -> Void

    var body: some View {
        // Not a ScrollView: the controls are pinned to the bottom, within
        // thumb reach, and the description takes whatever is left above them.
        // A scroll would let that arrangement slide out from under the thumb.
        VStack(spacing: Spacing.lg) {
            Spacer(minLength: Spacing.sm)
            selectedTypeBlock
            Spacer(minLength: Spacing.sm)
            typeSection
            durationSection
            suggestionLine
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
            Text(String(localized: "Breathing"))
                .appFont(.h3)
                .foregroundStyle(TextColors.primary)
                .lineLimit(1)
                .padding(.horizontal, TouchTarget.minimum + Spacing.xs)
            HStack {
                Spacer()
                // Closes straight away, no confirmation: nothing here was typed
                // — both fields are seeded and there is no draft to lose.
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

    // MARK: Selected type

    /// The description lives here, once, for the selected type — not inside the
    /// three cards, where each sentence would be two words wide.
    ///
    /// It says what the pattern *is* and how demanding it is, never what it
    /// gives you or when to reach for it: that line would be a recommendation
    /// (principle 1.1) on the user's own path (1.3).
    private var selectedTypeBlock: some View {
        VStack(spacing: Spacing.xxs) {
            Image(systemName: viewModel.pattern.icon)
                .appFont(.h2)
                .foregroundStyle(AppColors.positive)
                .frame(width: IconSize.hero, height: IconSize.hero)
                .background(
                    Circle().fill(AppColors.positive.opacity(Opacity.softBackground))
                )

            Text(viewModel.pattern.title)
                .appFont(.h2)
                .foregroundStyle(TextColors.primary)

            Text(viewModel.pattern.formula)
                .appFont(.small)
                .foregroundStyle(TextColors.secondary)

            Text(viewModel.pattern.summary)
                .appFont(.small)
                .foregroundStyle(TextColors.tertiary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, Spacing.md)
        }
        .frame(maxWidth: .infinity)
        .animation(AppAnimation.fast, value: viewModel.pattern)
        .accessibilityElement(children: .combine)
    }

    // MARK: Sections

    private var typeSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            SectionLabel(text: String(localized: "Type"))
            BreathingTypeCards(selection: $viewModel.pattern)
        }
    }

    private var durationSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            SectionLabel(text: String(localized: "Duration"))
            ScrollingTickRuler(
                // Ascending left to right: the tape reads like a ruler, even
                // though the ladder itself is stored top-down.
                values: Array(BreathingLadder.steps.reversed()),
                selection: $viewModel.plannedDuration,
                label: { minutesText(seconds: $0) },
                accessibilityValue: { minutesText(seconds: $0) }
            )
        }
    }

    /// The ladder rule, as a line the user may take or ignore. It never changes
    /// the duration by itself (principle 1.8), and there is no placeholder when
    /// it has nothing to say.
    ///
    /// Its permanent home is the History tab (spec §2.3); History is a
    /// placeholder until §11.6, and this is where the duration is actually
    /// chosen.
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

    private var startButton: some View {
        PrimaryButton(title: String(localized: "Start")) { onStart() }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.lg)
            .pinnedFooterBackground()
    }

    // MARK: Copy

    private func minutesText(seconds: Int) -> String {
        String(
            format: String(localized: "%@ min"),
            BreathingLadder.minutesLabel(seconds: seconds)
        )
    }

    private func suggestionGlyph(_ suggestion: BreathingLadder.Suggestion) -> String {
        switch suggestion {
        case .stepDown: "arrow.down"
        case .stepUp: "arrow.up"
        }
    }

    private func suggestionText(_ suggestion: BreathingLadder.Suggestion) -> String {
        let minutes = BreathingLadder.minutesLabel(seconds: suggestion.seconds)
        switch suggestion {
        case .stepDown:
            return String(
                format: String(localized: "Five in a row you relaxed in time. Try %@ min?"),
                minutes
            )
        case .stepUp:
            return String(
                format: String(localized: "Twice in a row you didn't relax in time. Back to %@ min?"),
                minutes
            )
        }
    }
}

#Preview {
    BreathingBeforeView(
        viewModel: BreathingFlowViewModel(),
        onClose: {},
        onStart: {}
    )
}
