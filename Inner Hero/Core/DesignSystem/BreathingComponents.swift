import SwiftUI

// ─────────────────────────────────────────────
// MARK: Breathing Components
// ─────────────────────────────────────────────
//
// Everything the breathing exercise (spec §4) draws. A separate file from
// `Components.swift` on purpose — that one is already ~1200 lines and stands in
// TECH_DEBT #3 waiting to be split, not to be grown.

// ─────────────────────────────────────────────
// MARK: Blob
// ─────────────────────────────────────────────

/// A closed, slowly deforming near-circle.
///
/// `wobble` is the deformation as a fraction of the radius. It is kept small on
/// purpose: the circle is the *instruction* — its size says inhale or exhale —
/// and a shape that wanders more than the phase scale moves would drown the
/// signal in decoration.
struct BreathingBlob: Shape {
    /// Seconds since an arbitrary origin. The caller feeds it a running clock.
    var time: Double
    /// 0 draws an exact circle.
    var wobble: Double = 0.05

    /// Control points around the circumference. Five, not six: an odd count
    /// cannot deform symmetrically, so the silhouette leans and rolls instead
    /// of pulsing evenly — which is what reads as *floating*.
    private static let lobes = 5

    /// Deliberately non-commensurate periods (seconds) — with harmonic ones the
    /// shape returns to the same silhouette every few seconds and the loop
    /// becomes something to watch instead of the breath.
    private static let periods: [Double] = [5, 8, 11]

    var animatableData: Double {
        get { time }
        set { time = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let baseRadius = min(rect.width, rect.height) / 2

        let points: [CGPoint] = (0..<Self.lobes).map { index in
            let angle = Double(index) / Double(Self.lobes) * 2 * .pi
            var offset = 0.0
            for (harmonic, period) in Self.periods.enumerated() {
                offset += sin(time * 2 * .pi / period + angle * Double(harmonic + 1))
            }
            let radius = baseRadius * (1 + wobble * offset / Double(Self.periods.count))
            return CGPoint(
                x: center.x + cos(angle) * radius,
                y: center.y + sin(angle) * radius
            )
        }

        // Quadratic curves through the midpoints, with the sampled points as
        // controls: a closed C1-continuous outline with no seam at the start.
        return Path { path in
            guard points.count > 2 else { return }
            func midpoint(_ a: CGPoint, _ b: CGPoint) -> CGPoint {
                CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
            }
            path.move(to: midpoint(points[points.count - 1], points[0]))
            for index in points.indices {
                let control = points[index]
                let next = points[(index + 1) % points.count]
                path.addQuadCurve(to: midpoint(control, next), control: control)
            }
            path.closeSubpath()
        }
    }
}

// ─────────────────────────────────────────────
// MARK: Breathing Circle
// ─────────────────────────────────────────────

/// The breathing guide: a soft blob that expands on the inhale, holds its size
/// through a hold, and contracts on the exhale.
///
/// **The scale is the exercise.** It is driven by `phase` and animated over
/// `phaseDuration`, so a hold needs no special case — the phase changes but the
/// scale does not, and the shape simply stops. Everything else here (the
/// wobble, the drift, the blur) is ambient.
///
/// Reduce Motion splits cleanly along that line: the scale **always** animates,
/// because switching it off would delete the instrument; the wobble and drift
/// switch off, because ambient motion is exactly what the setting is for.
///
/// Usage:
/// ```swift
/// BreathingCircle(phase: .inhale, phaseDuration: 4, isPaused: false)
/// ```
struct BreathingCircle: View {
    let phase: BreathPhase
    /// Length of the current phase — the scale animation matches it exactly, so
    /// the shape finishes moving as the phase ends.
    let phaseDuration: TimeInterval
    var isPaused: Bool = false
    var color: Color = AppColors.positive

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Sized against body text so it keeps its proportion to the phase label at
    /// every Dynamic Type size.
    @ScaledMetric(relativeTo: .body) private var diameter: CGFloat = 210

    /// Contracted at the bottom of the breath, expanded at the top. The gap is
    /// wide (0.42 → 1.0) because this is the *instruction*: a difference the
    /// user has to read out of the corner of their eye, not a subtle accent.
    private static let contracted: CGFloat = 0.42

    /// Expanded through the inhale and the hold that follows it, contracted
    /// through the exhale and its hold. The two holds are separate phases
    /// precisely so each can inherit the size it should keep.
    private var targetScale: CGFloat {
        switch phase {
        case .inhale, .holdAfterInhale: 1.0
        case .exhale, .holdAfterExhale: Self.contracted
        }
    }

    /// Driven explicitly rather than by `.animation(value: phase)`.
    ///
    /// With the implicit version the view arrived on screen already at the
    /// inhale's size: the first phase had nothing left to animate *to*, and the
    /// exercise opened on a circle that simply sat there for four seconds.
    /// Starting contracted and animating on appear makes the very first breath
    /// a real one.
    @State private var animatedScale: CGFloat = BreathingCircle.contracted

    private var isAmbientMotionOn: Bool { !reduceMotion && !isPaused }

    var body: some View {
        Group {
            if isAmbientMotionOn {
                TimelineView(.animation) { context in
                    blob(time: context.date.timeIntervalSinceReferenceDate)
                }
            } else {
                // No timeline at all when nothing ambient is moving — a
                // per-frame redraw of a blurred shape is not free, and a paused
                // session can sit here for a long time.
                blob(time: 0, wobble: 0, drift: .zero)
            }
        }
        // Room for the halo and the drift, which reach past the body.
        .frame(width: diameter * 1.35, height: diameter * 1.35)
        .accessibilityHidden(true)
        .onAppear { animate() }
        .onChange(of: phase) { _, _ in animate() }
    }

    /// `.easeInOut` because a breath has no sharp start or stop; the duration
    /// matches the phase, so the movement ends exactly when the phase does.
    private func animate() {
        withAnimation(.easeInOut(duration: max(phaseDuration, 0.1))) {
            animatedScale = targetScale
        }
    }

    private func blob(time: Double) -> some View {
        blob(
            time: time,
            // Still ~4× smaller than the phase scale travels (0.42 → 1.0), so
            // the shape reads as alive without competing with the instruction.
            wobble: 0.14,
            drift: CGSize(
                width: sin(time * 2 * .pi / 17) * diameter * 0.035,
                height: cos(time * 2 * .pi / 23) * diameter * 0.035
            )
        )
    }

    private func blob(time: Double, wobble: Double, drift: CGSize) -> some View {
        ZStack {
            // Halo — offset in time from the body so the two outlines drift
            // apart slightly instead of moving as one rigid shape.
            BreathingBlob(time: time + 3, wobble: wobble)
                .fill(color.opacity(Opacity.emphasizedBorder))
                .blur(radius: diameter * 0.10)
                .scaleEffect(1.18)

            // Body. Blurred on purpose: a crisp edge reads as a *button*, and
            // the shape is meant to be breathed with, not pressed.
            BreathingBlob(time: time, wobble: wobble)
                .fill(color)
                .blur(radius: diameter * 0.035)

            // Pale sheen drifting inside the body — this is what makes the
            // shape read as floating rather than merely wobbling. Masked to the
            // body so it never spills past the edge.
            sheen(time: time)
                .mask(BreathingBlob(time: time, wobble: wobble))
                .blur(radius: diameter * 0.05)
        }
        .offset(drift)
        .scaleEffect(animatedScale)
    }

    /// Two soft light patches wandering on slow, non-repeating orbits.
    private func sheen(time: Double) -> some View {
        let first = UnitPoint(
            x: 0.42 + sin(time * 2 * .pi / 19) * 0.16,
            y: 0.36 + cos(time * 2 * .pi / 23) * 0.16
        )
        let second = UnitPoint(
            x: 0.62 + cos(time * 2 * .pi / 29) * 0.18,
            y: 0.66 + sin(time * 2 * .pi / 31) * 0.14
        )
        return ZStack {
            RadialGradient(
                colors: [.white.opacity(Opacity.emphasizedBorder), .clear],
                center: first,
                startRadius: 0,
                endRadius: diameter * 0.42
            )
            RadialGradient(
                colors: [.white.opacity(Opacity.standardBorder), .clear],
                center: second,
                startRadius: 0,
                endRadius: diameter * 0.34
            )
        }
    }
}

// ─────────────────────────────────────────────
// MARK: Breathing Type Cards
// ─────────────────────────────────────────────

/// The three breathing types as a visible row, one tap each.
///
/// Visible rather than hidden behind a "change" link: the type is a genuine
/// choice, and a menu between the icon and the action is the thing principle
/// 1.2 forbids. It costs vertical space, not taps.
///
/// The cards carry **no description** — a single line for the selected type
/// lives above them. Three descriptions side by side would each be two words
/// wide.
struct BreathingTypeCards: View {
    @Binding var selection: BreathingPattern
    /// Green, not the CTA red: the tint ties the choice to the circle that
    /// follows it, and leaves the single screen accent to "Start".
    var tint: Color = AppColors.positive

    /// Roughly the tile width at default type — close enough to square.
    @ScaledMetric(relativeTo: .body) private var tileSide: CGFloat = 104

    var body: some View {
        HStack(spacing: Spacing.xxs) {
            ForEach(BreathingPattern.allCases, id: \.self) { pattern in
                card(pattern)
            }
        }
        // Without the priority the enclosing stack squeezes the row's height
        // first, and `aspectRatio` then shrinks the tiles' *width* to match —
        // three small squares floating in the middle of the screen.
        .layoutPriority(1)
    }

    private func card(_ pattern: BreathingPattern) -> some View {
        let isSelected = pattern == selection

        return Button {
            guard pattern != selection else { return }
            selection = pattern
            HapticFeedback.selection()
        } label: {
            VStack(spacing: Spacing.xxxs) {
                Image(systemName: pattern.icon)
                    .appFont(.h2)
                    .foregroundStyle(isSelected ? tint : TextColors.secondary)
                Text(pattern.title)
                    .appFont(isSelected ? .smallMedium : .small)
                    .foregroundStyle(TextColors.primary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, Spacing.xxs)
            .padding(.vertical, Spacing.xs)
            // Square-ish tiles: the row reads as three equal choices rather
            // than three labels sharing a strip.
            //
            // A floor, not `aspectRatio(1)`: a true aspect ratio inside an
            // HStack resolves against whatever height the parent hands down,
            // and then shrinks the *width* to match it. This tracks Dynamic
            // Type and stays a tile at every size.
            .frame(maxWidth: .infinity, minHeight: tileSide)
            // Fill carries the state, same grammar as `SegmentedChoice`.
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                    .fill(isSelected
                          ? tint.opacity(Opacity.mediumBackground)
                          : AppColors.cardBackground)
            )
        }
        .buttonStyle(.plain)
        .animation(AppAnimation.fast, value: isSelected)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityLabel("\(pattern.title). \(pattern.formula)")
    }
}

// MARK: - Preview

#Preview("Breathing") {
    @Previewable @State var pattern = BreathingPattern.box
    @Previewable @State var phase = BreathPhase.inhale

    VStack(spacing: Spacing.xl) {
        BreathingCircle(phase: phase, phaseDuration: 4)
        Button("Next phase") {
            let all = BreathPhase.allCases
            phase = all[(all.firstIndex(of: phase)! + 1) % all.count]
        }
        BreathingTypeCards(selection: $pattern)
            .padding(.horizontal, Spacing.sm)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(AppColors.sessionSurface)
    .environment(\.colorScheme, .dark)
}
