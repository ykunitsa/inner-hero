import SwiftUI

//  PMR-specific components (spec §5).
//
//  Separate file rather than more weight on `Components.swift`, which is ~1,265
//  lines and is TECH_DEBT #3 waiting to be split — the same reasoning that gave
//  breathing its own `BreathingComponents.swift`.

// MARK: - Step cards

/// The ladder as a scrolling row of cards, on the "before" screen itself.
///
/// Same grammar as `BreathingTypeCards` — filled tile carries the selection,
/// the description of the *selected* step lives once in the block above rather
/// than inside each tile, where every sentence would be two words wide.
///
/// Horizontal scroll rather than an equal-width row: five steps at tile width do
/// not fit, and a partial card at the trailing edge is the affordance that says
/// so. This replaced a "Change" button opening a sheet — the button read as a
/// stray link in the middle of the screen, and the sheet put a whole navigation
/// step between the user and a choice that fits on the screen it belongs to.
struct PMRStepCards: View {
    @Binding var selection: PMRStep
    /// Green, not the CTA red: the tint ties the choice to the session that
    /// follows it and leaves the single screen accent to "Start".
    var tint: Color = AppColors.positive

    @ScaledMetric(relativeTo: .body) private var tileWidth: CGFloat = 108
    @ScaledMetric(relativeTo: .body) private var tileMinHeight: CGFloat = 100
    @ScaledMetric(relativeTo: .body) private var dotDiameter: CGFloat = 18
    @ScaledMetric(relativeTo: .body) private var dotFillDiameter: CGFloat = 9

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: Spacing.xxs) {
                ForEach(PMRStep.allCases, id: \.self) { step in
                    card(step)
                }
            }
            .scrollTargetLayout()
        }
        .scrollIndicators(.hidden)
        // Keeps the chosen step in view when it is seeded from history rather
        // than tapped — otherwise a user on "16 groups" opens the screen looking
        // at four cards that are all something else.
        .scrollPosition(id: .constant(selection), anchor: .center)
    }

    private func card(_ step: PMRStep) -> some View {
        let isSelected = step == selection

        return Button {
            guard step != selection else { return }
            selection = step
            HapticFeedback.selection()
        } label: {
            VStack(spacing: Spacing.xxxs) {
                Text(step.title)
                    .appFont(isSelected ? .smallMedium : .small)
                    .foregroundStyle(TextColors.primary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Text(minutesText(step))
                    .appFont(.small)
                    .foregroundStyle(isSelected ? tint : TextColors.tertiary)
            }
            .padding(.horizontal, Spacing.xxs)
            .padding(.vertical, Spacing.xs)
            // Room for the dot above the title, so the two never collide at
            // large Dynamic Type.
            .padding(.top, dotDiameter)
            .frame(width: tileWidth)
            .frame(minHeight: tileMinHeight)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                    .fill(isSelected
                          ? tint.opacity(Opacity.mediumBackground)
                          : AppColors.cardBackground)
            )
            // An overlay on the tile, not a row in the stack: inside the stack
            // the dot aligned to the *text* column and drifted inward with the
            // content padding instead of sitting in the tile's corner.
            .overlay(alignment: .topLeading) {
                radioDot(isSelected: isSelected)
                    .padding(Spacing.xxs)
            }
        }
        .buttonStyle(.plain)
        .id(step)
        .animation(AppAnimation.fast, value: isSelected)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityLabel("\(step.title). \(minutesText(step)). \(step.summary)")
    }

    /// Same dot as `RadioCard`, at tile scale — the fill already carries the
    /// selection, and this says *which kind* of control the row is: pick one,
    /// not toggle several.
    private func radioDot(isSelected: Bool) -> some View {
        ZStack {
            Circle()
                .strokeBorder(
                    isSelected ? tint : AppColors.controlBorder,
                    lineWidth: isSelected ? BorderWidth.emphasized : BorderWidth.standard
                )
                .frame(width: dotDiameter, height: dotDiameter)
            if isSelected {
                Circle()
                    .fill(tint)
                    .frame(width: dotFillDiameter, height: dotFillDiameter)
            }
        }
        .accessibilityHidden(true)
    }

    private func minutesText(_ step: PMRStep) -> String {
        String(
            format: String(localized: "~%@ min"),
            PMRLadder.minutesLabel(duration: step.estimatedDuration)
        )
    }
}

// MARK: - Session cue text

/// The spoken instruction, on screen (spec §5).
///
/// Three things it does, all for the same reason — the user's eyes are closed
/// most of the time, so the moments they *do* look have to land immediately:
///
/// - **A soft glow.** At `Opacity.dimmedContent` on a near-black surface, plain
///   text sits right at the edge of legibility; the glow is what keeps the
///   dimmed line readable at a glance instead of demanding a squint.
/// - **A slow pulse.** The glow breathes on a cycle far slower than anything in
///   the script. It answers "is this still running?" without a tap, and it is
///   deliberately too slow to become the thing being watched.
/// - **Karaoke-style replace on change.** The finished instruction leaves
///   upward while the next one rises from below, both fading. The vertical
///   direction carries the sense that the script is *moving through* something,
///   which a cross-fade in place does not; a hard cut in a dark room reads as a
///   jolt, which is the opposite of what the exercise is training.
///
/// All three switch off under Reduce Motion except the glow itself, which is
/// legibility, not decoration.
struct PMRCueText: View {
    let headline: String
    var detail: String?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var isPulsing = false

    /// Wide and faint: a halo that lifts the glyphs off the surface, never a
    /// readable second copy of the text behind them.
    private static let glowRadiusLow: CGFloat = 10
    private static let glowRadiusHigh: CGFloat = 20
    /// Slower than any phase in the script, so it never competes with the
    /// instruction for attention.
    private static let pulsePeriod: TimeInterval = 5

    private var glowRadius: CGFloat {
        isPulsing ? Self.glowRadiusHigh : Self.glowRadiusLow
    }

    var body: some View {
        VStack(spacing: Spacing.xs) {
            Text(headline)
                .appFont(.h2)
                .foregroundStyle(TextColors.primary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .shadow(
                    color: TextColors.primary.opacity(Opacity.emphasizedBorder),
                    radius: glowRadius
                )

            if let detail {
                Text(detail)
                    .appFont(.body)
                    .foregroundStyle(TextColors.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .shadow(
                        color: TextColors.primary.opacity(Opacity.subtleBorder),
                        radius: glowRadius / 2
                    )
            }
        }
        .padding(.horizontal, Spacing.md)
        // Keyed on the instruction, not on the cue index: the two release cycles
        // of one group share a headline, and re-dissolving identical text would
        // look like a glitch.
        .id(headline)
        .transition(
            reduceMotion
                ? AnyTransition.opacity
                : .asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                )
        )
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(
                .easeInOut(duration: Self.pulsePeriod).repeatForever(autoreverses: true)
            ) {
                isPulsing = true
            }
        }
    }
}

// MARK: - Dimming

/// Wraps the PMR session screen in its own dimming behaviour: awake for a few
/// seconds, then down to a single faint line until the screen is touched.
///
/// This is the one screen in the app whose job is to **stop being looked at**.
/// The exercise is done with the eyes closed and the voice leading (spec §5),
/// so the screen exists to answer two questions — "is this still running?" and
/// "how do I stop?" — and to get out of the way in between.
///
/// What is easy to break here:
///
/// - **The dimmed state is not blank.** A fully black screen does not answer the
///   first question, and reads as a crash to anyone who opens their eyes. The
///   faint content is the answer, which is why `dimmed` gets `Opacity.dimmedContent`
///   and not zero.
/// - **Reduce Motion does not disable the dimming**, only the fade. The dimming
///   is a function of this screen, not decoration; switching it off would leave
///   a lit screen next to someone trying to relax.
/// - **VoiceOver never dims.** The visual fade would otherwise read as content
///   disappearing, when nothing has changed.
struct PMRDimmingContainer<Awake: View, Dimmed: View>: View {
    /// Set false to hold the screen awake — the intro, or a paused session that
    /// needs a decision from the user.
    var isDimmingEnabled: Bool = true

    @ViewBuilder var awake: Awake
    @ViewBuilder var dimmed: Dimmed

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled

    @State private var isAwake = true
    /// Bumped on every touch; the auto-dim task restarts with it.
    @State private var wakeCount = 0

    private var showsAwakeContent: Bool {
        isAwake || !isDimmingEnabled || voiceOverEnabled
    }

    var body: some View {
        ZStack {
            if showsAwakeContent {
                awake.transition(.opacity)
            } else {
                dimmed
                    .opacity(Opacity.dimmedContent)
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // The whole surface is the wake target, including the empty space —
        // fumbling for a button with your eyes shut is the thing to avoid.
        .contentShape(Rectangle())
        .onTapGesture { wake() }
        .animation(reduceMotion ? nil : AppAnimation.slow, value: showsAwakeContent)
        .task(id: wakeCount) {
            guard isDimmingEnabled, !voiceOverEnabled else { return }
            try? await Task.sleep(for: .seconds(InteractionTiming.sessionDimDelay))
            guard !Task.isCancelled else { return }
            isAwake = false
        }
        .onChange(of: isDimmingEnabled) { _, enabled in
            if !enabled { wake() }
        }
    }

    private func wake() {
        isAwake = true
        wakeCount += 1
    }
}
