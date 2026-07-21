import SwiftUI

/// The "after" screen of the breathing flow (spec §4): one question, one tap.
///
/// Stays on the dark session surface rather than snapping back to the form's
/// light gray — a flash of light-gray right after the practice lands in a fully
/// dilated pupil. The return to light happens when the flow closes, on a
/// natural boundary.
///
/// What is deliberately absent: praise for finishing, any session summary, and
/// the ladder line. Catching the end of a streak here would turn a calm exit
/// into a nudge.
struct BreathingAfterView: View {
    @Bindable var viewModel: BreathingFlowViewModel
    let onClose: () -> Void
    let onDone: () -> Void

    @State private var isNoteExpanded = false

    /// The editor's own minimum plus its padding — about three lines.
    @ScaledMetric(relativeTo: .body) private var noteHeight: CGFloat =
        FieldSize.editorMinHeight + Spacing.xs * 2

    private var yesNoOptions: [ChoiceOption<Bool>] {
        [
            ChoiceOption(value: true, title: String(localized: "Yes"), systemImage: "checkmark"),
            ChoiceOption(value: false, title: String(localized: "No"), systemImage: "xmark"),
        ]
    }

    var body: some View {
        VStack(spacing: Spacing.md) {
            Spacer(minLength: Spacing.sm)

            // The single question, centred on both axes — this screen asks one
            // thing and the layout should say so before the text does.
            Text(String(localized: "Did you manage to relax?"))
                .appFont(.h1)
                .foregroundStyle(TextColors.primary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, Spacing.sm)

            Spacer(minLength: Spacing.sm)

            // Answer and note sit low, within thumb reach of "Done".
            SegmentedChoice(
                options: yesNoOptions,
                selection: $viewModel.didRelax,
                style: .segments,
                // Tinted, not solid: "Done" is the loud green on this screen.
                accentColor: AppColors.positive.opacity(Opacity.emphasizedBorder)
            )
            noteSection
        }
        .padding(.horizontal, Spacing.sm)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .top) { header }
        .safeAreaInset(edge: .bottom) { doneButton }
        .background(AppColors.sessionSurface.ignoresSafeArea())
        .environment(\.colorScheme, .dark)
        .ignoresSafeArea(.container, edges: .bottom)
        // Expanding the note lifts the answer above it, rather than the block
        // appearing out of nowhere under a static layout.
        .animation(AppAnimation.standard, value: isNoteExpanded)
    }

    /// Same title treatment as the session screen: what was just done, quietly,
    /// at the top.
    private var header: some View {
        ZStack {
            Text(metaText)
                .appFont(.small)
                .foregroundStyle(TextColors.secondary)
                .lineLimit(1)
                .padding(.horizontal, TouchTarget.minimum + Spacing.xs)
            HStack {
                Spacer()
                // Leaving without answering keeps everything already recorded —
                // data, not a cancel (principle 1.5).
                CircleButton(systemImage: "xmark", background: AppColors.cardBackground) {
                    onClose()
                }
                .accessibilityLabel(String(localized: "Close"))
            }
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.top, Spacing.sm)
    }

    /// States the fact without calling it a failure: "4 of 10 min", never
    /// "interrupted".
    private var metaText: String {
        let pattern = viewModel.pattern.title
        let planned = BreathingLadder.minutesLabel(seconds: viewModel.plannedDuration)
        guard viewModel.didFinishEarly else {
            return String(format: String(localized: "%1$@ · %2$@ min"), pattern, planned)
        }
        // Rounded up: half a minute of breathing is not "0 min".
        let actual = BreathingLadder.minutesLabel(
            seconds: max(viewModel.actualDuration, 30)
        )
        return String(
            format: String(localized: "%1$@ · %2$@ of %3$@ min"),
            pattern, actual, planned
        )
    }

    /// A line, not an open field (spec §4): the note is available, not asked
    /// for.
    private var noteSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            if isNoteExpanded {
                SectionLabel(text: String(localized: "Note"))
                AppTextEditor(
                    text: $viewModel.note,
                    placeholder: String(localized: "Note…")
                )
                // An explicit height, not the editor's own floor: this screen
                // has no ScrollView, so a growable field simply absorbs every
                // spare point and the note swallows the whole screen.
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

    /// Green, not the inverted white the dark `colorScheme` would give it: a
    /// white slab is the loudest thing that can be put on this surface, and it
    /// arrives right after the practice. Green also ties the button to the
    /// circle the user was just watching.
    ///
    /// The selected Yes/No segment stays a *tinted* green rather than a solid
    /// one, so the screen keeps a single loud accent.
    private var doneButton: some View {
        PrimaryButton(
            title: String(localized: "Done"),
            color: AppColors.positive,
            titleColor: TextColors.onColor
        ) {
            onDone()
        }
        .disabled(!viewModel.canSaveAfter)
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.lg)
    }
}

#Preview {
    BreathingAfterView(
        viewModel: BreathingFlowViewModel(),
        onClose: {},
        onDone: {}
    )
}
