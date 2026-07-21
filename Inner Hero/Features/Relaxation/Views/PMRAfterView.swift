import SwiftUI

/// The "after" screen of the PMR flow (spec §5): one question, one tap.
///
/// Deliberately the same screen as breathing's. Two exercises asking the same
/// question in two different layouts would be noise dressed up as variety.
///
/// Stays on the dark session surface rather than snapping back to the form's
/// light gray — a flash of light-gray right after the practice lands in a fully
/// dilated pupil. The return to light happens when the flow closes.
///
/// What is deliberately absent: praise for finishing, a session summary, the
/// ladder line, and **the medal**. A step earned here is recorded, and its home
/// is a line in History (spec §5) — a congratulation modal at the end of a
/// relaxation exercise is exactly what the interface codex §8 rules out.
struct PMRAfterView: View {
    @Bindable var viewModel: PMRFlowViewModel
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
        .animation(AppAnimation.standard, value: isNoteExpanded)
    }

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

    /// States the fact without calling it a failure: "6 of 10 min", never
    /// "interrupted".
    private var metaText: String {
        let step = viewModel.step.title
        let planned = PMRLadder.minutesLabel(duration: TimeInterval(viewModel.plannedDuration))
        guard viewModel.didFinishEarly else {
            return String(format: String(localized: "%1$@ · %2$@ min"), step, planned)
        }
        // Rounded up: half a minute of practice is not "0 min".
        let actual = PMRLadder.minutesLabel(
            duration: TimeInterval(max(viewModel.actualDuration, 30))
        )
        return String(
            format: String(localized: "%1$@ · %2$@ of %3$@ min"),
            step, actual, planned
        )
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
                // An explicit height: this screen has no ScrollView, so a
                // growable field would absorb every spare point.
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
    PMRAfterView(
        viewModel: PMRFlowViewModel(),
        onClose: {},
        onDone: {}
    )
}
