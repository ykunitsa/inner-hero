import SwiftUI

// MARK: - Typography
//
// All text styles for the CBT Tools redesign.
// Built on SF Pro Display / SF Pro Text (system default on iOS).
//
// Usage:
//   Text("Hello").appFont(.h1)
//   Text("Hello").appFont(.body)

// MARK: - Font Style Enum

enum AppTextStyle {
    // Display
    case display        // 34px / 700  — onboarding splash titles
    case h1             // 28px / 700  — screen titles (large nav)
    case h2             // 22px / 700  — section headers, card titles
    case h3             // 17px / 600  — card subtitles, list headers

    // Body
    case bodyLarge      // 17px / 400  — prominent body copy
    case body           // 15px / 400  — standard body
    case bodyMedium     // 15px / 500  — semi-prominent body

    // Supporting
    case small          // 13px / 400  — meta, tags, timestamps
    case smallMedium    // 13px / 500  — badge labels, active states
    case caption        // 11px / 500  — ALL CAPS labels, section headers
    case mono           // 15px / 700  — timer display (monospaced)
    case monoLarge      // 28px / 700  — large timer / countdown

    // Specialised
    case buttonPrimary  // 16px / 600  — primary CTA button label
    case buttonSmall    // 14px / 600  — secondary / compact button label
    case navItem        // 16px / 400  — top tab bar inactive
    case navItemActive  // 16px / 600  — top tab bar active
}

// MARK: - Font Resolution

extension AppTextStyle {
    var font: Font {
        switch self {
        case .display:       return .system(size: 34, weight: .bold,    design: .default)
        case .h1:            return .system(size: 28, weight: .bold,    design: .default)
        case .h2:            return .system(size: 22, weight: .bold,    design: .default)
        case .h3:            return .system(size: 17, weight: .semibold, design: .default)
        case .bodyLarge:     return .system(size: 17, weight: .regular, design: .default)
        case .body:          return .system(size: 15, weight: .regular, design: .default)
        case .bodyMedium:    return .system(size: 15, weight: .medium,  design: .default)
        case .small:         return .system(size: 13, weight: .regular, design: .default)
        case .smallMedium:   return .system(size: 13, weight: .medium,  design: .default)
        case .caption:       return .system(size: 11, weight: .semibold, design: .default)
        case .mono:          return .system(size: 15, weight: .bold,    design: .monospaced)
        case .monoLarge:     return .system(size: 28, weight: .bold,    design: .monospaced)
        case .buttonPrimary: return .system(size: 16, weight: .semibold, design: .default)
        case .buttonSmall:   return .system(size: 14, weight: .semibold, design: .default)
        case .navItem:       return .system(size: 16, weight: .regular, design: .default)
        case .navItemActive: return .system(size: 16, weight: .semibold, design: .default)
        }
    }

    /// Recommended line spacing for multiline text
    var lineSpacing: CGFloat {
        switch self {
        case .display, .h1:     return 2
        case .h2, .h3:          return 1.5
        case .bodyLarge, .body: return 3
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

    func body(content: Content) -> some View {
        content
            .font(style.font)
            .lineSpacing(style.lineSpacing)
            .kerning(style.kerning)
    }
}

extension View {
    /// Apply a design-system text style.
    /// Example: `Text("CBT Tools").appFont(.h1)`
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

/// Meta label — "5 min · Reframing"
struct MetaLabel: View {
    let text: String
    var color: Color = TextColors.secondary

    var body: some View {
        Text(text)
            .appFont(.small)
            .foregroundStyle(color)
    }
}

/// ALL CAPS section header — "YOUR RECORDED THOUGHT"
struct SectionLabel: View {
    let text: String
    var color: Color = TextColors.tertiary

    var body: some View {
        Text(text.uppercased())
            .appFont(.caption)
            .foregroundStyle(color)
    }
}
