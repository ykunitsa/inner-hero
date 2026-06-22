import SwiftUI
import SwiftData

// MARK: - BAActiveSessionView (Step 2 of 3)
// Timer + activity info. Elapsed time is derived from session.startedAt so background
// transitions don't break the timer (Spec §8.7).

struct BAActiveSessionView: View {
    let sessionId: UUID
    var embeddedInFlow: Bool = false
    /// Wall-clock elapsed minus paused intervals; owned by `BASessionFlowView`.
    let elapsed: TimeInterval
    @Binding var requestCompleteFromPill: Bool
    let onMovedToPost: () -> Void

    @Environment(\.modelContext) private var modelContext

    @Query private var sessions: [ActivationSession]
    @Query private var tasks: [ActivationTask]

    // MARK: - Derived

    private var session: ActivationSession? { sessions.first { $0.id == sessionId } }
    private var activationTask: ActivationTask? {
        guard let s = session else { return nil }
        return tasks.first { $0.id == s.activityId }
    }

    private var suggestedSeconds: Double? {
        guard let minutes = activationTask?.suggestedMinutes else { return nil }
        return Double(minutes) * 60
    }

    private var timerProgress: Double {
        guard let total = suggestedSeconds, total > 0 else { return 0 }
        return min(elapsed / total, 1.0)
    }

    // MARK: - Body

    var body: some View {
        Group {
            if let t = activationTask {
                mainContent(task: t)
            } else {
                ContentUnavailableView(
                    String(localized: "Session not found"),
                    systemImage: "questionmark.circle"
                )
            }
        }
        .navigationBarBackButtonHidden(true)
        .onChange(of: requestCompleteFromPill) { _, requested in
            guard requested else { return }
            completeSession()
            requestCompleteFromPill = false
        }
    }

    @ViewBuilder
    private func mainContent(task: ActivationTask) -> some View {
        ZStack {
            if !embeddedInFlow {
                AppColors.gray100.ignoresSafeArea()
            }

            VStack(spacing: Spacing.xl) {
                Spacer()

                timerRing

                VStack(spacing: Spacing.xxs) {
                    Text(task.localizedTitle)
                        .appFont(.h2)
                        .foregroundStyle(TextColors.primary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.lg)

                    if let hint = task.localizedHint {
                        Text(hint)
                            .appFont(.body)
                            .foregroundStyle(TextColors.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Spacing.lg)
                    }
                }

                moodBeforeStrip

                Spacer()
            }
            .ignoresSafeArea(edges: .bottom)
        }
    }

    // MARK: - Timer Ring

    private var timerRing: some View {
        ZStack {
            Circle()
                .stroke(AppColors.gray200, lineWidth: Layout.ringStroke)

            if suggestedSeconds != nil {
                Circle()
                    .trim(from: 0, to: timerProgress)
                    .stroke(
                        AppColors.primary,
                        style: StrokeStyle(lineWidth: Layout.ringStroke, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(AppAnimation.fast, value: timerProgress)
            }

            VStack(spacing: Spacing.tight) {
                Text(formatTime(elapsed))
                    .appFont(.monoLarge)
                    .monospacedDigit()
                    .foregroundStyle(TextColors.primary)
                    .contentTransition(.numericText())

                if let suggested = activationTask?.suggestedMinutes {
                    Text(String(format: String(localized: "of %lld min"), Int64(suggested)))
                        .appFont(.caption)
                        .foregroundStyle(TextColors.secondary)
                }
            }
        }
        .frame(width: Layout.ringSize, height: Layout.ringSize)
    }

    // MARK: - Mood Before Strip

    @ViewBuilder
    private var moodBeforeStrip: some View {
        if let mood = session?.moodBefore {
            HStack(spacing: Spacing.xxs) {
                Text(String(localized: "Mood before"))
                    .appFont(.small)
                    .foregroundStyle(TextColors.secondary)

                Text(Mood.emoji(for: mood))
                    .font(.system(size: IconSize.inline))
            }
            .padding(.horizontal, Spacing.xl)
        }
    }

    // MARK: - Actions

    private func completeSession() {
        if let s = session {
            s.actualMinutes = max(0, Int(elapsed / 60))
            try? modelContext.save()
        }
        onMovedToPost()
    }

    // MARK: - Helpers

    private func formatTime(_ interval: TimeInterval) -> String {
        let total = Int(interval)
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private enum Layout {
        static let ringSize: CGFloat = 168
        static let ringStroke: CGFloat = 8
    }
}
