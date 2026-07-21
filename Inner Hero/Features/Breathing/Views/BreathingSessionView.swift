import SwiftUI

/// The breathing session (spec §4): a paced circle and almost nothing else.
///
/// On `AppColors.sessionSurface` — deliberately dark in both themes. Fifteen
/// minutes of light-gray screen in the evening goes straight into a dilated
/// pupil, and an adaptive surface would fail exactly the argument the dark one
/// exists for. The forced dark `colorScheme` underneath is what makes the
/// content tokens resolve correctly on top of it.
struct BreathingSessionView: View {
    @Bindable var viewModel: BreathingFlowViewModel
    let onComplete: () -> Void
    let onFinishEarly: () -> Void

    @State private var haptics = BreathingHapticPlayer()
    /// The phase the haptics have already been fired for.
    @State private var lastHapticPhase: BreathPhase?

    var body: some View {
        // Fast enough that a phase boundary is detected within ~100 ms — the
        // haptic ramp and the shape both start from here, and a coarser tick
        // would let them drift audibly behind the count.
        TimelineView(.periodic(from: .now, by: 0.1)) { context in
            let now = context.date
            let current = viewModel.phase(now: now)

            VStack(spacing: 0) {
                meta
                Spacer()
                BreathingCircle(
                    phase: current.phase,
                    phaseDuration: viewModel.phaseDuration(current.phase),
                    isPaused: viewModel.isPaused
                )
                Text(viewModel.isPaused ? String(localized: "Paused") : current.phase.title)
                    .appFont(.h2)
                    .foregroundStyle(TextColors.primary)
                    .padding(.top, Spacing.xl)
                    .animation(AppAnimation.fast, value: current.phase)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // An inset, not the last row of the stack: only this nests the pill
            // into the bottom rounding the way the Start and Done buttons do.
            // Inside the stack it stayed above the safe area no matter what
            // padding it was given.
            .safeAreaInset(edge: .bottom) {
                bottomPill(now: now)
                    .padding(.horizontal, Spacing.md)
                    .padding(.top, Spacing.md)
                    .padding(.bottom, Spacing.lg)
            }
            .onChange(of: current.phase) { _, newPhase in
                playHaptic(for: newPhase)
            }
        }
        // Only the surface runs under the notch and the home indicator. The
        // content must not: with a blanket `.ignoresSafeArea()` the meta line
        // slid under the Dynamic Island and was cut in half.
        .background(AppColors.sessionSurface.ignoresSafeArea())
        .environment(\.colorScheme, .dark)
        // Lets the pinned pill sit in the home-indicator strip, like the
        // Start/Done pills on the form steps.
        .ignoresSafeArea(.container, edges: .bottom)
        // A recorded UIKit exception (see ScreenAwake): without it iOS sleeps
        // the display mid-session and takes CoreHaptics down with it.
        .keepScreenAwake()
        .onAppear {
            haptics.start()
            playHaptic(for: viewModel.phase(now: Date()).phase)
        }
        .onDisappear { haptics.stop() }
        .task { await watchForEnd() }
    }

    /// The clock is polled rather than scheduled: a pause moves the end, and a
    /// timer set at start would have to be torn down and rebuilt every time.
    private func watchForEnd() async {
        while !Task.isCancelled {
            try? await Task.sleep(for: .milliseconds(250))
            if viewModel.isFinished(now: Date()) {
                HapticFeedback.success()
                onComplete()
                return
            }
        }
    }

    // MARK: Pieces

    /// Quiet orientation, not a headline: what is running and for how long.
    private var meta: some View {
        Text(metaText)
            .appFont(.small)
            .foregroundStyle(TextColors.secondary)
            .padding(.top, Spacing.md)
    }

    private var metaText: String {
        String(
            format: String(localized: "%1$@ · %2$@ min"),
            viewModel.pattern.title,
            BreathingLadder.minutesLabel(seconds: viewModel.plannedDuration)
        )
    }

    /// Finish · time left · pause. No hold-to-confirm, unlike the exposure
    /// session: the phone is in the user's hand with the screen on, and leaving
    /// early destroys nothing — the record is saved and the "after" screen
    /// still asks its question.
    private func bottomPill(now: Date) -> some View {
        SessionFlowBottomPill(
            // The default black capsule would vanish on the dark surface.
            background: AppColors.cardBackground
        ) {
            Button {
                onFinishEarly()
            } label: {
                HStack(spacing: Spacing.xxxs) {
                    Image(systemName: "flag.checkered")
                        .appFont(.small)
                        .accessibilityHidden(true)
                    Text(String(localized: "Finish"))
                        .appFont(.buttonSmall)
                }
                .foregroundStyle(TextColors.secondary)
            }
            .buttonStyle(.plain)
        } center: {
            // Small, and in the pill rather than centred large: the circle is
            // the content of this screen, and a big timer would take the
            // attention it needs. A countdown is fine here — this is training
            // on a schedule, not an exposure whose end must stay unpredictable.
            Text(BreathingFlowViewModel.formatRemaining(viewModel.remaining(now: now)))
                .appFont(.mono)
                .monospacedDigit()
                .foregroundStyle(TextColors.primary)
                .accessibilityLabel(String(localized: "Time left"))
        } right: {
            Button {
                viewModel.togglePause()
                if viewModel.isPaused { lastHapticPhase = nil }
            } label: {
                Image(systemName: viewModel.isPaused ? "play.fill" : "pause.fill")
                    .appFont(.bodyMedium)
                    .foregroundStyle(TextColors.primary)
                    .frame(minWidth: TouchTarget.minimum, minHeight: TouchTarget.minimum)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                viewModel.isPaused
                    ? String(localized: "Resume")
                    : String(localized: "Pause")
            )
        }
    }

    // MARK: Haptics

    private func playHaptic(for phase: BreathPhase) {
        guard !viewModel.isPaused, phase != lastHapticPhase else { return }
        lastHapticPhase = phase
        haptics.play(
            phase: phase,
            pattern: viewModel.pattern,
            duration: viewModel.phaseDuration(phase)
        )
    }

}

#Preview {
    BreathingSessionView(
        viewModel: BreathingFlowViewModel(),
        onComplete: {},
        onFinishEarly: {}
    )
}
