import SwiftUI

/// The "before" block of a planned exposure (spec §3): the prediction is
/// captured here, before the session — never after (principle 1.6). The
/// single primary action is "Start".
struct PlannedExposureBeforeView: View {
    @Bindable var viewModel: PlannedExposureFlowViewModel
    /// Returns false when persisting the entry failed.
    let onStart: () -> Bool
    let onClose: () -> Void

    @State private var showDiscardConfirmation = false
    @State private var showSaveError = false

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        activitySection
                        fearSection
                        confidenceSection
                        expectedAnxietySection
                        rangeSection
                    }
                    .padding(.horizontal, Spacing.sm)

                    // Room for the pinned Start block so the last field can
                    // scroll fully above it.
                    Color.clear
                        .frame(height: Spacing.xxxl * 2)
                }
            }
            startButton
        }
        .scrollDismissesKeyboard(.interactively)
        .background(AppColors.cardBackground.ignoresSafeArea())
        // The pinned pill sits low, near the physical bottom edge — same
        // placement as the situational sheet; the keyboard still pushes it up.
        .ignoresSafeArea(.container, edges: .bottom)
        .safeAreaInset(edge: .top) { header }
        .confirmationDialog(
            String(localized: "Discard this entry?"),
            isPresented: $showDiscardConfirmation,
            titleVisibility: .visible
        ) {
            Button(String(localized: "Discard"), role: .destructive) { onClose() }
            Button(String(localized: "Keep editing"), role: .cancel) {}
        }
        .alert(
            String(localized: "Couldn't save. Try again."),
            isPresented: $showSaveError
        ) {
            Button(String(localized: "OK"), role: .cancel) {}
        }
    }

    // MARK: Header

    private var header: some View {
        ZStack {
            Text(String(localized: "Exposure"))
                .appFont(.h3)
                .foregroundStyle(TextColors.primary)
                .lineLimit(1)
                .padding(.horizontal, TouchTarget.minimum + Spacing.xs)
            HStack {
                Spacer()
                CircleButton(systemImage: "xmark", background: AppColors.gray100) {
                    if viewModel.hasBeforeDraft {
                        showDiscardConfirmation = true
                    } else {
                        onClose()
                    }
                }
                .accessibilityLabel(String(localized: "Close"))
            }
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.top, Spacing.sm)
        .padding(.bottom, Spacing.xs)
        .background(
            // Content fades out under the header instead of hitting a hard edge.
            LinearGradient(
                stops: [
                    .init(color: AppColors.cardBackground, location: 0.65),
                    .init(color: AppColors.cardBackground.opacity(0), location: 1),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    // MARK: Sections

    private var activitySection: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            SectionLabel(text: String(localized: "What will you do"))
            AppTextEditor(
                text: $viewModel.activity,
                placeholder: String(localized: "Describe the activity…"),
                minHeight: 80
            )
            if !viewModel.activitySuggestions.isEmpty {
                SuggestionChipsRow(suggestions: viewModel.activitySuggestions) {
                    viewModel.applySuggestion($0)
                }
            }
        }
    }

    private var fearSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            SectionLabel(text: String(localized: "What do you fear anxiety will do"))
            AppTextEditor(
                text: $viewModel.fearedOutcome,
                placeholder: String(localized: "It will overwhelm me and I'll leave in a couple of minutes…"),
                minHeight: 80
            )
        }
    }

    private var confidenceSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            SectionLabel(text: String(localized: "How sure are you"))
            SegmentedChoice(
                options: PredictionConfidence.allCases.map {
                    ChoiceOption(value: $0, title: $0.title)
                },
                selection: $viewModel.confidence
            )
        }
    }

    private var expectedAnxietySection: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            SectionLabel(text: String(localized: "Expected anxiety"))
            IntensitySlider(value: $viewModel.expectedAnxiety)
                .accessibilityLabel(String(localized: "Expected anxiety"))
        }
    }

    private var rangeSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            SectionLabel(text: String(localized: "Time range"))
            DurationRangeSlider(
                minMinutes: $viewModel.rangeMinMinutes,
                maxMinutes: $viewModel.rangeMaxMinutes,
                bounds: PlannedExposureFlowViewModel.rangeBounds
            )
            Text(String(localized: "The exposure ends at a random moment inside the range"))
                .appFont(.small)
                .foregroundStyle(TextColors.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: Start

    private var startButton: some View {
        PrimaryButton(title: String(localized: "Start")) {
            if !onStart() {
                HapticFeedback.error()
                showSaveError = true
            }
        }
        .disabled(!viewModel.canStart)
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.md)
        .padding(.bottom, Spacing.lg)
        .background(
            // Fade instead of a hard edge: content visibly continues under
            // the button, signalling the form scrolls.
            LinearGradient(
                stops: [
                    .init(color: AppColors.cardBackground.opacity(0), location: 0),
                    .init(color: AppColors.cardBackground, location: 0.35),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

#Preview {
    PlannedExposureBeforeView(
        viewModel: PlannedExposureFlowViewModel(),
        onStart: { true },
        onClose: {}
    )
}
