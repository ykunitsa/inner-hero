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
    @State private var didFinishEarly = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// One dot per elapsed minute. Sized against body text so the row keeps
    /// its proportion to the stopwatch at every Dynamic Type size.
    ///
    /// 8pt, not 6: at the first minute there is exactly *one* dot on screen,
    /// and at 6pt it read as a speck of dust rather than a mark. Twenty of
    /// them (the longest range the form allows) still fit one line.
    @ScaledMetric(relativeTo: .body) private var minuteDotSize: CGFloat = 8

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

            // Ticks aligned to the session start, not to `.now`: the digit
            // roll has to land on the same second boundary the value changes
            // on, or it animates at a random offset inside every second.
            TimelineView(.periodic(from: viewModel.startedAt ?? .now, by: 1)) { context in
                let elapsed = viewModel.elapsed(now: context.date)
                let seconds = Int(elapsed)

                VStack(spacing: Spacing.md) {
                    Text(PlannedExposureFlowViewModel.formatElapsed(elapsed))
                        .appFont(.timerDisplay)
                        .monospacedDigit()
                        .foregroundStyle(TextColors.primary)
                        .contentTransition(reduceMotion ? .identity : .numericText())
                        .animation(AppAnimation.fast, value: seconds)
                        .accessibilityLabel(String(localized: "Elapsed time"))

                    minuteDots(count: seconds / 60)
                }
            }

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
        .formBackground()
        // Same low placement as the pinned pills on the form screens.
        .ignoresSafeArea(.container, edges: .bottom)
        .task { await watchForEndSignals() }
    }

    /// Elapsed minutes as a growing row of dots — **no track, no container,
    /// no total**. That is the whole constraint: anything bounded would let
    /// the user read off how much is left, and the end of a planned exposure
    /// must stay unpredictable (spec §3). This counts up and simply keeps
    /// going, like the stopwatch above it.
    ///
    /// Not a pulse or a breathing shape either — this app has a breathing
    /// exercise (spec §4), and a rhythmic figure here would read as "calm
    /// down", which is the opposite of the exposure model (principle 1.1).
    private func minuteDots(count: Int) -> some View {
        HStack(spacing: minuteDotSize) {
            ForEach(0..<max(count, 0), id: \.self) { _ in
                Circle()
                    .fill(AppColors.gray400)
                    .frame(width: minuteDotSize, height: minuteDotSize)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        // Height is reserved from the start, so the stopwatch doesn't jump
        // up the screen when the first minute lands.
        .frame(height: minuteDotSize)
        .animation(reduceMotion ? nil : AppAnimation.standard, value: count)
        // The stopwatch above already says this, more precisely.
        .accessibilityHidden(true)
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
            .background(Capsule().fill(AppColors.cardBackground))
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
                    // Released before the hold completed.
                    withAnimation(AppAnimation.fast) { holdProgress = 0 }
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

            // Always visible, never revealed after a failed attempt: a tap
            // that silently does nothing is a dead end, and this screen is
            // used by someone mid-exposure who has no attention to spend
            // working out why the button ignored them (codex §1).
            Text(String(localized: "Hold for 3 seconds"))
                .appFont(.small)
                .foregroundStyle(TextColors.tertiary)
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
