import SwiftUI

/// A subtle, top-only glow that softens the default grouped background.
/// Designed to look correct in both light and dark mode without overpowering content.
struct HomeTopGlowBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    
    /// Kept low on purpose: on screens that carry an accent hero card the
    /// glow sits directly behind it, and anything stronger reads as a second
    /// red wash competing with the card instead of warming the page.
    private var glowOpacity: Double {
        colorScheme == .dark ? 0.12 : 0.08
    }
    
    private var glowBlur: CGFloat {
        colorScheme == .dark ? 28 : 44
    }
    
    private var glowOffsetY: CGFloat {
        colorScheme == .dark ? -140 : -160
    }
    
    private var highlightOpacity: Double {
        colorScheme == .dark ? 0.06 : 0.03
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            Color(.systemGroupedBackground)
            
            RadialGradient(
                colors: [
                    Color.accentColor.opacity(glowOpacity),
                    Color.accentColor.opacity(0.0)
                ],
                center: .top,
                startRadius: 0,
                endRadius: 520
            )
            .blur(radius: glowBlur)
            .offset(y: glowOffsetY)
            .allowsHitTesting(false)
            
            LinearGradient(
                colors: [
                    Color.primary.opacity(highlightOpacity),
                    .clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 220)
            .allowsHitTesting(false)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

extension View {
    func homeBackground() -> some View {
        background { HomeTopGlowBackground() }
    }
}

