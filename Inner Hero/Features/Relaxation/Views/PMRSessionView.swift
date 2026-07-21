import SwiftUI

/// The PMR session (spec §5): the voice leads, and the screen gets out of the
/// way.
///
/// The inverse of the breathing session. There the circle *is* the instruction
/// and the screen is held awake; here the eyes are closed, the instruction is
/// spoken, and the screen dims itself after a few seconds. `keepScreenAwake()`
/// is deliberately absent — the voice survives a dark screen through the
/// `.playback` audio session and `UIBackgroundModes = audio`, which is exactly
/// what the exercise needs.
struct PMRSessionView: View {
    @Bindable var viewModel: PMRFlowViewModel
    let onComplete: () -> Void
    let onEndEarly: () -> Void

    @State private var voice: any PMRVoice = SystemPMRVoice()
    /// The cue the voice has already spoken, so a redraw does not restart it.
    @State private var spokenCueIndex: Int?

    var body: some View {
        // Half a second is plenty: cues are seconds long, and a tighter tick
        // would just spin the CPU through a fifteen-minute session.
        TimelineView(.periodic(from: .now, by: 0.5)) { context in
            let now = context.date
            let cue = viewModel.currentCue(now: now)

            PMRDimmingContainer(
                // An interruption needs a decision, so the screen stays up for it.
                isDimmingEnabled: !viewModel.isInterrupted
            ) {
                // The pill lives *inside* the awake content, not as an inset on
                // the container: as a sibling it kept its full brightness after
                // the screen dimmed, which is exactly the lit rectangle this
                // screen exists to avoid.
                awakeContent(cue: cue, now: now)
                    .safeAreaInset(edge: .bottom) {
                        bottomPill(now: now)
                            .padding(.horizontal, Spacing.md)
                            .padding(.top, Spacing.md)
                            .padding(.bottom, Spacing.lg)
                    }
            } dimmed: {
                // The one line that answers "is this still running?" without a
                // tap. Never blank — see PMRDimmingContainer. Keeps the glow:
                // at Opacity.dimmedContent it is what makes the line legible
                // rather than a smudge.
                PMRCueText(headline: cue?.headline ?? "")
            }
            // Cues dissolve into each other rather than snapping; the animation
            // lives here so both the awake and the dimmed line move together.
            .animation(AppAnimation.slow, value: cue?.headline)
            .onChange(of: viewModel.currentCueIndex(now: now)) { _, index in
                speak(index: index)
            }
        }
        .background(AppColors.sessionSurface.ignoresSafeArea())
        .environment(\.colorScheme, .dark)
        .ignoresSafeArea(.container, edges: .bottom)
        .onAppear { speak(index: viewModel.currentCueIndex(now: Date())) }
        .onDisappear { voice.stop() }
        .task { await watchForEnd() }
    }

    // MARK: Content

    @ViewBuilder
    private func awakeContent(cue: PMRCue?, now: Date) -> some View {
        VStack(spacing: 0) {
            meta(now: now)
            Spacer()

            PMRCueText(headline: cue?.headline ?? "", detail: cue?.detail)

            if viewModel.isInterrupted {
                resumeButton
                    .padding(.top, Spacing.lg)
            }

            Spacer()
        }
        // No horizontal padding here: `PMRCueText` insets itself, and adding a
        // second margin on top of it narrowed the instruction to a column.
    }

    /// Quiet orientation: where the script is, not a headline. Absent on the
    /// cue-controlled step, which has no groups to count.
    @ViewBuilder
    private func meta(now: Date) -> some View {
        if let position = viewModel.groupPosition(now: now) {
            Text(
                String(
                    format: String(localized: "%1$d of %2$d · %3$@"),
                    position.index,
                    position.total,
                    position.group.title
                )
            )
            .appFont(.small)
            .foregroundStyle(TextColors.secondary)
            .padding(.top, Spacing.md)
        }
    }

    /// The script never restarts itself after a call — a voice resuming
    /// mid-instruction while the phone is still at the user's ear is worse than
    /// waiting for a tap.
    private var resumeButton: some View {
        Button {
            viewModel.resumeAfterInterruption()
        } label: {
            Text(String(localized: "Resume"))
                .appFont(.buttonSmall)
                .foregroundStyle(TextColors.primary)
                .padding(.horizontal, Spacing.md)
                .frame(minHeight: TouchTarget.minimum)
                .background(
                    Capsule().fill(AppColors.cardBackground)
                )
        }
        .buttonStyle(.plain)
    }

    /// End early · elapsed. No pause button, unlike breathing: the script runs
    /// continuously, and pausing inside a release phase breaks the phase itself.
    private func bottomPill(now: Date) -> some View {
        SessionFlowBottomPill(background: AppColors.cardBackground) {
            Button {
                onEndEarly()
            } label: {
                HStack(spacing: Spacing.xxxs) {
                    Image(systemName: "flag.checkered")
                        .appFont(.small)
                        .accessibilityHidden(true)
                    // Names the fact, never "Cancel" (principle 1.5).
                    Text(String(localized: "End early"))
                        .appFont(.buttonSmall)
                }
                .foregroundStyle(TextColors.secondary)
            }
            .buttonStyle(.plain)
        } center: {
            // Counting up, not down: the end is decided by the script, and a
            // countdown would promise a precision the estimate does not have.
            Text(Self.formatElapsed(viewModel.elapsed(now: now)))
                .appFont(.mono)
                .monospacedDigit()
                .foregroundStyle(TextColors.primary)
                .accessibilityLabel(String(localized: "Time elapsed"))
        } right: {
            EmptyView()
        }
    }

    // MARK: Voice

    private func speak(index: Int?) {
        guard let index, index != spokenCueIndex else { return }
        spokenCueIndex = index
        // A silent cue speaks nothing — the pause is silence by construction.
        let cue = viewModel.cues[index]
        voice.speak(cue.spoken, delivery: cue.delivery)
    }

    /// Polled rather than scheduled: an interruption moves the end, and a timer
    /// set at start would have to be torn down and rebuilt each time.
    private func watchForEnd() async {
        while !Task.isCancelled {
            try? await Task.sleep(for: .milliseconds(500))
            if viewModel.isFinished(now: Date()) {
                voice.stop()
                onComplete()
                return
            }
        }
    }

    nonisolated static func formatElapsed(_ interval: TimeInterval) -> String {
        let total = max(Int(interval), 0)
        return String(format: "%02d:%02d", total / 60, total % 60)
    }
}

#Preview {
    PMRSessionView(
        viewModel: PMRFlowViewModel(),
        onComplete: {},
        onEndEarly: {}
    )
}
