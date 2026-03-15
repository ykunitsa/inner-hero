import SwiftUI

// MARK: - ViewModifiers.swift
//
// All reusable ViewModifiers for the design system.
// Apply via the extension helpers at the bottom of each section.

// ─────────────────────────────────────────────
// MARK: Card Styles
// ─────────────────────────────────────────────

/// Standard white surface card with subtle shadow
struct CardStyle: ViewModifier {
    @Environment(\.colorScheme) private var scheme
    var cornerRadius: CGFloat = CornerRadius.lg
    var padding: CGFloat      = Spacing.lg

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(scheme == .dark
                          ? Color(red: 0.13, green: 0.13, blue: 0.15)
                          : Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(AppColors.gray200, lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(scheme == .dark
                                          ? Opacity.lightShadow
                                          : Opacity.standardShadow),
                    radius: 8, y: 2)
    }
}

extension View {
    func cardStyle(
        cornerRadius: CGFloat = CornerRadius.lg,
        padding: CGFloat = Spacing.lg
    ) -> some View {
        modifier(CardStyle(cornerRadius: cornerRadius, padding: padding))
    }
}

// ─────────────────────────────────────────────

/// Hero card — bold coloured surface (default: primary red)
struct HeroCardStyle: ViewModifier {
    var color: Color         = AppColors.primary
    var cornerRadius: CGFloat = CornerRadius.xl
    var padding: CGFloat      = Spacing.lg

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(color)
            )
    }
}

extension View {
    func heroCardStyle(
        color: Color = AppColors.primary,
        cornerRadius: CGFloat = CornerRadius.xl,
        padding: CGFloat = Spacing.lg
    ) -> some View {
        modifier(HeroCardStyle(color: color, cornerRadius: cornerRadius, padding: padding))
    }
}

// ─────────────────────────────────────────────

/// Accent card — light tinted border + background (for thought records, alerts)
struct AccentCardStyle: ViewModifier {
    @Environment(\.colorScheme) private var scheme
    var accentColor: Color    = AppColors.primary
    var cornerRadius: CGFloat = CornerRadius.md
    var padding: CGFloat      = Spacing.sm

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(accentColor.opacity(scheme == .dark ? 0.08 : 0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(accentColor.opacity(0.25), lineWidth: 1)
            )
    }
}

extension View {
    func accentCardStyle(
        accentColor: Color = AppColors.primary,
        cornerRadius: CGFloat = CornerRadius.md,
        padding: CGFloat = Spacing.sm
    ) -> some View {
        modifier(AccentCardStyle(
            accentColor: accentColor,
            cornerRadius: cornerRadius,
            padding: padding
        ))
    }
}

// ─────────────────────────────────────────────
// MARK: Touch Target
// ─────────────────────────────────────────────

struct TouchTargetModifier: ViewModifier {
    var width: CGFloat  = TouchTarget.minimum
    var height: CGFloat = TouchTarget.minimum

    func body(content: Content) -> some View {
        content
            .frame(minWidth: width, minHeight: height)
            .contentShape(Rectangle())
    }
}

extension View {
    func touchTarget(
        width: CGFloat = TouchTarget.minimum,
        height: CGFloat = TouchTarget.minimum
    ) -> some View {
        modifier(TouchTargetModifier(width: width, height: height))
    }
}

// ─────────────────────────────────────────────
// MARK: Progress Bar
// ─────────────────────────────────────────────

struct ProgressBarModifier: ViewModifier {
    var progress: Double        // 0.0 – 1.0
    var color: Color            = AppColors.primary
    var trackColor: Color       = AppColors.gray200
    var height: CGFloat         = 4
    var cornerRadius: CGFloat   = 2

    func body(content: Content) -> some View {
        content.overlay(alignment: .top) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(trackColor)
                        .frame(height: height)
                    Capsule()
                        .fill(color)
                        .frame(width: geo.size.width * CGFloat(max(0, min(1, progress))),
                               height: height)
                        .animation(AppAnimation.standard, value: progress)
                }
            }
            .frame(height: height)
        }
    }
}

extension View {
    func progressBar(
        progress: Double,
        color: Color = AppColors.primary,
        trackColor: Color = AppColors.gray200,
        height: CGFloat = 4
    ) -> some View {
        modifier(ProgressBarModifier(
            progress: progress,
            color: color,
            trackColor: trackColor,
            height: height
        ))
    }
}

// ─────────────────────────────────────────────
// MARK: Page Background
// ─────────────────────────────────────────────

struct PageBackgroundModifier: ViewModifier {
    @Environment(\.colorScheme) private var scheme

    func body(content: Content) -> some View {
        content
            .background(
                scheme == .dark
                ? Color(red: 0.09, green: 0.09, blue: 0.11)
                : AppColors.gray100
            )
            .ignoresSafeArea()
    }
}

extension View {
    func pageBackground() -> some View {
        modifier(PageBackgroundModifier())
    }
}

// ─────────────────────────────────────────────
// MARK: Icon Container
// ─────────────────────────────────────────────

struct IconContainerModifier: ViewModifier {
    var size: CGFloat             = IconSize.card
    var backgroundColor: Color    = AppColors.primaryLight
    var cornerRadius: CGFloat     = CornerRadius.sm

    func body(content: Content) -> some View {
        content
            .frame(width: size, height: size)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(backgroundColor)
            )
    }
}

extension View {
    func iconContainer(
        size: CGFloat = IconSize.card,
        backgroundColor: Color = AppColors.primaryLight,
        cornerRadius: CGFloat = CornerRadius.sm
    ) -> some View {
        modifier(IconContainerModifier(
            size: size,
            backgroundColor: backgroundColor,
            cornerRadius: cornerRadius
        ))
    }
}

// ─────────────────────────────────────────────
// MARK: Shimmer Skeleton (loading state)
// ─────────────────────────────────────────────

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: .clear,                          location: phase - 0.3),
                            .init(color: .white.opacity(0.5),             location: phase),
                            .init(color: .clear,                          location: phase + 0.3),
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width)
                }
            )
            .clipped()
            .onAppear {
                withAnimation(
                    .linear(duration: 1.4).repeatForever(autoreverses: false)
                ) { phase = 1.3 }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}
