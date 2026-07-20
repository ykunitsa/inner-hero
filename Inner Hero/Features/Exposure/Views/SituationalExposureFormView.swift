import SwiftUI
import SwiftData

/// Situational exposure entry (spec §3, spec §11.1) — one screen, filled in
/// right after an exposure already happened. Presented as a full-height sheet
/// from Today. No prediction fields here, ever (principle 1.6).
struct SituationalExposureFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ExposureLogEntry.createdAt, order: .reverse)
    private var entries: [ExposureLogEntry]

    @State private var viewModel = SituationalExposureFormViewModel()
    @State private var showDiscardConfirmation = false
    @State private var showSaveError = false
    @State private var isNoteExpanded = false

    @State private var scrollPosition = ScrollPosition()

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                // Single explicit stack: loose ScrollView children overlap
                // instead of stacking.
                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        situationSection
                        anxietySection
                        behaviorSection
                        safetySection
                        noteSection
                    }
                    .padding(.horizontal, Spacing.sm)

                    // Room for the pinned Save block so the last field can
                    // scroll fully above it.
                    Color.clear
                        .frame(height: Spacing.xxxl * 2)
                }
            }
            .scrollPosition($scrollPosition)
            saveButton
        }
        .scrollDismissesKeyboard(.interactively)
        .background(AppColors.cardBackground.ignoresSafeArea())
        // The save pill nests into the sheet's bottom rounding (tab-bar
        // height); the keyboard still pushes it up when open.
        .ignoresSafeArea(.container, edges: .bottom)
        .safeAreaInset(edge: .top) { header }
        .interactiveDismissDisabled(viewModel.hasDraft)
        .onAppear { viewModel.configure(history: entries) }
        .confirmationDialog(
            String(localized: "Discard this entry?"),
            isPresented: $showDiscardConfirmation,
            titleVisibility: .visible
        ) {
            Button(String(localized: "Discard"), role: .destructive) { dismiss() }
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
        // System-sheet header: quiet centered title, close circle in the corner.
        ZStack {
            Text(String(localized: "Log an exposure"))
                .appFont(.h3)
                .foregroundStyle(TextColors.primary)
                .lineLimit(1)
                .padding(.horizontal, TouchTarget.minimum + Spacing.xs)
            HStack {
                Spacer()
                CircleButton(systemImage: "xmark", background: AppColors.gray100) {
                    attemptClose()
                }
                .accessibilityLabel(String(localized: "Close"))
            }
        }
        .padding(.horizontal, Spacing.sm)
        // Top inset matches the side insets so the header sits evenly
        // inside the sheet's corner radius.
        .padding(.top, Spacing.sm)
        .padding(.bottom, Spacing.xs)
        .background(
            // Mirror of the Save scrim: content fades out under the header
            // instead of hitting a hard edge.
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

    private var situationSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            SectionLabel(text: String(localized: "What happened"))
            AppTextEditor(
                text: $viewModel.situation,
                placeholder: String(localized: "Describe the situation…"),
                minHeight: 80
            )
            if !viewModel.situationSuggestions.isEmpty {
                SuggestionChipsRow(suggestions: viewModel.situationSuggestions) {
                    viewModel.applySuggestion($0)
                }
            }
        }
    }

    private var anxietySection: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            SectionLabel(text: String(localized: "Anxiety level"))
            IntensitySlider(value: $viewModel.anxiety)
                .accessibilityLabel(String(localized: "Anxiety level"))
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

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            if isNoteExpanded {
                SectionLabel(text: String(localized: "Note"))
                AppTextEditor(
                    text: $viewModel.note,
                    placeholder: String(localized: "Note…"),
                    minHeight: 80
                )
                // Scroll AFTER the editor is inserted and laid out — doing it
                // in the button action measures the pre-expansion height and
                // lands short.
                .onAppear {
                    DispatchQueue.main.async {
                        withAnimation(AppAnimation.standard) {
                            scrollPosition.scrollTo(edge: .bottom)
                        }
                    }
                }
            } else {
                Button {
                    // Deliberately not animated: an animated height change keeps
                    // the content too short at scroll time and the scroll-to-
                    // bottom call clamps to zero. The scroll itself provides
                    // the motion.
                    isNoteExpanded = true
                } label: {
                    HStack(spacing: Spacing.xxxs) {
                        Image(systemName: "plus")
                            .font(.system(size: IconSize.fieldGlyph, weight: .semibold))
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

    // MARK: Save

    private var saveButton: some View {
        PrimaryButton(title: String(localized: "Save")) { save() }
            .disabled(!viewModel.canSave)
            // Narrower than the fields, and the gap to the physical bottom
            // edge equals the side gaps — the pill nests into the rounding.
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

    private func save() {
        do {
            try viewModel.save(in: modelContext)
            HapticFeedback.success()
            dismiss()
        } catch {
            HapticFeedback.error()
            showSaveError = true
        }
    }

    private func attemptClose() {
        if viewModel.hasDraft {
            showDiscardConfirmation = true
        } else {
            dismiss()
        }
    }

}

#Preview {
    SituationalExposureFormView()
        .modelContainer(for: ExposureLogEntry.self, inMemory: true)
}
