import SwiftUI
import SwiftData

/// Planned exposure (spec §3, §11.2): before → during → after, presented as
/// a full-screen cover — a swipe-dismiss mid-session would be an exit that
/// loses data. One view model carries the single entry through all stages.
struct PlannedExposureFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(NotificationManager.self) private var notificationManager
    @Query(sort: \ExposureLogEntry.createdAt, order: .reverse)
    private var entries: [ExposureLogEntry]

    @State private var viewModel = PlannedExposureFlowViewModel()
    /// Whether the background end-signal notification can arrive; drives the
    /// hint line wording on the session screen.
    @State private var notificationsAuthorized = true

    private static let endSignalNotificationID = "plannedExposureEndSignal"

    var body: some View {
        Group {
            switch viewModel.stage {
            case .before:
                PlannedExposureBeforeView(
                    viewModel: viewModel,
                    onStart: start,
                    onClose: { dismiss() }
                )
            case .during:
                PlannedExposureSessionView(
                    viewModel: viewModel,
                    notificationsAuthorized: notificationsAuthorized,
                    onComplete: completeSession,
                    onFinishEarly: finishEarly
                )
            case .after:
                PlannedExposureAfterView(
                    viewModel: viewModel,
                    onClose: { dismiss() }
                )
            }
        }
        .animation(AppAnimation.standard, value: stageKey)
        .onAppear { viewModel.configure(history: entries) }
    }

    /// Stage as an Equatable key for the transition animation.
    private var stageKey: Int {
        switch viewModel.stage {
        case .before: 0
        case .during: 1
        case .after: 2
        }
    }

    // MARK: Session lifecycle

    private func start() -> Bool {
        do {
            try viewModel.startSession(in: modelContext)
        } catch {
            return false
        }
        guard viewModel.stage == .during else { return false }
        Task {
            notificationsAuthorized = await notificationManager.requestAuthorization()
            guard notificationsAuthorized else { return }
            // Scheduled from the remaining time so the permission dialog
            // doesn't shift the hidden end moment.
            let remaining = viewModel.targetDuration - viewModel.elapsed(now: Date())
            guard remaining > 0 else { return }
            await notificationManager.scheduleOneTimeSignal(
                id: Self.endSignalNotificationID,
                title: String(localized: "Time"),
                body: String(localized: "The exposure is done"),
                after: remaining
            )
        }
        return true
    }

    private func completeSession() {
        viewModel.completeSession(in: modelContext)
        cancelEndSignal()
    }

    private func finishEarly() {
        viewModel.finishEarly(in: modelContext)
        HapticFeedback.light()
        cancelEndSignal()
    }

    private func cancelEndSignal() {
        Task { await notificationManager.removeReminder(id: Self.endSignalNotificationID) }
    }
}

#Preview {
    PlannedExposureFlowView()
        .modelContainer(for: ExposureLogEntry.self, inMemory: true)
        .environment(NotificationManager())
}
