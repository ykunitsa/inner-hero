import SwiftUI

/// After "Did it" (spec §6): two ratings, and the forecast next to what actually
/// happened.
///
/// The outcome was already written on the previous screen, so nothing here is
/// load-bearing — "Done" adds detail, it does not commit anything. That is why
/// the sliders are optional and why closing with the cross is not a loss.
///
/// Two sliders on one screen is a knowing stretch of "one screen, one job"
/// (codex §1): pleasure and mastery are different axes and the spec asks for
/// both, and splitting them across two screens would buy tidiness with an extra
/// tap.
struct BAAfterView: View {
    @Bindable var viewModel: BAFlowViewModel
    let onOpenStore: () -> Void
    let onClose: () -> Void
    let onDone: () -> Void

    @State private var isNoteExpanded = false

    @ScaledMetric(relativeTo: .body) private var noteHeight: CGFloat =
        FieldSize.editorMinHeight + Spacing.xs * 2

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                ratingSection(
                    label: String(localized: "Was it pleasant?"),
                    accessibilityLabel: String(localized: "Pleasantness"),
                    value: viewModel.pleasure,
                    onChange: viewModel.setPleasure
                )
                ratingSection(
                    label: String(localized: "Did you handle it?"),
                    accessibilityLabel: String(localized: "Mastery"),
                    value: viewModel.mastery,
                    onChange: viewModel.setMastery
                )
                forecastComparison
                noteSection
                refillLine
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.top, Spacing.sm)
            .padding(.bottom, Spacing.xl)
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .top) { header }
        .safeAreaInset(edge: .bottom) { doneButton }
        .formBackground()
        .ignoresSafeArea(.container, edges: .bottom)
        .animation(AppAnimation.standard, value: isNoteExpanded)
    }

    private var header: some View {
        ZStack {
            Text(viewModel.entry?.activityTitle ?? "")
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

    /// The slider is fed through a closure rather than a plain binding so the
    /// view model can tell "dragged to 5" from "never touched" — an untouched
    /// slider must save nothing at all.
    private func ratingSection(
        label: String,
        accessibilityLabel: String,
        value: Int,
        onChange: @escaping (Int) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            SectionLabel(text: label)
            IntensitySlider(
                value: Binding(get: { value }, set: onChange)
            )
            .accessibilityLabel(accessibilityLabel)
        }
    }

    /// Both facts side by side, with no verdict attached. Not "better than you
    /// thought!" — the user can see which number is bigger, and the app noticing
    /// it out loud would be interpretation (principle 1.1).
    @ViewBuilder
    private var forecastComparison: some View {
        if let comparison = viewModel.forecastComparison {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                SectionLabel(
                    text: String(
                        format: String(localized: "Your forecast · %@"),
                        comparison.forecast.title
                    )
                )
                QuoteCard(
                    text: String(
                        format: String(localized: "It went %lld."),
                        comparison.rating
                    )
                )
            }
        }
    }

    /// A line, not an open field: the note is available, not asked for.
    private var noteSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            if isNoteExpanded {
                SectionLabel(text: String(localized: "Note"))
                AppTextEditor(
                    text: $viewModel.note,
                    placeholder: String(localized: "Note…")
                )
                .frame(height: noteHeight)
                .transition(.opacity)
            } else {
                Button {
                    isNoteExpanded = true
                } label: {
                    HStack(spacing: Spacing.xxxs) {
                        Image(systemName: "plus")
                            .appFont(.bodyMedium)
                            .accessibilityHidden(true)
                        Text(String(localized: "Add a note"))
                            .appFont(.body)
                    }
                    .foregroundStyle(TextColors.secondary)
                    .touchTarget(width: 0)
                }
                .buttonStyle(.plain)
            }
        }
    }

    /// Spec §6: the only place in the app that suggests anything, and it appears
    /// at 6+ only. Phrased about the shelf rather than about the person — "keep
    /// this on the list", never "you should do more of this".
    @ViewBuilder
    private var refillLine: some View {
        if viewModel.shouldSuggestRefill {
            Button(action: onOpenStore) {
                Text(String(localized: "Worth keeping something like this on the list."))
                    .appFont(.small)
                    .foregroundStyle(AppColors.accent)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(minHeight: TouchTarget.minimum)
            }
            .buttonStyle(.plain)
            .transition(.opacity)
        }
    }

    private var doneButton: some View {
        PrimaryButton(
            title: String(localized: "Done"),
            color: AppColors.black,
            titleColor: TextColors.onBlack
        ) {
            onDone()
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.xs)
        .padding(.bottom, Spacing.lg)
        .pinnedFooterBackground()
    }
}
