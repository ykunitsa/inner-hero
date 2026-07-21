import SwiftUI
import SwiftData

/// Breathing (spec §4, §11.3): before → session → after, as a full-screen
/// cover. One view model carries a single entry through all three stages.
struct BreathingFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BreathingSessionEntry.createdAt, order: .reverse)
    private var entries: [BreathingSessionEntry]

    @State private var viewModel = BreathingFlowViewModel()
    @State private var showSaveError = false

    var body: some View {
        Group {
            switch viewModel.stage {
            case .before:
                BreathingBeforeView(
                    viewModel: viewModel,
                    onClose: { dismiss() },
                    onStart: start
                )
            case .session:
                BreathingSessionView(
                    viewModel: viewModel,
                    onComplete: { viewModel.complete(in: modelContext) },
                    onFinishEarly: finishEarly
                )
            case .after:
                BreathingAfterView(
                    viewModel: viewModel,
                    onClose: closePartial,
                    onDone: done
                )
            }
        }
        // A cross-fade, not a slide: the surface goes from light to dark
        // between "before" and the session, and a push would make the change
        // land as a jolt.
        .animation(AppAnimation.slow, value: stageKey)
        .onAppear { viewModel.configure(history: entries) }
        // Both parameters feed the rule, so both invalidate it.
        .onChange(of: viewModel.pattern) { _, _ in
            viewModel.refreshSuggestion(history: entries)
        }
        .onChange(of: viewModel.plannedDuration) { _, _ in
            viewModel.refreshSuggestion(history: entries)
        }
        .alert(
            String(localized: "Couldn't save. Try again."),
            isPresented: $showSaveError
        ) {
            Button(String(localized: "OK"), role: .cancel) {}
        }
    }

    /// Stage as an Equatable key for the transition animation.
    private var stageKey: Int {
        switch viewModel.stage {
        case .before: 0
        case .session: 1
        case .after: 2
        }
    }

    // MARK: Lifecycle

    private func start() {
        do {
            try viewModel.start(in: modelContext)
        } catch {
            HapticFeedback.error()
            showSaveError = true
        }
    }

    private func finishEarly() {
        viewModel.finishEarly(in: modelContext)
        HapticFeedback.light()
    }

    private func done() {
        do {
            try viewModel.saveAfter(in: modelContext)
            HapticFeedback.success()
            dismiss()
        } catch {
            HapticFeedback.error()
            showSaveError = true
        }
    }

    /// Closing "after" without answering is still data: the session, its type
    /// and its real duration are already recorded (principle 1.5).
    private func closePartial() {
        try? viewModel.savePartial(in: modelContext)
        dismiss()
    }
}

#Preview {
    BreathingFlowView()
        .modelContainer(for: BreathingSessionEntry.self, inMemory: true)
}
