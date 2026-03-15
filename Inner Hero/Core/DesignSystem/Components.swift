import SwiftUI

// MARK: - Components.swift
//
// Reusable SwiftUI components matching the CBT Tools redesign.
// All components respect light/dark mode and Dynamic Type.

// ─────────────────────────────────────────────
// MARK: Buttons
// ─────────────────────────────────────────────

/// Full-width primary CTA button
/// Usage: `PrimaryButton(title: "Continue") { ... }`
struct PrimaryButton: View {
    let title: String
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
                    Text(title)
                        .appFont(.buttonPrimary)
                        .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                Capsule().fill(color)
            )
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
/// Usage: `TopTabBar(tabs: ["Daily", "Journal", "Discover"], selection: $tab)`
struct TopTabBar: View {
    let tabs: [String]
    @Binding var selection: Int

    var body: some View {
        HStack(spacing: Spacing.lg) {
            ForEach(tabs.indices, id: \.self) { i in
                Button {
                    withAnimation(AppAnimation.standard) { selection = i }
                } label: {
                    VStack(spacing: 4) {
                        Text(tabs[i])
                            .appFont(selection == i ? .navItemActive : .navItem)
                            .foregroundStyle(
                                selection == i ? TextColors.primary : TextColors.secondary
                            )
                        // Underline indicator
                        Rectangle()
                            .fill(selection == i ? AppColors.black : .clear)
                            .frame(height: 2)
                            .clipShape(Capsule())
                    }
                }
                .buttonStyle(.plain)
                .touchTarget()
            }
        }
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
                .animation(
                    AppAnimation.slow.repeatForever(autoreverses: true),
                    value: scale
                )
            // Main circle
            Circle()
                .fill(color)
                .scaleEffect(scale)
                .animation(
                    AppAnimation.slow.repeatForever(autoreverses: true),
                    value: scale
                )
        }
        .frame(width: 160, height: 160)
    }
}
