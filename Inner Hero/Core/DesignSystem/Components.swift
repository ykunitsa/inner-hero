import SwiftUI

// MARK: - Components.swift
//
// Reusable SwiftUI components of the Inner Hero design system.
// All components respect light/dark mode and Dynamic Type.

// ─────────────────────────────────────────────
// MARK: Buttons
// ─────────────────────────────────────────────

/// Reusable label for primary-style CTA. Use as content of `PrimaryButton` or as `NavigationLink` label so the link receives the tap.
/// Reacts to `.disabled(...)` on the enclosing control: gray surface + muted
/// text instead of an opacity fade (gray-on-gray washout).
/// Usage: `PrimaryButtonLabel(title: "Start session", systemImage: "play.fill", color: .positive)` inside NavigationLink.
struct PrimaryButtonLabel: View {
    @Environment(\.isEnabled) private var isEnabled

    let title: String
    var systemImage: String? = nil
    var color: Color = AppColors.black

    var body: some View {
        Group {
            if let systemImage {
                HStack(spacing: Spacing.xxs) {
                    Image(systemName: systemImage)
                        .font(.system(size: IconSize.glyph, weight: .semibold))
                    Text(title)
                        .appFont(.buttonPrimary)
                }
            } else {
                Text(title)
                    .appFont(.buttonPrimary)
            }
        }
        .foregroundStyle(isEnabled ? TextColors.onBlack : AppColors.gray400)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 52)
        .background(Capsule().fill(isEnabled ? color : AppColors.gray200))
        .animation(AppAnimation.fast, value: isEnabled)
    }
}

/// Full-width primary CTA button
/// Usage: `PrimaryButton(title: "Continue") { ... }` or `PrimaryButton(title: "Start", systemImage: "play.fill") { ... }`
/// For use inside NavigationLink, use `PrimaryButtonLabel` as the link's label so the tap triggers navigation.
struct PrimaryButton: View {
    let title: String
    var systemImage: String? = nil
    var color: Color = AppColors.black
    var isLoading: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView()
                        .tint(TextColors.onBlack)
                } else {
                    PrimaryButtonLabel(title: title, systemImage: systemImage, color: color)
                }
            }
        }
        .disabled(isLoading)
        .buttonStyle(.plain)
    }
}

/// Compact icon-only circular button.
/// Default — round glass, matching iOS 26 system toolbar buttons (back, etc.).
/// Variants via `background`: `AppColors.gray100` for a sheet-style close
/// circle, `AppColors.black` + `foreground: TextColors.onBlack` for the
/// prominent dark variant.
/// Usage: `CircleButton(systemImage: "gearshape") { ... }`
struct CircleButton: View {
    let systemImage: String
    var size: CGFloat           = TouchTarget.minimum
    var iconSize: CGFloat       = 17
    /// `nil` → system glass circle; a color → flat filled circle.
    var background: Color?      = nil
    var foreground: Color       = TextColors.primary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            if let background {
                icon.background(Circle().fill(background))
            } else {
                icon.glassEffect(in: .circle)
            }
        }
        .buttonStyle(.plain)
    }

    private var icon: some View {
        Image(systemName: systemImage)
            .font(.system(size: iconSize, weight: .semibold))
            .foregroundStyle(foreground)
            .frame(width: size, height: size)
    }
}

/// Play / pause circle control for dark chrome (e.g. `SessionFlowBottomPill`, breathing session bar).
struct SessionPlayPauseCircleButton: View {
    var isPlaying: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(isPlaying ? .white : Color.white.opacity(0.5))
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(isPlaying
                            ? Color.white.opacity(0.25)
                            : Color.white.opacity(0.12))
                )
        }
        .buttonStyle(.plain)
        .touchTarget()
        .padding(.horizontal, Spacing.xxxs)
        .accessibilityLabel(isPlaying ? String(localized: "Pause") : String(localized: "Resume"))
    }
}

// ─────────────────────────────────────────────
// MARK: Hero Feature Card
// ─────────────────────────────────────────────

/// Coloured hero action card — the single accent card of a screen
/// (e.g. "Log an exposure" on Today). Reads as a prominent action row:
/// icon circle, title with subtitle, arrow affordance.
/// Always available, no dismiss/favourite chrome (spec §2.1).
/// Usage: `HeroFeatureCard(subtitle: "While it's fresh", title: "Log an exposure")`
struct HeroFeatureCard: View {
    let subtitle: String
    let title: String
    var color: Color     = AppColors.primary
    var icon: String     = "pencil"

    var body: some View {
        HStack(spacing: Spacing.sm) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 26, weight: .medium))
                .foregroundStyle(color)
                .frame(width: IconSize.hero, height: IconSize.hero)
                .background(Circle().fill(.white))

            // Labels
            VStack(alignment: .leading, spacing: Spacing.xxxs) {
                Text(title)
                    .appFont(.h2)
                    .foregroundStyle(TextColors.onColor)
                    .fixedSize(horizontal: false, vertical: true)
                Text(subtitle)
                    .appFont(.small)
                    .foregroundStyle(TextColors.onColorSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: Spacing.xs)

            // Decorative affordance — the whole card is the button
            Image(systemName: "arrow.right")
                .font(.system(size: IconSize.glyph, weight: .semibold))
                .foregroundStyle(TextColors.onColor)
                .frame(width: IconSize.action, height: IconSize.action)
                .background(Circle().fill(.white.opacity(Opacity.prominentBackground)))
                .accessibilityHidden(true)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.xl, style: .continuous)
                .fill(color)
        )
    }
}

// ─────────────────────────────────────────────
// MARK: Exercise List Row
// ─────────────────────────────────────────────

/// Card row for exercise lists (launcher, history feed)
/// Usage: `ExerciseRow(title: "Breathing", meta: "Box · 10 min", icon: "wind")`
struct ExerciseRow: View {
    let title: String
    let meta: String
    var icon: String         = "doc.text"
    var iconColor: Color     = AppColors.primary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xs) {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: IconSize.glyph, weight: .medium))
                    .foregroundStyle(iconColor)
                    .iconContainer(
                        size: IconSize.card,
                        backgroundColor: iconColor.opacity(0.1),
                        cornerRadius: CornerRadius.sm
                    )

                // Labels
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .appFont(.bodyMedium)
                        .foregroundStyle(TextColors.primary)
                    Text(meta)
                        .appFont(.small)
                        .foregroundStyle(TextColors.secondary)
                }

                Spacer()

                // Decorative affordance — the whole row is the button
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(TextColors.onBlack)
                    .frame(width: IconSize.action, height: IconSize.action)
                    .background(Circle().fill(AppColors.black))
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous)
                    .fill(AppColors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous)
                    .strokeBorder(AppColors.gray200, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }
}

// ─────────────────────────────────────────────
// MARK: Radio Selection Card
// ─────────────────────────────────────────────

/// Selectable card with radio dot — for cognitive distortion picker etc.
/// Usage: `RadioCard(title: "Catastrophizing", description: "...", isSelected: $selected)`
struct RadioCard: View {
    let title: String
    let description: String
    @Binding var isSelected: Bool
    var accentColor: Color = AppColors.primary

    var body: some View {
        Button {
            isSelected.toggle()
        } label: {
            HStack(alignment: .top, spacing: Spacing.xs) {
                // Radio dot
                ZStack {
                    Circle()
                        .strokeBorder(
                            isSelected ? accentColor : AppColors.gray300,
                            lineWidth: isSelected ? 2 : 1.5
                        )
                        .frame(width: 20, height: 20)
                    if isSelected {
                        Circle()
                            .fill(accentColor)
                            .frame(width: 10, height: 10)
                    }
                }
                .padding(.top, 2)

                // Content
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .appFont(.bodyMedium)
                        .foregroundStyle(TextColors.primary)
                    Text(description)
                        .appFont(.small)
                        .foregroundStyle(TextColors.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                    .fill(isSelected ? accentColor.opacity(0.03) : AppColors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                    .strokeBorder(
                        isSelected ? accentColor : AppColors.gray200,
                        lineWidth: isSelected ? 1.5 : 0.5
                    )
            )
        }
        .buttonStyle(.plain)
        .animation(AppAnimation.fast, value: isSelected)
    }
}

// ─────────────────────────────────────────────
// MARK: Badge / Tag
// ─────────────────────────────────────────────

/// Pill badge for distortion labels, categories, status
/// Usage: `AppBadge(text: "Fortune Telling", style: .error)`
struct AppBadge: View {
    enum BadgeStyle {
        case error, success, neutral, accent, warning

        var background: Color {
            switch self {
            case .error:   return AppColors.State.error.opacity(Opacity.subtleBorder)
            case .success: return AppColors.positiveLight
            case .neutral: return AppColors.gray100
            case .accent:  return AppColors.accentLight
            case .warning: return AppColors.State.warning.opacity(Opacity.subtleBorder)
            }
        }

        var foreground: Color {
            switch self {
            case .error:   return AppColors.State.error
            case .success: return AppColors.positive
            case .neutral: return AppColors.gray600
            case .accent:  return AppColors.accent
            case .warning: return AppColors.State.warning
            }
        }
    }

    let text: String
    var style: BadgeStyle = .neutral
    var systemImage: String? = nil

    var body: some View {
        HStack(spacing: 4) {
            if let icon = systemImage {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
            }
            Text(text)
                .appFont(.smallMedium)
        }
        .foregroundStyle(style.foreground)
        .padding(.horizontal, Spacing.xxs + 2)
        .padding(.vertical, 4)
        .background(
            Capsule().fill(style.background)
        )
    }
}

// ─────────────────────────────────────────────
// MARK: Quote Card
// ─────────────────────────────────────────────

/// Quoted text display with a coloured left border.
/// Used to show the user's own earlier words back to them:
/// prediction reminder on the exposure "after" screen (spec §3),
/// forecast comparison in BA (spec §6).
/// Usage: `QuoteCard(label: "Your prediction", text: "It will overwhelm me...")`
struct QuoteCard: View {
    let label: String
    let text: String
    var accentColor: Color = AppColors.primary

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            SectionLabel(text: label)
            Text(text)
                .appFont(.bodyMedium)
                .foregroundStyle(TextColors.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            // A white card, not a gray field: this is the user's own words
            // shown back, not an input. The soft shadow keeps it readable
            // as a plate even on an all-white form screen.
            RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                .fill(AppColors.cardBackground)
        )
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(accentColor)
                .frame(width: 3)
                .clipShape(
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                )
                .padding(.vertical, 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous))
        .shadow(color: .black.opacity(Opacity.standardShadow), radius: 8, y: 2)
    }
}

// ─────────────────────────────────────────────
// MARK: Breathing Circle
// ─────────────────────────────────────────────

/// Animated breathing circle (Guided Breathing screen)
/// Usage: `BreathingCircle(phase: viewModel.breathPhase, color: .green)`
struct BreathingCircle: View {
    enum BreathPhase { case inhale, hold, exhale }
    let phase: BreathPhase
    var color: Color = AppColors.positive
    var duration: TimeInterval = 3

    private var scale: CGFloat {
        switch phase {
        case .inhale: return 1.15
        case .hold:   return 1.15
        case .exhale: return 0.88
        }
    }

    var body: some View {
        ZStack {
            // Halo
            Circle()
                .fill(color.opacity(0.12))
                .scaleEffect(scale + 0.12)
            // Main circle
            Circle()
                .fill(color)
                .scaleEffect(scale)
        }
        .frame(width: 160, height: 160)
        .animation(.easeInOut(duration: duration), value: phase)
    }
}

// ─────────────────────────────────────────────
// MARK: Session Flow Bottom Pill (Grounding-style)
// ─────────────────────────────────────────────

/// Black capsule bar with three equal columns: back | center (timer / label) | primary action.
/// Used by multi-step exercise flows (e.g. grounding, behavioral activation).
struct SessionFlowBottomPill<L: View, C: View, R: View>: View {
    @ViewBuilder let left: () -> L
    @ViewBuilder let center: () -> C
    @ViewBuilder let right: () -> R

    init(
        @ViewBuilder left: @escaping () -> L,
        @ViewBuilder center: @escaping () -> C,
        @ViewBuilder right: @escaping () -> R
    ) {
        self.left = left
        self.center = center
        self.right = right
    }

    var body: some View {
        HStack(spacing: 0) {
            left()
                .frame(maxWidth: .infinity)
                .frame(minHeight: TouchTarget.minimum)
            center()
                .frame(maxWidth: .infinity)
                .frame(minHeight: TouchTarget.minimum)
            right()
                .frame(maxWidth: .infinity)
                .frame(minHeight: TouchTarget.minimum)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xxs)
        .background(Capsule().fill(Color.black))
        .shadow(color: .black.opacity(0.22), radius: 16, y: 6)
        .environment(\.colorScheme, .dark)
    }
}

// ─────────────────────────────────────────────
// MARK: Section Header
// ─────────────────────────────────────────────

/// Bold section title with optional "See All" trailing action.
/// Matches "Current Mood  See All" / "Exercises" patterns on main screen.
///
/// Usage:
/// ```swift
/// SectionHeader(title: "Exercises", onSeeAll: { })
/// SectionHeader(title: "Current Mood")  // без кнопки
/// ```
struct SectionHeader: View {
    let title: String
    var onSeeAll: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .appFont(.h2)
                .foregroundStyle(TextColors.primary)

            Spacer()

            if let action = onSeeAll {
                Button(action: action) {
                    Text("See All")
                        .appFont(.small)
                        .foregroundStyle(TextColors.secondary)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// ─────────────────────────────────────────────
// MARK: Exercise Step Header
// ─────────────────────────────────────────────

/// Top bar for full-screen exercise flows:
/// X close + centred title + optional category label + optional gear.
/// (Step/progress variants removed — every 2.0 form is a single screen.)
///
/// Usage:
/// ```swift
/// ExerciseStepHeader(
///     title: "Guided Breathing",
///     category: "RELAXATION",
///     onBack: { dismiss() },
///     onSettings: { showSettings = true }
/// )
/// ```
struct ExerciseStepHeader: View {
    let title: String
    var category: String? = nil
    /// Close action
    var onBack: (() -> Void)? = nil
    /// Gear / settings action
    var onSettings: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: Spacing.xxs) {
            // ── Close ──────────────────────────────────
            Button {
                onBack?()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(TextColors.primary)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(AppColors.gray100))
                    .touchTarget()
            }
            .buttonStyle(.plain)

            // ── Title ──────────────────────────────────
            VStack(spacing: 2) {
                if let category {
                    Text(category.uppercased())
                        .appFont(.caption)
                        .foregroundStyle(AppColors.positive)
                }
                Text(title)
                    .appFont(.h3)
                    .foregroundStyle(TextColors.primary)
            }
            .frame(maxWidth: .infinity)

            // ── Settings / balance spacer ──────────────
            if let settings = onSettings {
                Button(action: settings) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(TextColors.primary)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(AppColors.gray100))
                        .touchTarget()
                }
                .buttonStyle(.plain)
            } else {
                Color.clear.frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, Spacing.sm)
        .frame(minHeight: 44)
    }
}

// ─────────────────────────────────────────────
// MARK: App Text Editor
// ─────────────────────────────────────────────

/// Styled multiline text input matching the "Describe the situation..." fields.
///
/// Usage:
/// ```swift
/// AppTextEditor(
///     text: $notes,
///     placeholder: "Describe the situation or thought...",
///     minHeight: 100
/// )
/// ```
struct AppTextEditor: View {
    @Binding var text: String
    var placeholder: String = ""
    var minHeight: CGFloat = 100
    /// Surface behind the field (default matches page gray; use `cardBackground` on tinted screens).
    var fillColor: Color = AppColors.gray100

    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Placeholder — gray400: gray300 is below readable contrast,
            // and the exposure form is filled in under stress
            if text.isEmpty {
                Text(placeholder)
                    .appFont(.body)
                    .foregroundStyle(AppColors.gray400)
                    .padding(.horizontal, 4)
                    .padding(.top, 8)
                    .allowsHitTesting(false)
            }

            TextEditor(text: $text)
                .appFont(.body)
                .foregroundStyle(TextColors.primary)
                .focused($isFocused)
                .frame(minHeight: minHeight)
                .scrollContentBackground(.hidden)
        }
        .padding(Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                .fill(fillColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                .strokeBorder(
                    isFocused ? AppColors.gray300 : .clear,
                    lineWidth: 1
                )
        )
        .animation(AppAnimation.fast, value: isFocused)
        .onTapGesture { isFocused = true }
    }
}

// ─────────────────────────────────────────────
// MARK: Intensity Slider (0–10)
// ─────────────────────────────────────────────

/// Discrete 0–10 slider for anxiety intensity and BA ratings:
/// the current value above a standard system `Slider`.
///
/// Deliberately NEUTRAL in color: the scale measures intensity only
/// (spec §3) — no green→red "good/bad" encoding, no words on the scale.
///
/// Usage:
/// ```swift
/// IntensitySlider(value: $anxiety)                 // 0...10
/// IntensitySlider(value: $mastery, range: 0...10)
/// ```
/// Give the field a name for VoiceOver at the call site:
/// `.accessibilityLabel(String(localized: "Anxiety level"))`
struct IntensitySlider: View {
    @Binding var value: Int
    var range: ClosedRange<Int> = 0...10
    var accentColor: Color = AppColors.accent

    var body: some View {
        VStack(spacing: Spacing.xxxs) {
            Text("\(value)")
                .appFont(.statValue)
                .monospacedDigit()
                .foregroundStyle(TextColors.primary)
                .contentTransition(.numericText())
                .animation(AppAnimation.fast, value: value)
                .accessibilityHidden(true) // the slider itself carries the value

            Slider(
                value: Binding(
                    get: { Double(value) },
                    set: { newValue in
                        let stepped = Int(newValue.rounded())
                        if stepped != value {
                            value = stepped
                            HapticFeedback.selection()
                        }
                    }
                ),
                in: Double(range.lowerBound)...Double(range.upperBound),
                step: 1
            )
            .tint(accentColor)
            .accessibilityValue("\(value)")
        }
    }
}

// ─────────────────────────────────────────────
// MARK: Duration Range Slider
// ─────────────────────────────────────────────

/// Tick-mark ruler with two draggable markers for a min–max duration in
/// minutes (spec §3: the planned exposure time range; the exact end is
/// picked randomly inside it). The selected range reads large above the
/// ruler; ticks inside the range are accented; markers never cross — a
/// real range is what makes the random end unpredictable.
///
/// Usage:
/// ```swift
/// DurationRangeSlider(minMinutes: $rangeMin, maxMinutes: $rangeMax)  // 1...20
/// ```
struct DurationRangeSlider: View {
    @Binding var minMinutes: Int
    @Binding var maxMinutes: Int
    var bounds: ClosedRange<Int> = 1...20
    var accentColor: Color = AppColors.accent

    private let minorTickHeight: CGFloat = Spacing.xs
    private let majorTickHeight: CGFloat = Spacing.md
    private let markerHeight: CGFloat = Spacing.xl
    private let markerWidth: CGFloat = Spacing.xxxs
    private let tickWidth: CGFloat = 1.5

    var body: some View {
        VStack(spacing: Spacing.xxs) {
            Text(String(localized: "\(minMinutes)–\(maxMinutes) min"))
                .appFont(.statValue)
                .monospacedDigit()
                .foregroundStyle(TextColors.primary)
                .contentTransition(.numericText())
                .animation(AppAnimation.fast, value: minMinutes)
                .animation(AppAnimation.fast, value: maxMinutes)
                .accessibilityHidden(true) // each marker reads its own value

            GeometryReader { geo in
                let width = max(geo.size.width, 1)
                let minX = position(of: minMinutes, width: width)
                let maxX = position(of: maxMinutes, width: width)

                ZStack(alignment: .leading) {
                    ruler(width: width)

                    marker
                        .offset(x: minX - TouchTarget.minimum / 2)
                        .highPriorityGesture(
                            DragGesture(minimumDistance: 0, coordinateSpace: .named("durationRange"))
                                .onChanged { gesture in
                                    let proposed = value(atX: gesture.location.x, width: width)
                                    update(&minMinutes, to: min(max(proposed, bounds.lowerBound), maxMinutes - 1))
                                }
                        )
                        .accessibilityLabel(String(localized: "Minimum"))
                        .accessibilityValue(String(localized: "\(minMinutes) min"))
                        .accessibilityAdjustableAction { direction in
                            switch direction {
                            case .increment: update(&minMinutes, to: min(minMinutes + 1, maxMinutes - 1))
                            case .decrement: update(&minMinutes, to: max(minMinutes - 1, bounds.lowerBound))
                            @unknown default: break
                            }
                        }

                    marker
                        .offset(x: maxX - TouchTarget.minimum / 2)
                        .highPriorityGesture(
                            DragGesture(minimumDistance: 0, coordinateSpace: .named("durationRange"))
                                .onChanged { gesture in
                                    let proposed = value(atX: gesture.location.x, width: width)
                                    update(&maxMinutes, to: max(min(proposed, bounds.upperBound), minMinutes + 1))
                                }
                        )
                        .accessibilityLabel(String(localized: "Maximum"))
                        .accessibilityValue(String(localized: "\(maxMinutes) min"))
                        .accessibilityAdjustableAction { direction in
                            switch direction {
                            case .increment: update(&maxMinutes, to: min(maxMinutes + 1, bounds.upperBound))
                            case .decrement: update(&maxMinutes, to: max(maxMinutes - 1, minMinutes + 1))
                            @unknown default: break
                            }
                        }
                }
                .coordinateSpace(name: "durationRange")
                .frame(maxHeight: .infinity, alignment: .center)
            }
            .frame(height: TouchTarget.minimum)
        }
    }

    /// Vertical tick per minute; every 5th is taller. Ticks inside the
    /// selected range pick up the accent color.
    private func ruler(width: CGFloat) -> some View {
        Canvas { context, size in
            for tick in bounds.lowerBound...bounds.upperBound {
                let x = position(of: tick, width: width)
                let isMajor = tick % 5 == 0 || tick == bounds.lowerBound || tick == bounds.upperBound
                let height = isMajor ? majorTickHeight : minorTickHeight
                let rect = CGRect(
                    x: x - tickWidth / 2,
                    y: (size.height - height) / 2,
                    width: tickWidth,
                    height: height
                )
                let isInRange = (minMinutes...maxMinutes).contains(tick)
                context.fill(
                    Path(roundedRect: rect, cornerRadius: tickWidth / 2),
                    with: .color(isInRange ? accentColor : AppColors.gray300)
                )
            }
        }
        .frame(height: markerHeight)
        .accessibilityHidden(true)
    }

    /// Rounded vertical bar, taller than the ticks; hit area is padded to
    /// TouchTarget.minimum.
    private var marker: some View {
        RoundedRectangle(cornerRadius: markerWidth / 2, style: .continuous)
            .fill(accentColor)
            .frame(width: markerWidth, height: markerHeight)
            .shadow(color: .black.opacity(Opacity.standardShadow), radius: 2, y: 1)
            .frame(width: TouchTarget.minimum, height: TouchTarget.minimum)
            .contentShape(Rectangle())
    }

    /// Ruler coordinates: ticks span the full width edge to edge.
    private func position(of value: Int, width: CGFloat) -> CGFloat {
        let span = CGFloat(max(bounds.upperBound - bounds.lowerBound, 1))
        let inset = tickWidth / 2
        return inset + CGFloat(value - bounds.lowerBound) / span * (width - tickWidth)
    }

    private func value(atX x: CGFloat, width: CGFloat) -> Int {
        let span = CGFloat(bounds.upperBound - bounds.lowerBound)
        let fraction = (x - tickWidth / 2) / max(width - tickWidth, 1)
        return bounds.lowerBound + Int((fraction * span).rounded())
    }

    private func update(_ binding: inout Int, to newValue: Int) {
        guard newValue != binding else { return }
        binding = newValue
        HapticFeedback.selection()
    }
}

// ─────────────────────────────────────────────
// MARK: Chips
// ─────────────────────────────────────────────

/// Tappable suggestion chip — tap inserts its text into a field
/// (spec §3: prompts from past sessions; NOT saved entities).
/// Deliberately small and NOT capsule-shaped: an insert-arrow glyph on a
/// quiet rounded rect, so it never reads as a `SelectableChip` toggle.
/// Usage: `SuggestionChip(text: "Metro ride") { situation = "Metro ride" }`
struct SuggestionChip: View {
    let text: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xxxs) {
                Image(systemName: "arrow.up.left")
                    .appFont(.smallMedium)
                    .foregroundStyle(TextColors.secondary)
                    .accessibilityHidden(true)
                Text(text)
                    .appFont(.small)
                    .foregroundStyle(TextColors.primary)
                    .lineLimit(1)
            }
            .padding(.horizontal, Spacing.xxs)
            .padding(.vertical, Spacing.xxxs + 2)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.sm, style: .continuous)
                    .fill(AppColors.gray100)
            )
            .touchTarget(width: 0)
        }
        .buttonStyle(.plain)
    }
}

/// Single-line, horizontally scrolling row of suggestion chips. Edges fade
/// out when there is more content in that direction — the fade is the
/// scroll affordance.
/// Usage: `SuggestionChipsRow(suggestions: chips) { field = $0 }`
struct SuggestionChipsRow: View {
    let suggestions: [String]
    let onSelect: (String) -> Void

    @State private var edges = EdgeOverflow()

    private struct EdgeOverflow: Equatable {
        var leading = false
        var trailing = false
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.xxs) {
                ForEach(suggestions, id: \.self) { suggestion in
                    SuggestionChip(text: suggestion) { onSelect(suggestion) }
                }
            }
        }
        .onScrollGeometryChange(for: EdgeOverflow.self) { geometry in
            EdgeOverflow(
                leading: geometry.contentOffset.x > 1,
                trailing: geometry.contentOffset.x + geometry.containerSize.width
                    < geometry.contentSize.width - 1
            )
        } action: { _, overflow in
            withAnimation(AppAnimation.fast) { edges = overflow }
        }
        .mask(fadeMask)
    }

    private var fadeMask: some View {
        HStack(spacing: 0) {
            LinearGradient(
                colors: [edges.leading ? .clear : .black, .black],
                startPoint: .leading, endPoint: .trailing
            )
            .frame(width: Spacing.md)
            Rectangle().fill(.black)
            LinearGradient(
                colors: [.black, edges.trailing ? .clear : .black],
                startPoint: .leading, endPoint: .trailing
            )
            .frame(width: Spacing.md)
        }
    }
}

/// Selectable chip for multi-select sets (e.g. safety behaviors, spec §3).
/// Usage: `SelectableChip(text: "Breathing", isSelected: $selected)`
struct SelectableChip: View {
    let text: String
    @Binding var isSelected: Bool
    var accentColor: Color = AppColors.accent

    var body: some View {
        Button {
            isSelected.toggle()
            HapticFeedback.selection()
        } label: {
            Text(text)
                .appFont(isSelected ? .bodyMedium : .body)
                .foregroundStyle(isSelected ? accentColor : TextColors.primary)
                .lineLimit(1)
                .padding(.horizontal, Spacing.xs)
                .padding(.vertical, Spacing.xxs)
                .background(
                    Capsule().fill(isSelected
                                   ? accentColor.opacity(Opacity.softBackground)
                                   : AppColors.cardBackground)
                )
                .overlay(
                    Capsule().strokeBorder(
                        isSelected ? accentColor.opacity(Opacity.emphasizedBorder) : AppColors.gray200,
                        lineWidth: isSelected ? BorderWidth.standard : BorderWidth.hairline
                    )
                )
                .touchTarget(width: 0)
        }
        .buttonStyle(.plain)
        .animation(AppAnimation.fast, value: isSelected)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// Wrapping flow layout for chip groups.
/// Usage: `ChipFlowLayout { ForEach(chips) { SelectableChip(...) } }`
struct ChipFlowLayout: Layout {
    var spacing: CGFloat = Spacing.xxs

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > maxWidth {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: proposal.width ?? x, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

// ─────────────────────────────────────────────
// MARK: Segmented Choice
// ─────────────────────────────────────────────

/// One option of a `SegmentedChoice`.
struct ChoiceOption<Value: Hashable>: Identifiable {
    let value: Value
    let title: String
    var id: Value { value }
}

/// Single-select group of 2–4 full-word options, one tap each
/// (codex §2: segments instead of typing numbers).
///
/// `.vertical` (default) — stacked rows with a radio dot; fits long labels
/// ("wanted to leave, but stayed").
/// `.horizontal` — equal-width segments without a dot; for short options
/// ("yes" / "no").
///
/// Usage:
/// ```swift
/// SegmentedChoice(
///     options: [
///         ChoiceOption(value: Outcome.stayed, title: String(localized: "Stayed until the end")),
///         ChoiceOption(value: Outcome.stayedHard, title: String(localized: "Wanted to leave, but stayed")),
///         ChoiceOption(value: Outcome.left, title: String(localized: "Left early")),
///     ],
///     selection: $outcome
/// )
/// ```
struct SegmentedChoice<Value: Hashable>: View {
    let options: [ChoiceOption<Value>]
    @Binding var selection: Value?
    var axis: Axis = .vertical
    var accentColor: Color = AppColors.accent

    var body: some View {
        switch axis {
        case .vertical:
            VStack(spacing: Spacing.xxs) {
                ForEach(options) { option in
                    optionCard(option, showDot: true)
                }
            }
        case .horizontal:
            HStack(spacing: Spacing.xxs) {
                ForEach(options) { option in
                    optionCard(option, showDot: false)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    @ViewBuilder
    private func optionCard(_ option: ChoiceOption<Value>, showDot: Bool) -> some View {
        let isSelected = selection == option.value

        Button {
            selection = option.value
            HapticFeedback.selection()
        } label: {
            HStack(spacing: Spacing.xs) {
                if showDot {
                    ZStack {
                        Circle()
                            .strokeBorder(
                                isSelected ? accentColor : AppColors.gray300,
                                lineWidth: isSelected ? 2 : 1.5
                            )
                            .frame(width: 20, height: 20)
                        if isSelected {
                            Circle()
                                .fill(accentColor)
                                .frame(width: 10, height: 10)
                        }
                    }
                }
                Text(option.title)
                    .appFont(isSelected ? .bodyMedium : .body)
                    .foregroundStyle(TextColors.primary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: showDot ? .infinity : nil, alignment: showDot ? .leading : .center)
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .frame(maxWidth: .infinity, minHeight: TouchTarget.minimum)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                    .fill(isSelected ? accentColor.opacity(0.03) : AppColors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                    .strokeBorder(
                        isSelected ? accentColor : AppColors.gray200,
                        lineWidth: isSelected ? 1.5 : 0.5
                    )
            )
        }
        .buttonStyle(.plain)
        .animation(AppAnimation.fast, value: isSelected)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// ─────────────────────────────────────────────
// MARK: Input Control Previews
// ─────────────────────────────────────────────

#Preview("Input Controls") {
    @Previewable @State var anxiety = 6
    @Previewable @State var chipOn = true
    @Previewable @State var chipOff = false
    @Previewable @State var outcome: String? = "stayed"
    @Previewable @State var answer: String? = nil

    ScrollView {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            SectionLabel(text: "Anxiety")
            IntensitySlider(value: $anxiety)

            SectionLabel(text: "Suggestions")
            ChipFlowLayout {
                SuggestionChip(text: "Metro ride") {}
                SuggestionChip(text: "Call to the bank") {}
                SuggestionChip(text: "Crowded store") {}
            }

            SectionLabel(text: "Safety behaviors")
            ChipFlowLayout {
                SelectableChip(text: "Nothing", isSelected: $chipOff)
                SelectableChip(text: "Breathing", isSelected: $chipOn)
                SelectableChip(text: "Phone", isSelected: $chipOff)
                SelectableChip(text: "Distraction", isSelected: $chipOff)
            }

            SectionLabel(text: "What did you do")
            SegmentedChoice(
                options: [
                    ChoiceOption(value: "stayed", title: "Stayed until the end"),
                    ChoiceOption(value: "stayedHard", title: "Wanted to leave, but stayed"),
                    ChoiceOption(value: "left", title: "Left early"),
                ],
                selection: $outcome
            )

            SectionLabel(text: "Managed to relax?")
            SegmentedChoice(
                options: [
                    ChoiceOption(value: "yes", title: "Yes"),
                    ChoiceOption(value: "no", title: "No"),
                ],
                selection: $answer,
                axis: .horizontal
            )
        }
        .padding(Spacing.lg)
    }
    .background(AppColors.gray100)
}

#Preview("Buttons & Badges") {
    ScrollView {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            SectionLabel(text: "Primary buttons")
            PrimaryButton(title: "Start") {}
            PrimaryButton(title: "Save", systemImage: "checkmark", color: AppColors.primary) {}
            PrimaryButton(title: "Saving", isLoading: true) {}

            SectionLabel(text: "Circle buttons")
            HStack(spacing: Spacing.sm) {
                CircleButton(systemImage: "gearshape") {} // default — round glass (iOS 26 toolbar style)
                CircleButton(systemImage: "xmark",
                             background: AppColors.gray100) {} // sheet-style close
                CircleButton(systemImage: "arrow.up",
                             background: AppColors.black,
                             foreground: TextColors.onBlack) {} // prominent
            }

            SectionLabel(text: "Badges")
            ChipFlowLayout {
                AppBadge(text: "Situational", style: .neutral)
                AppBadge(text: "Completed", style: .success)
                AppBadge(text: "Error", style: .error, systemImage: "exclamationmark.triangle")
                AppBadge(text: "Accent", style: .accent)
                AppBadge(text: "Warning", style: .warning)
            }
        }
        .padding(Spacing.lg)
    }
    .background(AppColors.gray100)
}

#Preview("Cards & Rows") {
    @Previewable @State var radioOn = true
    @Previewable @State var radioOff = false
    @Previewable @State var notes = ""

    ScrollView {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HeroFeatureCard(
                subtitle: "While it's fresh",
                title: "Log an exposure",
                color: AppColors.primary,
                icon: "square.and.pencil"
            )

            SectionHeader(title: "Exercises", onSeeAll: {})
            ExerciseRow(title: "Breathing", meta: "Box · 10 min", icon: "wind", iconColor: AppColors.positive) {}
            ExerciseRow(title: "Relaxation (PMR)", meta: "7 groups · today", icon: "figure.mind.and.body") {}

            SectionLabel(text: "Radio cards")
            RadioCard(
                title: "7 groups",
                description: "Whole arm ×2, face, neck, torso, whole leg ×2 · ~15 min",
                isSelected: $radioOn
            )
            RadioCard(
                title: "4 groups",
                description: "Arms, face + neck, torso, legs · ~10 min",
                isSelected: $radioOff
            )

            SectionLabel(text: "Quote card")
            QuoteCard(label: "Your prediction", text: "It will overwhelm me so much I'll leave in two minutes.")

            SectionLabel(text: "Text editor")
            AppTextEditor(text: $notes, placeholder: "Describe the situation...", fillColor: AppColors.cardBackground)

            SectionLabel(text: "Card style modifier")
            Text("Any content").appFont(.body).frame(maxWidth: .infinity).cardStyle()
        }
        .padding(Spacing.lg)
    }
    .background(AppColors.gray100)
}

#Preview("Headers & Session Chrome") {
    @Previewable @State var isPlaying = true

    VStack(spacing: Spacing.xl) {
        ExerciseStepHeader(title: "Guided Breathing", category: "Relaxation", onBack: {}, onSettings: {})
        ExerciseStepHeader(title: "Situational log", onBack: {})

        HStack(spacing: Spacing.xl) {
            BreathingCircle(phase: .exhale)
                .frame(width: 120, height: 120)
        }
        .frame(maxWidth: .infinity)

        SessionFlowBottomPill(
            left: {
                CircleButton(systemImage: "chevron.left",
                             background: .white.opacity(0.12)) {}
            },
            center: {
                Text("02:41").appFont(.mono).foregroundStyle(.white)
            },
            right: {
                SessionPlayPauseCircleButton(isPlaying: isPlaying) { isPlaying.toggle() }
            }
        )
        .padding(.horizontal, Spacing.lg)
    }
    .padding(.vertical, Spacing.xl)
    .background(AppColors.gray100)
}

