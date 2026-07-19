import SwiftUI

// MARK: - Typography
//
// All text styles for the design system.
// Built on SF Pro (system default on iOS).
//
// Every style scales with Dynamic Type: `AppFontModifier` anchors the
// point size to a system text style via `@ScaledMetric`. Sizes in the
// enum are the values at the default (Large) content size.
//
// Usage:
//   Text("Hello").appFont(.h1)
//   Text("Hello").appFont(.body)

// MARK: - Font Style Enum

enum AppTextStyle: CaseIterable {
    // Display
    case display        // 34px / 700  — onboarding splash titles
    case h1             // 28px / 700  — screen titles (large nav)
    case h2             // 22px / 700  — section headers, card titles
    case h3             // 17px / 600  — card subtitles, list headers

    // Body — 17, matching the iOS system body size: the app is used
    // under stress, meaningful text must not be small.
    case body           // 17px / 400  — standard body
    case bodyMedium     // 17px / 500  — semi-prominent body

    // Supporting
    case small          // 13px / 400  — meta, tags, timestamps
    case smallMedium    // 13px / 500  — badge labels, active states
    case caption        // 11px / 500  — ALL CAPS labels, section headers
    case mono           // 15px / 700  — timer display (monospaced)
    case monoLarge      // 28px / 700  — large timer / countdown
    case statValue      // 20px / 700  — numeric stat tiles (monospaced)

    // Specialised
    case buttonPrimary  // 16px / 600  — primary CTA button label
    case buttonSmall    // 14px / 600  — secondary / compact button label
}

// MARK: - Font Resolution

extension AppTextStyle {

    /// Point size at the default (Large) Dynamic Type size.
    var size: CGFloat {
        switch self {
        case .display:       return 34
        case .h1:            return 28
        case .h2:            return 22
        case .h3:            return 17
        case .body:          return 17
        case .bodyMedium:    return 17
        case .small:         return 13
        case .smallMedium:   return 13
        case .caption:       return 11
        case .mono:          return 15
        case .monoLarge:     return 28
        case .statValue:     return 20
        case .buttonPrimary: return 16
        case .buttonSmall:   return 14
        }
    }

    var weight: Font.Weight {
        switch self {
        case .display, .h1, .h2:            return .bold
        case .h3:                           return .semibold
        case .body, .small:                 return .regular
        case .bodyMedium, .smallMedium:     return .medium
        case .caption:                      return .semibold
        case .mono, .monoLarge, .statValue: return .bold
        case .buttonPrimary, .buttonSmall:  return .semibold
        }
    }

    var design: Font.Design {
        switch self {
        case .mono, .monoLarge, .statValue: return .monospaced
        default:                            return .default
        }
    }

    /// System text style the size is anchored to for Dynamic Type scaling.
    var relativeTextStyle: Font.TextStyle {
        switch self {
        case .display:                return .largeTitle
        case .h1, .monoLarge:         return .title
        case .h2:                     return .title2
        case .h3:                     return .headline
        case .body, .bodyMedium:      return .body
        case .mono:                   return .subheadline
        case .small, .smallMedium:    return .footnote
        case .caption:                return .caption2
        case .statValue:              return .title3
        case .buttonPrimary:          return .callout
        case .buttonSmall:            return .subheadline
        }
    }

    /// Fixed-size font (does NOT scale with Dynamic Type).
    /// Prefer `.appFont(...)` in views — this exists for the rare context
    /// where a ViewModifier cannot be applied.
    var fixedFont: Font {
        .system(size: size, weight: weight, design: design)
    }

    /// Recommended line spacing for multiline text
    var lineSpacing: CGFloat {
        switch self {
        case .display, .h1:     return 2
        case .h2, .h3:          return 1.5
        case .body:             return 3
        case .small:            return 2
        default:                return 0
        }
    }

    /// Letter spacing override (kerning)
    var kerning: CGFloat {
        switch self {
        case .caption: return 0.5
        default:       return 0
        }
    }
}

// MARK: - View Modifier

struct AppFontModifier: ViewModifier {
    let style: AppTextStyle
    @ScaledMetric private var scaledSize: CGFloat

    init(style: AppTextStyle) {
        self.style = style
        _scaledSize = ScaledMetric(wrappedValue: style.size, relativeTo: style.relativeTextStyle)
    }

    func body(content: Content) -> some View {
        content
            .font(.system(size: scaledSize, weight: style.weight, design: style.design))
            .lineSpacing(style.lineSpacing)
            .kerning(style.kerning)
    }
}

extension View {
    /// Apply a design-system text style (scales with Dynamic Type).
    /// Example: `Text("Inner Hero").appFont(.h1)`
    func appFont(_ style: AppTextStyle) -> some View {
        modifier(AppFontModifier(style: style))
    }
}

// MARK: - Preset Text Components
// Ready-made text views for common patterns.

/// Screen title — maps to NavigationTitle equivalent in custom layouts
struct AppTitle: View {
    let text: String
    var color: Color = TextColors.primary

    var body: some View {
        Text(text)
            .appFont(.h1)
            .foregroundStyle(color)
    }
}

/// Card title (bold, adaptive)
struct CardTitle: View {
    let text: String
    var color: Color = TextColors.primary

    var body: some View {
        Text(text)
            .appFont(.h2)
            .foregroundStyle(color)
    }
}

/// Meta label — "5 min · Relaxation"
struct MetaLabel: View {
    let text: String
    var color: Color = TextColors.secondary

    var body: some View {
        Text(text)
            .appFont(.small)
            .foregroundStyle(color)
    }
}

/// ALL CAPS section header — "YOUR PREDICTION"
struct SectionLabel: View {
    let text: String
    var color: Color = TextColors.tertiary

    var body: some View {
        Text(text.uppercased())
            .appFont(.caption)
            .foregroundStyle(color)
    }
}

// MARK: - Preview

#Preview("Typography") {
    ScrollView {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("display 34 · splash").appFont(.display)
            Text("h1 28 · screen title").appFont(.h1)
            Text("h2 22 · card title").appFont(.h2)
            Text("h3 17 · list header").appFont(.h3)
            Text("body 17 · standard copy").appFont(.body)
            Text("bodyMedium 17 · semi-prominent").appFont(.bodyMedium)
            Text("small 13 · meta / timestamps").appFont(.small).foregroundStyle(TextColors.secondary)
            Text("smallMedium 13 · badge label").appFont(.smallMedium)
            SectionLabel(text: "caption 11 · section label")
            Text("02:41").appFont(.mono)
            Text("12:05").appFont(.monoLarge)
            Text("6 / 7").appFont(.statValue)
            Text("buttonPrimary 16").appFont(.buttonPrimary)
            Text("buttonSmall 14").appFont(.buttonSmall)
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .background(AppColors.gray100)
}
