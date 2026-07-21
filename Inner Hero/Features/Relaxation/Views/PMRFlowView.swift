import SwiftData
import SwiftUI

/// Container for the PMR flow (spec §5). Owns the model context, the history
/// query, the audio session and the dismiss — the three stage views stay pure
/// presentation over the view model, exactly as in breathing.
struct PMRFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PMRSessionEntry.createdAt, order: .reverse) private var entries: [PMRSessionEntry]

    @State private var viewModel = PMRFlowViewModel()
    @State private var audio = AudioSessionController()
    @State private var showSaveError = false

    var body: some View {
        Group {
            switch viewModel.stage {
            case .before:
                PMRBeforeView(
                    viewModel: viewModel,
                    hasSessions: !entries.isEmpty,
                    onClose: { dismiss() },
                    onStart: start
                )
            case .session:
                PMRSessionView(
                    viewModel: viewModel,
                    onComplete: complete,
                    onEndEarly: endEarly
                )
            case .after:
                PMRAfterView(
                    viewModel: viewModel,
                    onClose: closePartial,
                    onDone: done
                )
            }
        }
        .animation(AppAnimation.slow, value: stageKey)
        .onAppear { viewModel.configure(history: entries) }
        .onChange(of: viewModel.step) { _, _ in
            viewModel.refreshSuggestion(history: entries)
        }
        .onDisappear { audio.deactivate() }
        .alert(
            String(localized: "Couldn't save"),
            isPresented: $showSaveError
        ) {
            Button(String(localized: "OK"), role: .cancel) {}
        } message: {
            Text(String(localized: "Try again in a moment."))
        }
    }

    /// An Equatable projection of the stage, so the cross-fade fires on a real
    /// change and not on every view-model mutation.
    private var stageKey: Int {
        switch viewModel.stage {
        case .before: 0
        case .session: 1
        case .after: 2
        }
    }

    // MARK: Actions

    private func start() {
        do {
            // Audio first: a session that starts silently is not a session, and
            // failing here must not leave a record claiming otherwise.
            try audio.activate()
            audio.onInterruptionBegan = { viewModel.interrupt() }
            // The script does not resume itself — a voice restarting mid-word
            // while the user is still putting the phone down is worse than
            // waiting for a tap. The session screen offers "Resume".
            audio.onInterruptionEnded = nil

            try viewModel.start(in: modelContext, now: Date())
            HapticFeedback.light()
        } catch {
            audio.deactivate()
            HapticFeedback.error()
            showSaveError = true
        }
    }

    private func complete() {
        HapticFeedback.success()
        viewModel.complete(in: modelContext)
    }

    private func endEarly() {
        HapticFeedback.light()
        viewModel.finishEarly(in: modelContext)
    }

    private func done() {
        do {
            try viewModel.saveAfter(in: modelContext)
            audio.deactivate()
            HapticFeedback.success()
            dismiss()
        } catch {
            HapticFeedback.error()
            showSaveError = true
        }
    }

    /// Closing without answering keeps everything already recorded
    /// (principle 1.5).
    private func closePartial() {
        try? viewModel.savePartial(in: modelContext)
        audio.deactivate()
        dismiss()
    }
}

#Preview {
    PMRFlowView()
        .modelContainer(for: PMRSessionEntry.self, inMemory: true)
}
