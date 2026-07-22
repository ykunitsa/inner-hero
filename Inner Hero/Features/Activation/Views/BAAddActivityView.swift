import SwiftData
import SwiftUI

/// Adding a store line (spec §6): "строка + корзина, всё".
///
/// The sheet stays open after adding and keeps the basket, because filling the
/// store is a burst of several lines rather than one — reopening the sheet and
/// re-picking "easy" for each one is the repeated choice codex §2 exists to
/// remove.
struct BAAddActivityView: View {
    @Bindable var viewModel: BAActivitiesViewModel

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @FocusState private var isTitleFocused: Bool
    @State private var showSaveError = false

    private var effortOptions: [ChoiceOption<BAEffort>] {
        BAEffort.allCases.map { ChoiceOption(value: $0, title: $0.title) }
    }

    private var kindOptions: [ChoiceOption<BAKind>] {
        BAKind.allCases.map { ChoiceOption(value: $0, title: $0.title) }
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: Spacing.md) {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    SectionLabel(text: String(localized: "What will you do?"))
                    AppTextField(
                        text: $viewModel.draftTitle,
                        placeholder: String(localized: "Go for a walk…"),
                        isFocused: $isTitleFocused
                    )
                }

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    SectionLabel(text: String(localized: "Effort"))
                    // Three very short options — the canonical case for
                    // `.segments` (USAGE.MD).
                    SegmentedChoice(
                        options: effortOptions,
                        selection: Binding(
                            get: { viewModel.draftEffort },
                            set: { viewModel.draftEffort = $0 ?? viewModel.draftEffort }
                        ),
                        style: .segments
                    )
                }

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    SectionLabel(text: String(localized: "Type"))
                    // Cards, not segments: "Necessary" and "Pleasant" are twice
                    // the width of "Easy", and three of them in one row collapse
                    // at the first Dynamic Type step. No glyph here — `.cards`
                    // deliberately ignores `systemImage` so it does not compete
                    // with the radio dot; the store's glyphs carry their meaning
                    // by convention and by VoiceOver label instead.
                    SegmentedChoice(
                        options: kindOptions,
                        selection: Binding(
                            get: { viewModel.draftKind },
                            set: { viewModel.draftKind = $0 ?? viewModel.draftKind }
                        )
                    )
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.top, Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .formBackground()
            .navigationTitle(String(localized: "New activity"))
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) { addButton }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(String(localized: "Close")) { dismiss() }
                }
            }
            .onAppear { isTitleFocused = true }
            .alert(
                String(localized: "Couldn't save"),
                isPresented: $showSaveError
            ) {
                Button(String(localized: "OK"), role: .cancel) {}
            } message: {
                Text(String(localized: "Try again in a moment."))
            }
        }
    }

    private var addButton: some View {
        PrimaryButton(
            title: String(localized: "Add"),
            color: AppColors.black,
            titleColor: TextColors.onBlack
        ) {
            add()
        }
        .disabled(!viewModel.canAdd)
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.xs)
        .padding(.bottom, Spacing.md)
        .pinnedFooterBackground()
    }

    private func add() {
        do {
            try viewModel.add(in: modelContext)
            HapticFeedback.success()
            isTitleFocused = true
        } catch {
            HapticFeedback.error()
            showSaveError = true
        }
    }
}
