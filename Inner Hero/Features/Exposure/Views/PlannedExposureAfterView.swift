import SwiftUI
import SwiftData

/// The "after" screen of a planned exposure (spec §3): record the fact and
/// hold it against the prediction. The prediction is shown as the user's own
/// quote and is never editable here (principle 1.6). The single primary
/// action is "Save"; closing keeps what is filled — the entry is already
/// data (principle 1.5).
struct PlannedExposureAfterView: View {
    @Bindable var viewModel: PlannedExposureFlowViewModel
    let onClose: () -> Void

    @Environment(\.modelContext) private var modelContext

    @State private var showPartialSaveConfirmation = false
    @State private var showSaveError = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                predictionCard
                outcomeSection
                actualSituationSection
                behaviorSection
                safetySection
                difficultySection
            }
            .padding(.horizontal, Spacing.sm)
        }
        // An inset, not a ZStack overlay: the button has to shorten the
        // scrollable area, not float over it.
        .safeAreaInset(edge: .bottom) { saveButton }
        .scrollDismissesKeyboard(.interactively)
        .formBackground()
        // The pinned pill sits low, near the physical bottom edge — same
        // placement as the situational sheet; the keyboard still pushes it up.
        .ignoresSafeArea(.container, edges: .bottom)
        .safeAreaInset(edge: .top) { header }
        .confirmationDialog(
            String(localized: "Save without the summary?"),
            isPresented: $showPartialSaveConfirmation,
            titleVisibility: .visible
        ) {
            Button(String(localized: "Save as is")) { savePartial() }
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
            Text(String(localized: "Planned exposure"))
                .appFont(.h3)
                .foregroundStyle(TextColors.primary)
                .lineLimit(1)
                .padding(.horizontal, TouchTarget.minimum + Spacing.xs)
            HStack {
                Spacer()
                CircleButton(systemImage: "xmark", background: AppColors.cardBackground) {
                    showPartialSaveConfirmation = true
                }
                .accessibilityLabel(String(localized: "Close"))
            }
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.top, Spacing.sm)
        .padding(.bottom, Spacing.xs)
        .pinnedHeaderBackground()
    }

    // MARK: Sections

    @ViewBuilder
    private var predictionCard: some View {
        if let entry = viewModel.entry,
           let fearedOutcome = entry.fearedOutcome,
           let confidence = entry.confidence {
            // Same label-outside-the-container shape as every other block,
            // so the reminder shares the form's left edge instead of sitting
            // indented above it.
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                SectionLabel(
                    text: String(localized: "Your prediction · \(confidence.title.localizedLowercase)")
                )
                QuoteCard(text: fearedOutcome)
            }
            .accessibilityElement(children: .combine)
        }
    }

    private var outcomeSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            SectionLabel(text: String(localized: "Did it come true"))
            SegmentedChoice(
                options: PredictionOutcome.allCases.map {
                    ChoiceOption(value: $0, title: $0.title)
                },
                selection: $viewModel.predictionOutcome,
                style: .segments
            )
        }
    }

    private var actualSituationSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            SectionLabel(text: String(localized: "What actually happened"))
            AppTextEditor(
                text: $viewModel.actualSituation,
                placeholder: String(localized: "Describe the situation…")
            )
        }
    }

    private var behaviorSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            SectionLabel(text: String(localized: "What did you do"))
            SegmentedChoice(
                options: ExposureBehavior.allCases.map {
                    ChoiceOption(value: $0, title: $0.title)
                },
                selection: $viewModel.behavior
            )
        }
    }

    private var safetySection: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            SectionLabel(text: String(localized: "Did anything to feel better"))
            SafetyBehaviorPicker(
                options: viewModel.safetyBehaviorOptions,
                isNothingSelected: viewModel.isNothingSelected,
                selected: viewModel.selectedSafetyBehaviors,
                onToggleNothing: { viewModel.toggleNothing() },
                onToggle: { viewModel.toggleSafetyBehavior($0) },
                onAddCustom: { viewModel.addCustomSafetyBehavior($0) }
            )
        }
    }

    private var difficultySection: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            SectionLabel(text: String(localized: "How hard was it overall"))
            IntensitySlider(value: $viewModel.overallDifficulty)
                .accessibilityLabel(String(localized: "How hard was it overall"))
        }
    }

    // MARK: Save

    private var saveButton: some View {
        PrimaryButton(title: String(localized: "Save")) { save() }
            .disabled(!viewModel.canSaveAfter)
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.lg)
            .pinnedFooterBackground()
    }

    private func save() {
        do {
            try viewModel.saveAfter(in: modelContext)
            HapticFeedback.success()
            onClose()
        } catch {
            HapticFeedback.error()
            showSaveError = true
        }
    }

    private func savePartial() {
        do {
            try viewModel.savePartial(in: modelContext)
            onClose()
        } catch {
            HapticFeedback.error()
            showSaveError = true
        }
    }
}

#Preview {
    PlannedExposureAfterView(
        viewModel: PlannedExposureFlowViewModel(),
        onClose: {}
    )
    .modelContainer(for: ExposureLogEntry.self, inMemory: true)
}
