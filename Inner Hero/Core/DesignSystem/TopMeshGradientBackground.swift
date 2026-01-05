import SwiftUI

/// A top-only mesh gradient that smoothly fades into `systemBackground` toward the bottom,
/// so it looks correct in both light and dark mode.
struct TopMeshGradientBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    
    enum Palette: Sendable {
        case `default`
        case teal
    }
    
    var height: CGFloat
    var fadeHeight: CGFloat
    var palette: Palette
    
    init(height: CGFloat = 320, fadeHeight: CGFloat = 140, palette: Palette = .default) {
        self.height = height
        self.fadeHeight = fadeHeight
        self.palette = palette
    }
    
    private var meshColors: [Color] {
        switch palette {
        case .default:
            return [
                Color(red: 0.46, green: 0.86, blue: 0.95), // aqua
                Color(red: 0.36, green: 0.58, blue: 0.98), // blue
                Color(red: 0.70, green: 0.60, blue: 1.00), // lilac
                
                Color(red: 0.52, green: 0.94, blue: 0.80), // mint
                Color(red: 0.78, green: 0.86, blue: 1.00), // soft sky
                Color(red: 0.96, green: 0.70, blue: 0.90), // pink
                
                Color(red: 0.94, green: 0.97, blue: 1.00), // near-white
                Color(red: 0.90, green: 0.96, blue: 1.00), // near-white blue
                Color(red: 0.86, green: 0.95, blue: 0.98)  // near-white teal
            ]
        case .teal:
            return [
                Color(red: 0.16, green: 0.86, blue: 0.80), // teal
                Color(red: 0.22, green: 0.72, blue: 0.96), // cyan-blue
                Color(red: 0.14, green: 0.60, blue: 0.84), // deep teal-blue
                
                Color(red: 0.38, green: 0.92, blue: 0.78), // mint
                Color(red: 0.46, green: 0.82, blue: 0.98), // soft sky
                Color(red: 0.22, green: 0.78, blue: 0.70), // seafoam
                
                Color(red: 0.93, green: 0.98, blue: 0.98), // near-white teal
                Color(red: 0.90, green: 0.97, blue: 0.99), // near-white cyan
                Color(red: 0.88, green: 0.96, blue: 0.97)  // near-white mint
            ]
        }
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            Rectangle()
                .fill(.background)
                .ignoresSafeArea()
            
            MeshGradient(
                width: 3,
                height: 3,
                points: [
                    SIMD2(0.0, 0.0), SIMD2(0.5, 0.0), SIMD2(1.0, 0.0),
                    SIMD2(0.0, 0.5), SIMD2(0.5, 0.5), SIMD2(1.0, 0.5),
                    SIMD2(0.0, 1.0), SIMD2(0.5, 1.0), SIMD2(1.0, 1.0)
                ],
                colors: meshColors
            )
            .saturation(colorScheme == .dark ? 1.1 : 1.0)
            .opacity(colorScheme == .dark ? 0.55 : 1.0)
            .blur(radius: 18)
            .frame(height: height)
            .ignoresSafeArea(edges: .top)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(.background)
                    .frame(height: fadeHeight)
                    .mask(
                        LinearGradient(
                            colors: [.clear, .black],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
        }
        .accessibilityHidden(true)
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 24) {
            RoundedRectangle(cornerRadius: 20)
                .fill(.thinMaterial)
                .frame(height: 160)
                .padding(.horizontal, 20)
            
            RoundedRectangle(cornerRadius: 20)
                .fill(.thinMaterial)
                .frame(height: 320)
                .padding(.horizontal, 20)
        }
        .padding(.top, 24)
        .padding(.bottom, 40)
    }
    .background(TopMeshGradientBackground())
}


