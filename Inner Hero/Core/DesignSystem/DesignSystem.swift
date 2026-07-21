import SwiftUI

// MARK: - Brand Colors
//
// Inner Hero brand palette (assets in Resources/Assets.xcassets/Colors).
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
    //
    // ⚠️ Pick by the role in the comment, not by the number — and mind the
    // contrast note: only gray600 clears 4.5:1 for text. gray400 sits at
    // ~2.9:1 on white, which is placeholder-only territory.
    static let black         = Color("AppBlack")
    static let cardBackground = Color("CardBackground") // card / elevated surface (#FFF light, #2C2C2E dark)
    static let gray100       = Color("Gray100") // page background
    static let gray200       = Color("Gray200") // dividers / decorative card edges (NOT control outlines — see controlBorder)
    static let gray300       = Color("Gray300") // disabled borders (too light for text)
    static let gray400       = Color("Gray400") // placeholders only — fails text contrast
    static let gray600       = Color("Gray600") // quiet text that still has to be read
    static let white         = Color.white

    /// The surface of a running exercise session (breathing, spec §4).
    ///
    /// **Deliberately dark in both themes — it has no light variant.** Fifteen
    /// minutes of light-gray screen goes into a fully dilated pupil in the
    /// evening, and an adaptive token would fail exactly the argument it exists
    /// for. Watch Breathe, Tide and Calm all land in the same place.
    ///
    /// Because the surface does not adapt, the *content* on it must be told
    /// where it is: pair this with `.environment(\.colorScheme, .dark)` on the
    /// subtree, so `TextColors.primary`, `cardBackground` and the grays resolve
    /// to their dark values in light mode too. The colorset pins the surface,
    /// the environment pins everything drawn on it — see USAGE.MD.
    static let sessionSurface = Color("SessionSurface")

    /// The ring of an unselected **state indicator** — today that means the
    /// radio dot, and nothing else.
    ///
    /// Controls are told apart by their *fill*, not by an outline: a 3:1
    /// stroke around every chip and option turned the exposure forms into a
    /// wireframe. The dot is the exception because it is small, it is the
    /// thing that actually encodes selected/unselected, and at `gray300`
    /// (~1.5:1) it was invisible. 3.24:1 light / 4.27:1 dark, at
    /// `BorderWidth.standard`.
    ///
    /// Do **not** reach for this to outline a chip, card or field.
    static let controlBorder = Color("ControlBorder")

    // MARK: Semantic State Colors
    enum State {
        static let success = AppColors.positive
        static let warning = Color("StateWarning")
        /// Distinct from `primary` (brand): errors must not look like CTAs.
        static let error   = Color("StateError")
        static let info    = Color("StateInfo")
        static let neutral = AppColors.gray400
    }

    // NOTE: There is deliberately NO color scale for anxiety levels.
    // The 0–10 scale measures intensity only (spec §3) — colouring it
    // green→red would encode a "high anxiety = bad" judgment that
    // contradicts the inhibitory-learning model (success = stayed,
    // not lower anxiety). Intensity controls use a single neutral color.
}

// MARK: - Text Colors

enum TextColors {
    /// Main body text — adapts to light/dark automatically
    static let primary: Color   = .primary
    static let secondary: Color = .secondary
    /// Quietest text tier. NOT `.secondary` dimmed further: `.secondary` is
    /// already 60% black in light mode, and another 0.65 lands near 2.7:1 —
    /// below the 4.5:1 small text needs (codex §6). `gray600` is the token
    /// designed for this role and holds contrast in both themes.
    static let tertiary: Color  = AppColors.gray600
    static let toolbar: Color   = .primary
    /// White text for use on colored surfaces (red/purple cards)
    static let onColor: Color   = .white
    /// Subtitle on colored surfaces. Kept high (0.9, not 0.8): at 13pt on
    /// `PrimaryRed` every step down costs contrast the small size can't
    /// afford — see the note on `HeroFeatureCard`.
    static let onColorSecondary = Color.white.opacity(0.9)
    /// Content on `AppColors.black` surfaces. AppBlack inverts to
    /// near-white in dark mode, so its content must invert too —
    /// plain `.white` becomes invisible there.
    static let onBlack = Color(.systemBackground)
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
    /// Tight stacks (title + subtitle on one card).
    static let tight: CGFloat = 2
    /// Large vertical padding around empty-state illustrations.
    static let emptyStateVertical: CGFloat = 80
    /// Minimum space above/below an empty-state block (e.g. journal placeholder).
    static let emptyStateInset: CGFloat = 60
}

// MARK: - Corner Radius

enum CornerRadius {
    static let sm:   CGFloat = 8
    static let md:   CGFloat = 14
    static let lg:   CGFloat = 22
    static let xl:   CGFloat = 28
    static let pill: CGFloat = 999
}

// MARK: - Borders

enum BorderWidth {
    /// 0.5pt — card strokes, search field outline (matches `cardStyle` overlay).
    static let hairline: CGFloat = 0.5
    /// 1pt — outline of an interactive control (`AppColors.controlBorder`).
    static let standard: CGFloat = 1
    /// 1.5pt — the same control once selected, so the state reads at a glance
    /// without the layout shifting.
    static let emphasized: CGFloat = 1.5
}

// MARK: - Touch Targets
// iOS HIG minimum is 44×44 pt. Never go below this.

enum TouchTarget {
    static let minimum:  CGFloat = 44
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
    /// SF Symbol font size for the glyph inside a `hero` container.
    /// Wrap in `@ScaledMetric` at the use site so it tracks Dynamic Type.
    static let heroGlyph: CGFloat = 26
    /// Large illustration icons in empty states (aligned with prominent UI scale).
    static let emptyState: CGFloat = 40
    /// Glyphs paired with body-sized field text — matches `AppTextStyle.body` (15pt).
    ///
    /// ⚠️ Prefer `.appFont(.bodyMedium)` on the `Image` instead: a raw
    /// `.system(size:)` is frozen at this value and stops tracking Dynamic
    /// Type, so the label grows and the glyph next to it does not (codex §6).
    static let fieldGlyph: CGFloat = 15
}

// MARK: - Field Sizes

/// Intrinsic sizes of form controls that have no natural content size.
/// Wrap in `@ScaledMetric` at the use site so they track Dynamic Type.
enum FieldSize {
    /// Multiline editor height — about three lines of body text, enough to
    /// show that more than a phrase is welcome without eating the screen.
    static let editorMinHeight: CGFloat = 80
    /// Inline "your own…" chip field. A chip inside `ChipFlowLayout` gets an
    /// unspecified proposal, so a text field needs an explicit width.
    static let inlineChipField: CGFloat = 140
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

// MARK: - Color from Hex

extension Color {
    init?(hex: String) {
        var str = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        str = str.hasPrefix("#") ? String(str.dropFirst()) : str
        guard str.count == 6, let value = UInt64(str, radix: 16) else { return nil }
        self.init(
            red:   Double((value >> 16) & 0xFF) / 255.0,
            green: Double((value >>  8) & 0xFF) / 255.0,
            blue:  Double( value        & 0xFF) / 255.0
        )
    }
}

// MARK: - Animation

enum AppAnimation {
    static let standard  = Animation.easeOut(duration: 0.22)
    static let spring    = Animation.spring(response: 0.38, dampingFraction: 0.72)
    static let fast      = Animation.easeOut(duration: 0.14)
    static let slow      = Animation.easeInOut(duration: 0.40)
    static let appear    = Animation.easeOut(duration: 0.28)
}

// MARK: - Content scaling

enum ContentScaling {
    /// Allow stat tiles to shrink before truncating.
    static let statMinimum: CGFloat = 0.7
}

// MARK: - Timings (seconds)

enum InteractionTiming {
    /// Auto-dismiss for transient bottom banners.
    static let toastAutoDismiss: TimeInterval = 3
}
