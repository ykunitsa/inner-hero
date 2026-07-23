import SwiftUI
import WidgetKit

/// The shared body of every widget in this bundle: a glyph, a title, a quiet line.
///
/// A new component rather than `ExerciseRow` or `HeroFeatureCard`, and the reason is
/// structural rather than aesthetic. Those are `Button`s built for full screen
/// width — a 56pt glyph, `Spacing.md` padding and a chevron fill a 158pt widget on
/// their own, and a button inside a widget is not a thing that exists. What is
/// reused is everything that carries the app's look: the tokens, the type scale, the
/// icon container, the hierarchy of title over subtitle.
///
/// There is no chevron and no arrow: in a widget there is no second element to
/// distinguish the tappable one from. The whole surface is the target.
struct WidgetTile: View {
    let icon: String
    let title: String
    /// Nil under App Lock — the snapshot arrives with nothing to say, and the tile
    /// shows the exercise's name alone rather than a placeholder.
    let subtitle: String?
    var tint: Color = AppColors.primary
    /// `systemMedium` gives the text room; small has to keep two lines.
    var isWide: Bool = false

    var body: some View {
        HStack(spacing: isWide ? Spacing.sm : 0) {
            if isWide {
                glyph
                labels
                Spacer(minLength: 0)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    glyph
                    Spacer(minLength: Spacing.xs)
                    labels
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var glyph: some View {
        Image(systemName: icon)
            // `.appFont`, not `.system(size:)` — a frozen point size drops the
            // glyph out of Dynamic Type, the same reason the launcher tiles use it.
            .appFont(isWide ? .h2 : .h3)
            .foregroundStyle(tint)
            .frame(
                width: isWide ? IconSize.hero : IconSize.card,
                height: isWide ? IconSize.hero : IconSize.card
            )
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                    .fill(tint.opacity(Opacity.subtleBackground))
            )
            // The tinted home screen renders the glyph in the user's colour and
            // leaves the rest of the tile in greyscale.
            .widgetAccentable()
            .accessibilityHidden(true)
    }

    private var labels: some View {
        VStack(alignment: .leading, spacing: Spacing.xxxs) {
            Text(title)
                .appFont(isWide ? .h3 : .bodyMedium)
                .foregroundStyle(TextColors.primary)
                // Truncation rather than a shrinking font: text that scales down to
                // fit reads as a rendering fault, and the canvas cannot grow.
                .lineLimit(2)
            if let subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .appFont(isWide ? .body : .small)
                    .foregroundStyle(TextColors.secondary)
                    .lineLimit(2)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}
