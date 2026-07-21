import SwiftUI

// ─────────────────────────────────────────────
// MARK: Tick Track
// ─────────────────────────────────────────────
//
// One visual grammar for every "pick a value" control in the app: the value
// reads large above a ticked track with a marker on it. Three configurations
// sit on this primitive —
//
//   ScaleChoice        4 stops, words   ("definitely … unlikely")
//   IntensitySlider    11 stops, a digit (0–10 anxiety)
//   DurationRangeSlider 20 stops, two markers (3–8 min)
//
// Before this existed, the same screen asked three questions with three
// different-looking controls, and the differences carried no meaning.

/// Tick positions and hit-testing for a track. Kept separate from the view so
/// the geometry can be shared by single- and double-marker controls.
struct TickTrackGeometry {
    let bounds: ClosedRange<Int>
    var tickWidth: CGFloat = 1.5
    /// Half the width of the widest thing drawn at a stop. Without it the
    /// outermost stop is centred on x = 0 and the screen edge cuts it in half.
    var inset: CGFloat?

    private var edgeInset: CGFloat { inset ?? tickWidth / 2 }

    func position(of value: Int, width: CGFloat) -> CGFloat {
        let span = CGFloat(max(bounds.upperBound - bounds.lowerBound, 1))
        return edgeInset + CGFloat(value - bounds.lowerBound) / span * (width - edgeInset * 2)
    }

    func value(atX x: CGFloat, width: CGFloat) -> Int {
        let span = CGFloat(max(bounds.upperBound - bounds.lowerBound, 1))
        let fraction = (x - edgeInset) / max(width - edgeInset * 2, 1)
        let raw = bounds.lowerBound + Int((fraction * span).rounded())
        return min(max(raw, bounds.lowerBound), bounds.upperBound)
    }
}

/// The ruler itself. `highlighted` ticks take the accent color; everything
/// else is quiet. Decorative — the owning control carries the accessibility.
struct TickTrack: View {
    let geometry: TickTrackGeometry
    let highlighted: ClosedRange<Int>?
    /// Every n-th tick is drawn tall. `nil` makes every tick tall — right when
    /// there are few enough stops that each one is a distinct answer.
    var majorEvery: Int? = 5
    var accentColor: Color = AppColors.accent

    static let markerHeight: CGFloat = Spacing.xl

    private var minorTickHeight: CGFloat { Spacing.xs }
    private var majorTickHeight: CGFloat { Spacing.md }

    var body: some View {
        Canvas { context, size in
            for tick in geometry.bounds {
                let x = geometry.position(of: tick, width: size.width)
                let height = isMajor(tick) ? majorTickHeight : minorTickHeight
                let rect = CGRect(
                    x: x - geometry.tickWidth / 2,
                    y: (size.height - height) / 2,
                    width: geometry.tickWidth,
                    height: height
                )
                context.fill(
                    Path(roundedRect: rect, cornerRadius: geometry.tickWidth / 2),
                    with: .color(highlighted?.contains(tick) == true ? accentColor : AppColors.gray300)
                )
            }
        }
        .frame(height: Self.markerHeight)
        .accessibilityHidden(true)
    }

    private func isMajor(_ tick: Int) -> Bool {
        guard let majorEvery else { return true }
        return tick % majorEvery == 0
            || tick == geometry.bounds.lowerBound
            || tick == geometry.bounds.upperBound
    }
}

/// Rounded vertical bar standing taller than the ticks. The visible bar stays
/// slim; the hit area around it is a full touch target.
struct TrackMarker: View {
    var accentColor: Color = AppColors.accent

    static let width: CGFloat = Spacing.xxxs

    var body: some View {
        RoundedRectangle(cornerRadius: Self.width / 2, style: .continuous)
            .fill(accentColor)
            .frame(width: Self.width, height: TickTrack.markerHeight)
            .shadow(color: .black.opacity(Opacity.standardShadow), radius: 2, y: 1)
            .frame(width: TouchTarget.minimum, height: TouchTarget.minimum)
            .contentShape(Rectangle())
    }
}

// ─────────────────────────────────────────────
// MARK: Scale Choice
// ─────────────────────────────────────────────

/// Single-select over an **ordinal** set of 3–5 word options: the selected
/// word reads large above a stepped slider, with the two ends labelled
/// underneath to anchor the direction.
///
/// Use it when the options form a gradient the user moves along — how sure,
/// how much, how often. Do NOT use it for a set of distinct facts ("stayed" /
/// "left early"): a slider implies a continuum, and inventing one where there
/// isn't any is a lie about the data. Those stay `SegmentedChoice(.cards)`.
///
/// Height is constant no matter how many options there are or how long their
/// titles run — only the selected one is spelled out. That is the whole point:
/// the same question as a stack of cards costs ~200pt.
///
/// The selection is **not** optional. A slider thumb always sits somewhere, so
/// an "unanswered" state would be a thumb pointing at a value the user never
/// chose. The owner seeds the field instead, and seeds it with the option that
/// asserts the least — see `PlannedExposureFlowViewModel.confidence`.
///
/// Usage:
/// ```swift
/// ScaleChoice(
///     options: PredictionConfidence.allCases.map { ChoiceOption(value: $0, title: $0.title) },
///     selection: $confidence
/// )
/// ```
struct ScaleChoice<Value: Hashable>: View {
    let options: [ChoiceOption<Value>]
    @Binding var selection: Value
    var accentColor: Color = AppColors.accent

    private var selectedIndex: Int {
        options.firstIndex { $0.value == selection } ?? 0
    }

    private var lastIndex: Int { max(options.count - 1, 1) }

    var body: some View {
        VStack(spacing: Spacing.xxxs) {
            Text(options.first { $0.value == selection }?.title ?? "")
                .appFont(.h3)
                .foregroundStyle(TextColors.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .contentTransition(.opacity)
                .animation(AppAnimation.fast, value: selectedIndex)
                .frame(maxWidth: .infinity)

            // The same system slider the intensity scale uses, stepped by one
            // option: nothing here needs custom drawing, and the native control
            // brings its own drag feel and VoiceOver.
            Slider(
                value: Binding(
                    get: { Double(selectedIndex) },
                    set: { newValue in selectIndex(Int(newValue.rounded())) }
                ),
                in: 0...Double(lastIndex),
                step: 1
            )
            .tint(accentColor)
            .accessibilityValue(options.first { $0.value == selection }?.title ?? "")

            if let first = options.first, let last = options.last, options.count > 1 {
                HStack {
                    Text(first.title)
                    Spacer()
                    Text(last.title)
                }
                .appFont(.small)
                .foregroundStyle(TextColors.secondary)
                .lineLimit(1)
                .accessibilityHidden(true)
            }
        }
    }

    private func selectIndex(_ index: Int) {
        guard options.indices.contains(index) else { return }
        let value = options[index].value
        guard value != selection else { return }
        selection = value
        HapticFeedback.selection()
    }
}

// ─────────────────────────────────────────────
// MARK: Scrolling Tick Ruler
// ─────────────────────────────────────────────

/// A ruler that moves under a fixed marker: the value reads large above a
/// centred marker, and the ticked tape scrolls beneath it.
///
/// Unlike `ScaleChoice` and `IntensitySlider` — where the marker moves along a
/// static track — here the marker is the still point. Reach for it only when
/// the stops are a **named ladder** the user steps along rather than a range
/// they sweep (today: breathing duration, spec §4).
///
/// Ticks are all the same height and carry no labels: with a ladder there is no
/// "every fifth" to mark, and the number above the marker is the only reading
/// that matters. Snapping is strict — every resting position is a ladder step,
/// because a value between steps would have nothing to compare against in the
/// ladder rule.
struct ScrollingTickRuler: View {
    let values: [Int]
    @Binding var selection: Int
    /// How a value reads above the marker.
    let label: (Int) -> String
    var accentColor: Color = AppColors.positive
    /// Spoken value for VoiceOver, which never sees the tape.
    var accessibilityValue: (Int) -> String

    @ScaledMetric(relativeTo: .body) private var stepWidth: CGFloat = 44
    @ScaledMetric(relativeTo: .body) private var tickHeight: CGFloat = 20

    @State private var scrolledValue: Int?

    var body: some View {
        VStack(spacing: Spacing.xs) {
            Text(label(selection))
                .appFont(.monoLarge)
                .foregroundStyle(TextColors.primary)
                .contentTransition(.numericText())
                .animation(AppAnimation.fast, value: selection)

            ZStack {
                tape
                marker
            }
            .frame(height: TickTrack.markerHeight)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityValue(accessibilityValue(selection))
        .accessibilityAdjustableAction { direction in
            guard let index = values.firstIndex(of: selection) else { return }
            // "Increment" moves right along the tape, which is the way the
            // values are ordered — not necessarily "more minutes".
            let next = direction == .increment ? index + 1 : index - 1
            guard values.indices.contains(next) else { return }
            selection = values[next]
        }
    }

    private var tape: some View {
        GeometryReader { proxy in
            // Half a viewport of margin on each side, so the first and last
            // steps can reach the centre marker.
            let sideMargin = max((proxy.size.width - stepWidth) / 2, 0)

            ScrollView(.horizontal) {
                HStack(spacing: 0) {
                    ForEach(values, id: \.self) { value in
                        RoundedRectangle(cornerRadius: TrackMarker.width / 2, style: .continuous)
                            .fill(value == selection ? accentColor : AppColors.gray300)
                            .frame(width: TrackMarker.width / 2, height: tickHeight)
                            .frame(width: stepWidth, height: TickTrack.markerHeight)
                            .id(value)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollIndicators(.hidden)
            .contentMargins(.horizontal, sideMargin, for: .scrollContent)
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $scrolledValue, anchor: .center)
            .onAppear { scrolledValue = selection }
            .onChange(of: scrolledValue) { _, newValue in
                guard let newValue, newValue != selection else { return }
                selection = newValue
                HapticFeedback.selection()
            }
            // The value can also change from outside — the ladder rule offers a
            // step and the tape has to travel there.
            .onChange(of: selection) { _, newValue in
                guard scrolledValue != newValue else { return }
                withAnimation(AppAnimation.standard) { scrolledValue = newValue }
            }
        }
        .accessibilityHidden(true)
    }

    private var marker: some View {
        RoundedRectangle(cornerRadius: TrackMarker.width / 2, style: .continuous)
            .fill(accentColor)
            .frame(width: TrackMarker.width, height: TickTrack.markerHeight)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

// MARK: - Preview

#Preview("Tick Tracks") {
    @Previewable @State var confidence: String? = nil
    @Previewable @State var anxiety = 6
    @Previewable @State var rangeMin = 3
    @Previewable @State var rangeMax = 8

    ScrollView {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                SectionLabel(text: "How sure are you")
                ScaleChoice(
                    options: [
                        ChoiceOption(value: "certain", title: "Definitely"),
                        ChoiceOption(value: "likely", title: "Probably"),
                        ChoiceOption(value: "fiftyFifty", title: "Fifty-fifty"),
                        ChoiceOption(value: "unlikely", title: "Unlikely"),
                    ],
                    selection: $confidence
                )
            }

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                SectionLabel(text: "Anxiety level")
                IntensitySlider(value: $anxiety)
            }

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                SectionLabel(text: "Time range")
                DurationRangeSlider(minMinutes: $rangeMin, maxMinutes: $rangeMax)
            }
        }
        .padding(Spacing.lg)
    }
    .background(AppColors.cardBackground)
}
