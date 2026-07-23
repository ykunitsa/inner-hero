import SwiftData
import SwiftUI

/// The "before" block of a planned exposure (spec §3): the prediction is
/// captured here, before the session — never after (principle 1.6). The
/// single primary action is "Start".
struct PlannedExposureBeforeView: View {
    @Bindable var viewModel: PlannedExposureFlowViewModel
    /// Returns false when persisting the entry failed. Async because the
    /// notification permission is settled here, before the clock starts.
    let onStart: () async -> Bool
    let onClose: () -> Void

    @Environment(ArticlesStore.self) private var articles
    /// Both exposure forms count towards the `sessions == 0` rule: §3 keeps
    /// situational and planned entries in one table because they are one
    /// exercise, so the article leaves the door after either kind.
    @Query private var entries: [ExposureLogEntry]

    @State private var showDiscardConfirmation = false
    @State private var showSaveError = false
    @State private var isStarting = false
    @State private var showArticle = false

    private var article: Article? {
        articles.allArticles.first { $0.id == ExerciseArticle.exposure }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                articleDoor
                activitySection
                fearSection
                confidenceSection
                expectedAnxietySection
                rangeSection
            }
            .padding(.horizontal, Spacing.sm)
        }
        // An inset, not a ZStack overlay: the button has to shorten the
        // scrollable area, not float over it. Overlaid, it silently swallowed
        // the last line of the form whenever the content was barely taller
        // than the screen.
        .safeAreaInset(edge: .bottom) { startButton }
        .scrollDismissesKeyboard(.interactively)
        .formBackground()
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
        .articleDoorSheet(article, isPresented: $showArticle)
    }

    // MARK: Header

    /// Spec §8: the article stands at the door only before the first session.
    /// Unlike the pinned flows, this screen scrolls, so the card sits at the top
    /// of the form — above the first field, still below nothing.
    @ViewBuilder
    private var articleDoor: some View {
        if entries.isEmpty, let article {
            ArticleDoorRow(title: article.title, readTime: article.readTime) {
                showArticle = true
            }
        }
    }

    private var header: some View {
        // "Planned", not just "Exposure": the Exercises tile leads only here,
        // while the situational form (spec §3's primary mode) is launched from
        // Today. The title is what tells the user which of the two they landed
        // in, immediately and at no cost to the tile.
        ExerciseDoorHeader(
            title: String(localized: "Planned exposure"),
            infoLabel: article?.title,
            onInfo: article == nil ? nil : { showArticle = true },
            onClose: {
                if viewModel.hasBeforeDraft {
                    showDiscardConfirmation = true
                } else {
                    onClose()
                }
            }
        )
    }

    // MARK: Sections

    private var activitySection: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            SectionLabel(text: String(localized: "What will you do"))
            AppTextEditor(
                text: $viewModel.activity,
                placeholder: String(localized: "Describe the activity…")
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
                placeholder: String(localized: "It will overwhelm me and I'll leave in a couple of minutes…")
            )
        }
    }

    private var confidenceSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            SectionLabel(text: String(localized: "How sure are you"))
            // A gradient, not a set of facts — so a scale, not cards. As four
            // stacked cards this one question ate ~200pt, half the screen
            // above the fold, for an answer that is one tap either way.
            ScaleChoice(
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
            guard !isStarting else { return }
            isStarting = true
            Task {
                let started = await onStart()
                isStarting = false
                if !started {
                    HapticFeedback.error()
                    showSaveError = true
                }
            }
        }
        .disabled(!viewModel.canStart || isStarting)
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.md)
        .padding(.bottom, Spacing.lg)
        .pinnedFooterBackground()
    }
}

#Preview {
    PlannedExposureBeforeView(
        viewModel: PlannedExposureFlowViewModel(),
        onStart: { true },
        onClose: {}
    )
    .environment(ArticlesStore())
    .modelContainer(for: ExposureLogEntry.self, inMemory: true)
}
