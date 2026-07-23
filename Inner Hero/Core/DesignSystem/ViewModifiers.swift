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

// Screens sit on one of three grounds. Pick by what the screen *is*; never
// invent a fourth. See USAGE.MD § "Фон экрана".
//
//  • hub          `.homeBackground()`  — grouped gray + the accent glow
//  • form         `.formBackground()`  — flat page gray, controls are
//                                        `cardBackground` plates on it
//  • single task  `AppColors.cardBackground` — one continuous surface,
//                                        for screens with no controls at all
//
// Forms used to be "one continuous surface" too. That stopped being true the
// moment controls started being identified by their *fill*: the screen is now
// a stack of discrete plates, so it needs a ground for them to sit on. A gray
// plate on white also reads as disabled on iOS — which is exactly what the
// white-page version was reported as looking like.
//
// Whatever a form uses here, its `PinnedScrim` must use the same colour, or
// the pinned header and footer paint bands across the page.

extension View {
    /// Ground of a form screen. Pairs with `cardBackground` controls.
    func formBackground() -> some View {
        background(AppColors.gray100.ignoresSafeArea())
    }
}

// ─────────────────────────────────────────────
// MARK: Pinned Form Scrims
// ─────────────────────────────────────────────

/// Backdrop for a bar pinned over a scrolling form — the title band at the
/// top, the primary-action pill at the bottom.
///
/// The band itself is **opaque**, and the fade lives entirely *outside* it.
/// A scrim that fades within its own bounds looks fine behind running text
/// and broken behind anything with an edge: a chip or a slider caught in the
/// half-transparent zone reads as clipped, not as scrolled-under.
struct PinnedScrim: ViewModifier {
    enum Edge {
        case top
        case bottom
    }

    var edge: Edge
    var fadeHeight: CGFloat = Spacing.md
    /// Must match the page behind the form, or the band shows as a stripe.
    var surface: Color = AppColors.gray100

    func body(content: Content) -> some View {
        content
            .background(surface)
            .overlay(alignment: edge == .top ? .bottom : .top) {
                LinearGradient(
                    colors: edge == .top
                        ? [surface, surface.opacity(0)]
                        : [surface.opacity(0), surface],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: fadeHeight)
                // Pushed clear of the band, so the opaque part never eats
                // into the fade and vice versa.
                .offset(y: edge == .top ? fadeHeight : -fadeHeight)
                .allowsHitTesting(false)
            }
    }
}

extension View {
    /// Opaque header band plus a fade below it.
    func pinnedHeaderBackground(
        fadeHeight: CGFloat = Spacing.md,
        surface: Color = AppColors.gray100
    ) -> some View {
        modifier(PinnedScrim(edge: .top, fadeHeight: fadeHeight, surface: surface))
    }

    /// Opaque footer band plus a fade above it.
    func pinnedFooterBackground(
        fadeHeight: CGFloat = Spacing.md,
        surface: Color = AppColors.gray100
    ) -> some View {
        modifier(PinnedScrim(edge: .bottom, fadeHeight: fadeHeight, surface: surface))
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
// MARK: Article Door Sheet
// ─────────────────────────────────────────────

extension View {
    /// Presents the article that stands at an exercise's door (spec §8) from
    /// inside a full-screen flow.
    ///
    /// A sheet rather than a push: the door screens live in a `fullScreenCover`
    /// with no navigation stack of their own, and giving them one just to reach
    /// an article would put a back-stack between the user and "Start".
    ///
    /// A `nil` article renders nothing at all — a renamed id degrades to a
    /// missing row, never to an empty sheet.
    func articleDoorSheet(_ article: Article?, isPresented: Binding<Bool>) -> some View {
        sheet(isPresented: isPresented) {
            if let article {
                NavigationStack {
                    ArticleDetailView(article: article)
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button(String(localized: "Done")) {
                                    isPresented.wrappedValue = false
                                }
                            }
                        }
                }
            }
        }
    }
}
