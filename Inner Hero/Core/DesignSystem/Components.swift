import SwiftUI

// MARK: - Components.swift
//
// Reusable SwiftUI components matching the CBT Tools redesign.
// All components respect light/dark mode and Dynamic Type.

// ─────────────────────────────────────────────
// MARK: Buttons
// ─────────────────────────────────────────────

/// Reusable label for primary-style CTA. Use as content of `PrimaryButton` or as `NavigationLink` label so the link receives the tap.
/// Usage: `PrimaryButtonLabel(title: "Start session", systemImage: "play.fill", color: .positive)` inside NavigationLink.
struct PrimaryButtonLabel: View {
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
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .frame(height: 52)
        .background(Capsule().fill(color))
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
                        .tint(.white)
                } else {
                    PrimaryButtonLabel(title: title, systemImage: systemImage, color: color)
                }
            }
        }
        .disabled(isLoading)
        .buttonStyle(.plain)
    }
}

/// Compact icon-only circular button
/// Usage: `CircleButton(systemImage: "xmark", background: .red) { ... }`
struct CircleButton: View {
    let systemImage: String
    var size: CGFloat           = TouchTarget.minimum
    var iconSize: CGFloat       = 17
    var background: Color       = AppColors.black
    var foreground: Color       = .white
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: iconSize, weight: .semibold))
                .foregroundStyle(foreground)
                .frame(width: size, height: size)
                .background(Circle().fill(background))
        }
        .buttonStyle(.plain)
    }
}

/// Arrow forward button (used in exercise list rows)
struct ArrowButton: View {
    var size: CGFloat = IconSize.action
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: size, height: size)
                .background(Circle().fill(AppColors.black))
        }
        .buttonStyle(.plain)
    }
}

// ─────────────────────────────────────────────
// MARK: Progress Bar
// ─────────────────────────────────────────────

/// Standalone inline progress bar (step N of M)
/// Usage: `StepProgressBar(current: 2, total: 5, color: .red)`
struct StepProgressBar: View {
    let current: Int
    let total: Int
    var color: Color = AppColors.primary
    var height: CGFloat = 4

    private var progress: Double {
        guard total > 0 else { return 0 }
        return Double(current) / Double(total)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(AppColors.gray200)
                    .frame(height: height)
                Capsule()
                    .fill(color)
                    .frame(width: geo.size.width * progress, height: height)
                    .animation(AppAnimation.standard, value: progress)
            }
        }
        .frame(height: height)
    }
}

// ─────────────────────────────────────────────
// MARK: Hero Feature Card
// ─────────────────────────────────────────────

/// Large coloured hero card (Daily check-in / main exercise prompt)
/// Usage: `HeroFeatureCard(subtitle: "Afternoon Check-in", title: "Identify your cognitive distortions")`
struct HeroFeatureCard: View {
    let subtitle: String
    let title: String
    var color: Color     = AppColors.primary
    var icon: String     = "sun.max"
    var onDismiss: (() -> Void)? = nil
    var onFavourite: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 26, weight: .medium))
                .foregroundStyle(color)
                .frame(width: IconSize.hero, height: IconSize.hero)
                .background(Circle().fill(.white))
                .padding(.bottom, Spacing.lg)

            // Subtitle
            Text(subtitle)
                .appFont(.small)
                .foregroundStyle(TextColors.onColorSecondary)
                .padding(.bottom, Spacing.xxs)

            // Title
            Text(title)
                .appFont(.h2)
                .foregroundStyle(TextColors.onColor)
                .fixedSize(horizontal: false, vertical: true)

            // Actions
            if onDismiss != nil || onFavourite != nil {
                HStack {
                    Spacer()
                    if let dismiss = onDismiss {
                        CircleButton(
                            systemImage: "xmark",
                            size: 44,
                            iconSize: 15,
                            background: AppColors.primary.opacity(0.35),
                            foreground: .white,
                            action: dismiss
                        )
                    }
                    if let fav = onFavourite {
                        CircleButton(
                            systemImage: "heart",
                            size: 44,
                            iconSize: 15,
                            background: AppColors.primary.opacity(0.35),
                            foreground: .white,
                            action: fav
                        )
                    }
                }
                .padding(.top, Spacing.md)
            }
        }
        .padding(Spacing.lg)
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

/// White card row for exercise lists
/// Usage: `ExerciseRow(title: "Thought Record", meta: "5 min · Reframing", icon: "doc.text")`
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

                ArrowButton(action: action)
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous)
                    .fill(.white)
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
                    .fill(isSelected ? accentColor.opacity(0.03) : .white)
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
// MARK: Emotion Picker Cell
// ─────────────────────────────────────────────

/// Emoji grid cell for mood selection
/// Usage: `EmotionCell(emoji: "😌", label: "Calm", isSelected: $selected)`
struct EmotionCell: View {
    let emoji: String
    let label: String
    @Binding var isSelected: Bool
    var accentColor: Color = AppColors.accent

    var body: some View {
        Button { isSelected.toggle() } label: {
            VStack(spacing: Spacing.xxs) {
                Text(emoji)
                    .font(.system(size: 28))
                Text(label)
                    .appFont(.smallMedium)
                    .foregroundStyle(TextColors.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                    .fill(isSelected ? accentColor.opacity(0.08) : .white)
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
        case error, success, neutral, accent

        var background: Color {
            switch self {
            case .error:   return AppColors.primaryLight
            case .success: return AppColors.positiveLight
            case .neutral: return AppColors.gray100
            case .accent:  return AppColors.accentLight
            }
        }

        var foreground: Color {
            switch self {
            case .error:   return AppColors.primary
            case .success: return AppColors.positive
            case .neutral: return AppColors.gray600
            case .accent:  return AppColors.accent
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
// MARK: Top Tab Navigation Bar
// ─────────────────────────────────────────────

/// Segmented top navigation with active underline
/// Segmented pill tab bar
/// Usage: `TopTabBar(tabs: ["Today", "All schedules"], selection: $tab)`
struct TopTabBar: View {
    let tabs: [String]
    @Binding var selection: Int
    @Namespace private var namespace

    var body: some View {
        HStack(spacing: Spacing.xxxs) {
            ForEach(tabs.indices, id: \.self) { i in
                Button {
                    withAnimation(AppAnimation.standard) { selection = i }
                    HapticFeedback.selection()
                } label: {
                    Text(tabs[i])
                        .appFont(selection == i ? .bodyMedium : .body)
                        .foregroundStyle(selection == i ? TextColors.primary : TextColors.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.xxs)
                        .background {
                            if selection == i {
                                Capsule()
                                    .fill(Color(.systemBackground))
                                    .shadow(
                                        color: Color.black.opacity(Opacity.lightShadow),
                                        radius: 4, x: 0, y: 2
                                    )
                                    .matchedGeometryEffect(id: "tab_indicator", in: namespace)
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selection == i ? .isSelected : [])
            }
        }
        .padding(Spacing.xxxs)
        .background(
            Capsule().fill(AppColors.gray100)
        )
    }
}

// ─────────────────────────────────────────────
// MARK: Thought Record Card
// ─────────────────────────────────────────────

/// Quoted thought display with red left border
/// Usage: `RecordedThoughtCard(text: "I made one mistake...")`
struct RecordedThoughtCard: View {
    let text: String
    var accentColor: Color = AppColors.primary

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            SectionLabel(text: "Your Recorded Thought")
            Text(text)
                .appFont(.bodyMedium)
                .foregroundStyle(TextColors.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                .strokeBorder(AppColors.gray200, lineWidth: 0.5)
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
// MARK: Flat Pill Nav Bar (Main Tab navigation)
// ─────────────────────────────────────────────

/// Floating pill nav bar where ALL items are uniform — no prominent center button.
/// Use this for main app tab navigation (replaces UITabBar).
///
/// Usage:
/// ```swift
/// FlatPillNavBar(
///     items: [
///         .init(systemImage: "heart.gauge.open", tag: 0, accessibilityLabel: "Home"),
///         .init(systemImage: "figure.mind.and.body", tag: 1, accessibilityLabel: "Exercises"),
///         .init(systemImage: "calendar", tag: 2, accessibilityLabel: "Schedule"),
///         .init(systemImage: "book.pages", tag: 3, accessibilityLabel: "Knowledge"),
///         .init(systemImage: "gear", tag: 4, accessibilityLabel: "Settings"),
///     ],
///     selection: $selectedTab
/// )
/// ```
struct FlatPillNavBar: View {

    struct NavItem {
        let systemImage: String
        let activeSystemImage: String  // filled/bold variant for active state
        let tag: Int
        var accessibilityLabel: String = ""

        /// Convenience init — uses same icon for both states
        init(systemImage: String,
             activeSystemImage: String? = nil,
             tag: Int,
             accessibilityLabel: String = "") {
            self.systemImage       = systemImage
            self.activeSystemImage = activeSystemImage ?? systemImage
            self.tag               = tag
            self.accessibilityLabel = accessibilityLabel
        }
    }

    let items: [NavItem]
    @Binding var selection: Int
    /// Called when the already-selected tab is tapped (use for pop-to-root etc.)
    var onReselect: ((Int) -> Void)? = nil

    @Namespace private var pillNS

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items, id: \.tag) { item in
                flatNavButton(item)
            }
        }
        .padding(.horizontal, Spacing.xxs)
        .padding(.vertical, Spacing.xxs)
        .background(Capsule().fill(Color.black))
        .shadow(color: .black.opacity(0.25), radius: 20, y: 8)
        .environment(\.colorScheme, .dark)
    }

    @ViewBuilder
    private func flatNavButton(_ item: NavItem) -> some View {
        let isSelected = selection == item.tag

        Button {
            if isSelected {
                onReselect?(item.tag)
            } else {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                withAnimation(AppAnimation.spring) {
                    selection = item.tag
                }
            }
        } label: {
            ZStack {
                // Sliding pill background via matchedGeometryEffect
                if isSelected {
                    Capsule()
                        .fill(Color.white.opacity(0.15))
                        .matchedGeometryEffect(id: "pill", in: pillNS)
                }

                Image(systemName: isSelected ? item.activeSystemImage : item.systemImage)
                    .font(.system(size: 18, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? Color.white : Color.white.opacity(0.4))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.accessibilityLabel)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

// ─────────────────────────────────────────────
// MARK: Bottom Pill Navigation Bar (with center button)
// ─────────────────────────────────────────────

/// Pill-shaped floating bottom navigation bar.
/// Matches the black pill from the mockups with icon tabs,
/// a prominent center stop/record button, and an optional trailing CTA.
///
/// Usage:
/// ```swift
/// BottomPillNavBar(
///     items: [
///         .init(systemImage: "face.smiling",  tag: 0),
///         .init(systemImage: "play.circle",   tag: 1),
///         .init(systemImage: "plus.square",   tag: 2),
///         .init(systemImage: "person",        tag: 4),
///     ],
///     centerItem: .init(systemImage: "stop.fill", tag: 3),
///     selection: $selectedTab,
///     onTrailingTap: { /* next / continue */ }
/// )
/// ```
struct BottomPillNavBar: View {

    struct NavItem {
        let systemImage: String
        let tag: Int
        var accessibilityLabel: String = ""
    }

    /// Regular icon tabs (excluding center)
    let items: [NavItem]
    /// The prominent center button (stop/record/active action)
    let centerItem: NavItem
    /// Currently selected tab tag
    @Binding var selection: Int
    /// Optional trailing arrow CTA (pass nil to hide)
    var onTrailingTap: (() -> Void)? = nil

    // Center button is "active" when its tag is selected
    private var centerIsActive: Bool { selection == centerItem.tag }

    var body: some View {
        HStack(spacing: 0) {
            // ── Left icon items ────────────────────────
            HStack(spacing: 4) {
                ForEach(items.prefix(items.count / 2), id: \.tag) { item in
                    pillIconButton(item)
                }
            }

            // ── Center button ──────────────────────────
            Button {
                selection = centerItem.tag
            } label: {
                Image(systemName: centerItem.systemImage)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(centerIsActive ? .white : Color.white.opacity(0.5))
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(centerIsActive
                                  ? Color.white.opacity(0.25)
                                  : Color.white.opacity(0.12))
                    )
            }
            .buttonStyle(.plain)
            .touchTarget()
            .accessibilityLabel(centerItem.accessibilityLabel.isEmpty
                                ? centerItem.systemImage
                                : centerItem.accessibilityLabel)
            .padding(.horizontal, 4)

            // ── Right icon items ───────────────────────
            HStack(spacing: 4) {
                ForEach(items.suffix(items.count - items.count / 2), id: \.tag) { item in
                    pillIconButton(item)
                }
            }

            // ── Trailing CTA arrow (optional) ──────────
            if let onTrailing = onTrailingTap {
                Spacer().frame(width: Spacing.xxs)
                Button(action: onTrailing) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(Color.white.opacity(0.18)))
                }
                .buttonStyle(.plain)
                .touchTarget()
                .accessibilityLabel("Next")
            }
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xxs)
        .background(
            Capsule()
                .fill(Color.black)
        )
        .shadow(color: .black.opacity(0.22), radius: 16, y: 6)
        .environment(\.colorScheme, .dark)
    }

    @ViewBuilder
    private func pillIconButton(_ item: NavItem) -> some View {
        let isSelected = selection == item.tag
        Button {
            withAnimation(AppAnimation.fast) { selection = item.tag }
        } label: {
            Image(systemName: item.systemImage)
                .font(.system(size: 17, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? .white : Color.white.opacity(0.45))
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(isSelected
                              ? Color.white.opacity(0.15)
                              : .clear)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.accessibilityLabel.isEmpty ? item.systemImage : item.accessibilityLabel)
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

/// Top navigation bar for exercise flows. Three variants:
///
/// `.progress` — back chevron + progress bar + "2/5" counter
/// `.titled`   — X close button + centered title + optional gear icon
/// `.stepped`  — back chevron + "Step 3 of 5" label (right-aligned)
///
/// Usage:
/// ```swift
/// // Variant 1 — distortion / mood flows
/// ExerciseStepHeader(
///     variant: .progress(current: 2, total: 5, color: AppColors.primary),
///     onBack: { dismiss() }
/// )
///
/// // Variant 2 — Guided Breathing style
/// ExerciseStepHeader(
///     variant: .titled("Guided Breathing", category: "RELAXATION"),
///     onBack: { dismiss() },
///     onSettings: { showSettings = true }
/// )
///
/// // Variant 3 — Thought Record style
/// ExerciseStepHeader(
///     variant: .stepped(current: 3, total: 5),
///     onBack: { dismiss() }
/// )
/// ```
struct ExerciseStepHeader: View {

    enum Variant {
        /// Back + coloured progress bar + "N/M"
        case progress(current: Int, total: Int, color: Color = AppColors.primary)
        /// X close + centred title + optional category label + gear
        case titled(String, category: String? = nil)
        /// Back + "Step N of M" pill (right)
        case stepped(current: Int, total: Int)
    }

    let variant: Variant
    /// Back / close action
    var onBack: (() -> Void)? = nil
    /// Gear / settings action (only shown in `.titled`)
    var onSettings: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: Spacing.xxs) {
            // ── Leading button ─────────────────────────
            leadingButton

            // ── Center content ─────────────────────────
            centerContent

            // ── Trailing ───────────────────────────────
            trailingContent
        }
        .padding(.horizontal, Spacing.sm)
        .frame(height: 44)
    }

    // MARK: Sub-views

    @ViewBuilder
    private var leadingButton: some View {
        switch variant {
        case .titled:
            Button {
                onBack?()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(TextColors.primary)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(AppColors.gray100))
            }
            .buttonStyle(.plain)

        default:
            Button {
                onBack?()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(TextColors.primary)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(AppColors.gray100))
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var centerContent: some View {
        switch variant {
        case .progress(let current, let total, let color):
            // Progress bar + counter
            HStack(spacing: Spacing.xxs) {
                StepProgressBar(current: current, total: total, color: color)
                Text("\(current)/\(total)")
                    .appFont(.small)
                    .foregroundStyle(TextColors.secondary)
                    .monospacedDigit()
                    .fixedSize()
            }

        case .titled(let title, let category):
            VStack(spacing: 2) {
                if let cat = category {
                    Text(cat.uppercased())
                        .appFont(.caption)
                        .foregroundStyle(AppColors.positive)
                }
                Text(title)
                    .appFont(.h3)
                    .foregroundStyle(TextColors.primary)
            }
            .frame(maxWidth: .infinity)

        case .stepped(let current, let total):
            Spacer()
            Text("Step \(current) of \(total)")
                .appFont(.small)
                .foregroundStyle(TextColors.secondary)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, 5)
                .background(
                    Capsule().fill(AppColors.gray100)
                )
        }
    }

    @ViewBuilder
    private var trailingContent: some View {
        switch variant {
        case .titled:
            if let settings = onSettings {
                Button(action: settings) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(TextColors.primary)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(AppColors.gray100))
                }
                .buttonStyle(.plain)
            } else {
                // Keep layout balanced
                Color.clear.frame(width: 32, height: 32)
            }

        default:
            // Keep layout balanced with leading button
            Color.clear.frame(width: 32, height: 32)
        }
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

    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Placeholder
            if text.isEmpty {
                Text(placeholder)
                    .appFont(.body)
                    .foregroundStyle(AppColors.gray300)
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
                .fill(AppColors.gray100)
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
// MARK: Thought Record Section Card
// ─────────────────────────────────────────────

/// Single section card inside a Thought Record exercise step.
/// Combines: ALL CAPS label, content text or placeholder,
/// optional distortion badge, optional hint line.
///
/// Usage:
/// ```swift
/// // Filled section
/// ThoughtRecordSection(
///     label: "Automatic Thought",
///     content: "I'm going to fail this presentation...",
///     badge: "Fortune Telling"
/// )
///
/// // Empty / input section
/// ThoughtRecordSection(
///     label: "Evidence Against",
///     placeholder: "What facts contradict this thought?",
///     hint: "Think of times you've succeeded before."
/// )
///
/// // Active / highlighted section (underline accent)
/// ThoughtRecordSection(
///     label: "Alternative Thought",
///     isActive: true
/// )
/// ```
struct ThoughtRecordSection: View {
    let label: String
    var content: String?          = nil
    var placeholder: String?      = nil
    var hint: String?             = nil
    var badge: String?            = nil
    /// Highlights the section with a coloured bottom border (active input step)
    var isActive: Bool            = false
    var accentColor: Color        = AppColors.primary

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            // Label
            SectionLabel(text: label)

            // Content or placeholder
            if let text = content {
                Text(text)
                    .appFont(.body)
                    .foregroundStyle(TextColors.primary)
                    .fixedSize(horizontal: false, vertical: true)
            } else if let ph = placeholder {
                Text(ph)
                    .appFont(.body)
                    .foregroundStyle(AppColors.gray300)
            }

            // Distortion badge
            if let badgeText = badge {
                AppBadge(
                    text: badgeText,
                    style: .error,
                    systemImage: "exclamationmark.triangle"
                )
            }

            // Hint
            if let hintText = hint {
                HStack(spacing: 5) {
                    Image(systemName: "clock")
                        .font(.system(size: 11))
                        .foregroundStyle(AppColors.gray300)
                    Text(hintText)
                        .appFont(.small)
                        .foregroundStyle(AppColors.gray300)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                .fill(AppColors.gray100)
        )
        .overlay(alignment: .bottom) {
            if isActive {
                Rectangle()
                    .fill(accentColor)
                    .frame(height: 2)
                    .clipShape(
                        RoundedRectangle(cornerRadius: 1, style: .continuous)
                    )
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous))
    }
}

// MARK: - BottomPillNavBar Preview
#Preview("Bottom Pill Nav") {
    @Previewable @State var tab = 0

    VStack {
        Spacer()
        BottomPillNavBar(
            items: [
                .init(systemImage: "face.smiling",  tag: 0, accessibilityLabel: "Mood"),
                .init(systemImage: "play.circle",   tag: 1, accessibilityLabel: "Play"),
                .init(systemImage: "plus.square",   tag: 2, accessibilityLabel: "Add"),
                .init(systemImage: "person",        tag: 4, accessibilityLabel: "Profile"),
            ],
            centerItem: .init(systemImage: "stop.fill", tag: 3, accessibilityLabel: "Stop"),
            selection: $tab,
            onTrailingTap: {}
        )
        .padding(.horizontal, Spacing.lg)
        .padding(.bottom, Spacing.lg)
    }
    .background(AppColors.gray100)
}
