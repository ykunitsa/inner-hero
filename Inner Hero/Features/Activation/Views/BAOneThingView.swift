import SwiftUI

/// "Одно дело" (spec §6): one card, one commitment.
///
/// The rule this screen exists to enforce is negative — the activity list is
/// **never** shown here in full. Picking from fifteen options is precisely the
/// operation a person with no energy cannot perform, so the shelf was already
/// chosen by the previous screen and the card was drawn at random from it.
///
/// The accent belongs to "I'll go" alone. The activity card carries its weight
/// through size, not colour: two accented things would make the screen ask twice
/// what it is asking once.
struct BAOneThingView: View {
    @Bindable var viewModel: BAFlowViewModel
    let onShuffle: () -> Void
    let onApplySuggestion: () -> Void
    let onCommit: () -> Void
    let onOpenStore: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: Spacing.md) {
            Spacer(minLength: Spacing.sm)

            if let candidate = viewModel.candidate {
                activityCard(candidate)
                shuffleButton
            } else {
                emptyBasket
            }

            if let suggestion = viewModel.suggestion {
                BASuggestionLine(suggestion: suggestion, onApply: onApplySuggestion)
            }

            Spacer(minLength: Spacing.sm)

            if viewModel.hasCandidate {
                forecastSection
            }
        }
        .padding(.horizontal, Spacing.sm)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .top) { header }
        .safeAreaInset(edge: .bottom) { actions }
        .formBackground()
        .ignoresSafeArea(.container, edges: .bottom)
        .animation(AppAnimation.standard, value: viewModel.candidate?.title)
    }

    // MARK: Header

    private var header: some View {
        ZStack {
            Text(String(localized: "Activation"))
                .appFont(.h3)
                .foregroundStyle(TextColors.primary)
                .lineLimit(1)
                .padding(.horizontal, TouchTarget.minimum + Spacing.xs)
            HStack {
                CircleButton(systemImage: "chevron.left", background: AppColors.cardBackground) {
                    viewModel.returnToEnergy()
                }
                .accessibilityLabel(String(localized: "Back"))
                Spacer()
                CircleButton(systemImage: "xmark", background: AppColors.cardBackground) {
                    onDismiss()
                }
                .accessibilityLabel(String(localized: "Close"))
            }
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.top, Spacing.sm)
        .padding(.bottom, Spacing.xs)
        .pinnedHeaderBackground()
    }

    // MARK: Card

    private func activityCard(_ activity: BAActivity) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text(activity.title)
                .appFont(.h2)
                .foregroundStyle(TextColors.primary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(viewModel.basket.title)
                .appFont(.small)
                .foregroundStyle(TextColors.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(cornerRadius: CornerRadius.lg, padding: Spacing.md)
        .accessibilityElement(children: .combine)
    }

    /// Hidden rather than disabled when there is nothing to shuffle to: a greyed
    /// control invites a tap and then refuses it.
    @ViewBuilder
    private var shuffleButton: some View {
        if viewModel.canShuffle {
            Button(action: onShuffle) {
                HStack(spacing: Spacing.xxxs) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .appFont(.bodyMedium)
                        .accessibilityHidden(true)
                    Text(String(localized: "Something else"))
                        .appFont(.body)
                }
                .foregroundStyle(TextColors.secondary)
                .frame(minHeight: TouchTarget.minimum)
            }
            .buttonStyle(.plain)
        }
    }

    /// Not a dead end: the basket can only be empty because the store was
    /// emptied, and the way out is the store.
    private var emptyBasket: some View {
        VStack(spacing: Spacing.xs) {
            Text(String(localized: "Nothing in this basket yet."))
                .appFont(.body)
                .foregroundStyle(TextColors.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Button(action: onOpenStore) {
                Text(String(localized: "Open activities"))
                    .appFont(.body)
                    .foregroundStyle(AppColors.accent)
                    .frame(minHeight: TouchTarget.minimum)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Forecast

    /// Captured **before**, one tap, and genuinely optional (principle 1.6).
    /// Chips rather than a scale: a slider is always parked on some value, so a
    /// skipped question would still record an answer.
    private var forecastSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            SectionLabel(text: String(localized: "How do you think it will go?"))
            ChipFlowLayout {
                ForEach(BAForecast.allCases, id: \.self) { option in
                    SelectableChip(
                        text: option.title,
                        isSelected: Binding(
                            get: { viewModel.forecast == option },
                            set: { isOn in viewModel.forecast = isOn ? option : nil }
                        )
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Actions

    private var actions: some View {
        VStack(spacing: Spacing.xxs) {
            PrimaryButton(
                title: String(localized: "I'll go"),
                color: AppColors.black,
                titleColor: TextColors.onBlack
            ) {
                onCommit()
            }
            .disabled(!viewModel.hasCandidate)

            // Names the fact, not a cancel. Nothing has been written yet, so this
            // genuinely leaves no trace (spec §6) — which is why it is not called
            // "Cancel" either.
            Button(action: onDismiss) {
                Text(String(localized: "Not now"))
                    .appFont(.body)
                    .foregroundStyle(TextColors.secondary)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: TouchTarget.minimum)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.xs)
        .padding(.bottom, Spacing.lg)
        .pinnedFooterBackground()
    }
}
