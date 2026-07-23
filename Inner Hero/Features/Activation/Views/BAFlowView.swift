import SwiftData
import SwiftUI

/// Container for the BA flow (spec §6). Owns the model context, the two queries,
/// the reminder and the dismiss; the stage views stay pure presentation over the
/// view model, as in breathing and PMR.
///
/// There is no "entry mode" parameter, and that is deliberate: an open activity
/// always wins, so opening BA from the launcher and opening it from the row on
/// Today converge on the same screen without the caller having to know.
struct BAFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(NotificationManager.self) private var notificationManager

    @Query(sort: \BAActivity.createdAt) private var activities: [BAActivity]
    @Query(sort: \BALogEntry.createdAt, order: .reverse) private var entries: [BALogEntry]

    @State private var viewModel = BAFlowViewModel()
    @State private var showStore = false
    @State private var showSaveError = false

    private var openEntry: BALogEntry? {
        entries.first { $0.isOpen }
    }

    var body: some View {
        Group {
            switch viewModel.stage {
            case .energy:
                BAEnergyView(
                    activityCount: activities.count,
                    hasSessions: !entries.isEmpty,
                    onAnswer: { energy in
                        viewModel.answerEnergy(energy, activities: activities)
                    },
                    onOpenStore: { showStore = true },
                    onClose: { dismiss() }
                )
            case .oneThing:
                BAOneThingView(
                    viewModel: viewModel,
                    onShuffle: { viewModel.shuffleCandidate(from: activities) },
                    onApplySuggestion: { viewModel.applySuggestion(activities: activities) },
                    onCommit: commit,
                    onOpenStore: { showStore = true },
                    // "Not now" closes without a trace (spec §6) — nothing was
                    // written, so there is nothing to save.
                    onDismiss: { dismiss() }
                )
            case .tail:
                BATailView(
                    entry: viewModel.entry,
                    onAnswer: answer,
                    onClose: { dismiss() }
                )
            case .after:
                BAAfterView(
                    viewModel: viewModel,
                    onOpenStore: { showStore = true },
                    onClose: closePartial,
                    onDone: done
                )
            }
        }
        .animation(AppAnimation.slow, value: stageKey)
        .onAppear { viewModel.configure(openEntry: openEntry, history: entries) }
        .sheet(isPresented: $showStore) {
            BAActivitiesView()
        }
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
        case .energy: 0
        case .oneThing: 1
        case .tail: 2
        case .after: 3
        }
    }

    // MARK: Actions

    private func commit() {
        do {
            guard let entry = try viewModel.commit(in: modelContext) else { return }
            HapticFeedback.success()
            scheduleReminder(for: entry)
            // Spec §6: "приложение закрывается". The phone has done its part —
            // anything else on screen now competes with actually going.
            dismiss()
        } catch {
            HapticFeedback.error()
            showSaveError = true
        }
    }

    private func answer(_ outcome: BAOutcome) {
        guard let entry = viewModel.entry else { return }
        let reminderID = entry.reminderID
        do {
            try viewModel.answer(outcome, in: modelContext)
            HapticFeedback.light()
            Task { await notificationManager.removeReminder(id: reminderID) }
            // "Couldn't" is recorded and done. No sliders, no follow-up question.
            if outcome == .couldNot { dismiss() }
        } catch {
            HapticFeedback.error()
            showSaveError = true
        }
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

    /// Closing "after" without touching the sliders keeps the outcome already
    /// recorded (principle 1.5).
    private func closePartial() {
        try? viewModel.saveAfter(in: modelContext)
        dismiss()
    }

    /// The single quiet reminder (spec §6). Silent on purpose, and scheduled only
    /// if notifications are already authorised — asking for permission at the
    /// moment someone has just committed to going outside is a prompt at the
    /// worst possible time.
    private func scheduleReminder(for entry: BALogEntry) {
        let delay = entry.effort?.reminderDelay ?? BAEffort.easy.reminderDelay
        let id = entry.reminderID
        let title = entry.activityTitle
        Task {
            guard await notificationManager.checkAuthorizationStatus() == .authorized else { return }
            await notificationManager.scheduleOneTimeSignal(
                id: id,
                title: title,
                body: String(localized: "Did it happen?"),
                after: delay,
                sound: nil,
                // Opens BA, which puts the tail first — the same door the row on
                // Today and the "Сегодня" widget use.
                deepLink: .exercise(.activation)
            )
        }
    }
}

#Preview {
    BAFlowView()
        .modelContainer(for: [BAActivity.self, BALogEntry.self], inMemory: true)
        .environment(NotificationManager())
}
