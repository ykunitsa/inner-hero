import SwiftUI

// MARK: - ViewModifiers.swift
//
// All reusable ViewModifiers for the design system.
// Apply via the extension helpers at the bottom of each section.

// ─────────────────────────────────────────────
// MARK: Card Styles
// ─────────────────────────────────────────────

/// Standard surface card with subtle shadow (adapts to light/dark via CardBackground asset)
struct CardStyle: ViewModifier {
    @Environment(\.colorScheme) private var scheme
    var cornerRadius: CGFloat = CornerRadius.lg
    var padding: CGFloat      = Spacing.lg

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(AppColors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(AppColors.gray200, lineWidth: BorderWidth.hairline)
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

// NOTE: there is deliberately no `pageBackground()` here. A screen is either
// a hub (`.homeBackground()` — grouped gray, so cards float on it) or a piece
// of work (`AppColors.cardBackground` — one continuous surface). A third,
// in-between page gray only produced drift. See USAGE.MD § "Фон экрана".

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

