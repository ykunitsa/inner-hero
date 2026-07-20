import SwiftUI

/// The "during" screen of a planned exposure (spec §3): deliberately near
/// empty — the user is out there doing the exposure, not watching the phone.
/// Stopwatch counts UP (a countdown would make the end predictable). The
/// last 5 seconds are a haptic countdown, the end is a distinct signal; in
/// the background a single notification vibrates at the end moment instead.
struct PlannedExposureSessionView: View {
    @Bindable var viewModel: PlannedExposureFlowViewModel
    let notificationsAuthorized: Bool
    let onComplete: () -> Void
    let onFinishEarly: () -> Void

    /// "Finish early" requires a deliberate hold — an accidental tap must
    /// not end the session.
    private let holdDuration: TimeInterval = 3

    @State private var holdProgress: Double = 0
    @State private var showHoldHint = false
    @State private var didFinishEarly = false

    var body: some View {
        VStack(spacing: 0) {
            Text(viewModel.trimmedActivity)
                .appFont(.small)
                .foregroundStyle(TextColors.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.md)

            Spacer()

            TimelineView(.periodic(from: .now, by: 0.5)) { context in
                Text(PlannedExposureFlowViewModel.formatElapsed(viewModel.elapsed(now: context.date)))
                    .appFont(.timerDisplay)
                    .monospacedDigit()
                    .foregroundStyle(TextColors.primary)
            }
            .accessibilityLabel(String(localized: "Elapsed time"))

            Text(hint)
                .appFont(.body)
                .foregroundStyle(TextColors.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.sm)

            Spacer()

            finishEarlyButton
                .padding(.bottom, Spacing.lg)
        }
        .frame(maxWidth: .infinity)
        // Same surface as the before/after steps — the background must not
        // shift underneath the user mid-session.
        .background(AppColors.cardBackground.ignoresSafeArea())
        // Same low placement as the pinned pills on the form screens.
        .ignoresSafeArea(.container, edges: .bottom)
        .task { await watchForEndSignals() }
    }

    private var hint: String {
        notificationsAuthorized
            ? String(localized: "Vibration will tell you when it's done")
            : String(localized: "Vibration works while the screen is on")
    }

    /// Quiet secondary action — available, not inviting (the screen's job is
    /// to be ignored). Names the fact, never "Cancel" (principle 1.5).
    /// A 3-second hold guards against pocket taps; the ring around the stop
    /// icon is the hold indicator.
    private var finishEarlyButton: some View {
        VStack(spacing: Spacing.xxs) {
            HStack(spacing: Spacing.xxs) {
                holdIndicator
                Text(String(localized: "Finish early"))
                    .appFont(.body)
            }
            .foregroundStyle(TextColors.secondary)
            .padding(.horizontal, Spacing.md)
            .frame(minHeight: TouchTarget.minimum)
            .background(Capsule().fill(AppColors.gray100))
            .contentShape(Capsule())
            .onLongPressGesture(
                minimumDuration: holdDuration,
                maximumDistance: TouchTarget.minimum
            ) {
                didFinishEarly = true
                onFinishEarly()
            } onPressingChanged: { pressing in
                guard !didFinishEarly else { return }
                if pressing {
                    withAnimation(.linear(duration: holdDuration)) { holdProgress = 1 }
                } else {
                    // Released before the hold completed — reset and explain.
                    withAnimation(AppAnimation.fast) { holdProgress = 0 }
                    showHoldHint = true
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel(String(localized: "Finish early"))
            .accessibilityHint(String(localized: "Hold for 3 seconds"))
            // VoiceOver users can't perform a timed hold — expose the action
            // directly instead.
            .accessibilityAction {
                didFinishEarly = true
                onFinishEarly()
            }

            Text(String(localized: "Hold for 3 seconds"))
                .appFont(.small)
                .foregroundStyle(TextColors.tertiary)
                .opacity(showHoldHint ? 1 : 0)
                .animation(AppAnimation.standard, value: showHoldHint)
                .accessibilityHidden(true)
        }
    }

    /// Stop glyph inside a progress ring that fills over the hold.
    private var holdIndicator: some View {
        ZStack {
            Circle()
                .stroke(AppColors.gray200, lineWidth: BorderWidth.standard * 2)
            Circle()
                .trim(from: 0, to: holdProgress)
                .stroke(
                    AppColors.accent,
                    style: StrokeStyle(lineWidth: BorderWidth.standard * 2, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            Image(systemName: "stop.fill")
                .appFont(.caption)
        }
        .frame(width: IconSize.inline, height: IconSize.inline)
        .accessibilityHidden(true)
    }

    /// Polls the session clock. Suspended in the background — after a return
    /// the view model produces at most one catch-up signal, and the end
    /// vibration itself is covered by the scheduled notification.
    private func watchForEndSignals() async {
        while !Task.isCancelled {
            try? await Task.sleep(for: .milliseconds(250))
            switch viewModel.dueSignal(now: Date()) {
            case .countdownTick:
                HapticFeedback.medium()
            case .sessionEnd:
                HapticFeedback.success()
                onComplete()
                return
            case nil:
                break
            }
        }
    }
}

#Preview {
    PlannedExposureSessionView(
        viewModel: PlannedExposureFlowViewModel(),
        notificationsAuthorized: true,
        onComplete: {},
        onFinishEarly: {}
    )
}
