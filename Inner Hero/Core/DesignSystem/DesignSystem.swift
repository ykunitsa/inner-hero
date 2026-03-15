import SwiftUI

// MARK: - Brand Colors
//
// Primary palette extracted from CBT Tools redesign mockups.
// Use semantic aliases (AppColors.*) in views — never raw hex values.

enum AppColors {

    // MARK: Primary — Coral Red
    /// Main CTA, hero cards, primary actions
    static let primary      = Color("PrimaryRed")
    static let primaryDark  = Color("PrimaryRedDark")
    static let primaryLight = Color("PrimaryRedLight")
    /// Overlay buttons on red surfaces (dismiss / like icons)
    static let primaryOverlay = AppColors.primary.opacity(0.35)

    // MARK: Accent — Purple (mood / emotional flow)
    static let accent       = Color("Accent")
    static let accentLight  = Color("AccentLight")

    // MARK: Positive — Green (breathing, success, progress)
    static let positive     = Color("Positive")
    static let positiveLight = Color("PositiveLight")

    // MARK: Neutrals
    static let black         = Color("AppBlack")
    static let gray100       = Color("Gray100") // page background
    static let gray200       = Color("Gray200") // dividers / card borders
    static let gray300       = Color("Gray300") // disabled borders
    static let gray400       = Color("Gray400") // secondary text
    static let gray600       = Color("Gray600") // tertiary text
    static let white         = Color.white

    // MARK: Semantic State Colors
    enum State {
        static let success = AppColors.positive
        static let warning = Color("StateWarning")
        static let error   = AppColors.primary
        static let info    = Color("StateInfo")
        static let neutral = AppColors.gray400
    }

    // MARK: Anxiety Scale (for exposure sessions — kept from original)
    static func anxietyColor(for level: Int) -> Color {
        switch level {
        case 0...3: return positive
        case 4...6: return State.warning
        case 7...10: return primary
        default: return gray400
        }
    }
}

// MARK: - Text Colors

enum TextColors {
    /// Main body text — adapts to light/dark automatically
    static let primary: Color   = .primary
    static let secondary: Color = .secondary
    static let tertiary: Color  = .secondary.opacity(0.65)
    static let toolbar: Color   = .primary
    /// White text for use on colored surfaces (red/purple cards)
    static let onColor: Color   = .white
    static let onColorSecondary = Color.white.opacity(0.8)
}

// MARK: - Spacing
//
// 4-point grid. Use names, not raw numbers.

enum Spacing {
    static let xxxs: CGFloat = 4
    static let xxs:  CGFloat = 8
    static let xs:   CGFloat = 12
    static let sm:   CGFloat = 16
    static let md:   CGFloat = 20
    static let lg:   CGFloat = 24
    static let xl:   CGFloat = 32
    static let xxl:  CGFloat = 40
    static let xxxl: CGFloat = 48
}

// MARK: - Corner Radius

enum CornerRadius {
    static let sm:   CGFloat = 8
    static let md:   CGFloat = 14
    static let lg:   CGFloat = 22
    static let xl:   CGFloat = 28
    static let pill: CGFloat = 999
}

// MARK: - Touch Targets
// iOS HIG minimum is 44×44 pt. Never go below this.

enum TouchTarget {
    static let minimum:  CGFloat = 44
    static let standard: CGFloat = 44
    static let large:    CGFloat = 56
}

// MARK: - Icon Sizes

enum IconSize {
    /// Hero icon on feature cards
    static let hero:    CGFloat = 56
    /// List row icon containers
    static let card:    CGFloat = 44
    /// Action / toolbar buttons
    static let action:  CGFloat = 36
    /// In-line / nav glyphs
    static let inline:  CGFloat = 24
    /// SF Symbol font size for inline use
    static let glyph:   CGFloat = 17
}

// MARK: - Opacity Scale

enum Opacity {
    static let subtleBackground:    Double = 0.05
    static let softBackground:      Double = 0.08
    static let mediumBackground:    Double = 0.15
    static let prominentBackground: Double = 0.20
    static let subtleBorder:        Double = 0.12
    static let standardBorder:      Double = 0.20
    static let emphasizedBorder:    Double = 0.35
    static let lightShadow:         Double = 0.04
    static let standardShadow:      Double = 0.08
    static let darkShadow:          Double = 0.20
}

// MARK: - Animation

enum AppAnimation {
    static let standard  = Animation.easeOut(duration: 0.22)
    static let spring    = Animation.spring(response: 0.38, dampingFraction: 0.72)
    static let fast      = Animation.easeOut(duration: 0.14)
    static let slow      = Animation.easeInOut(duration: 0.40)
    static let appear    = Animation.easeOut(duration: 0.28)
}
