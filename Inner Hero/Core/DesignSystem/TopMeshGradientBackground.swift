import SwiftUI

/// A top-only mesh gradient that smoothly fades into `systemBackground` toward the bottom,
/// so it looks correct in both light and dark mode.
struct TopMeshGradientBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    
    enum Palette: Sendable {
        case `default`
        case teal
        case mint
        case green
        case purple
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
        case .mint:
            return [
                Color(red: 0.24, green: 0.92, blue: 0.78), // vivid mint
                Color(red: 0.18, green: 0.78, blue: 0.66), // seafoam teal
                Color(red: 0.14, green: 0.70, blue: 0.60), // deep seafoam
                
                Color(red: 0.42, green: 0.96, blue: 0.84), // bright mint
                Color(red: 0.36, green: 0.88, blue: 0.86), // mint-cyan
                Color(red: 0.20, green: 0.84, blue: 0.74), // soft seafoam
                
                Color(red: 0.94, green: 0.99, blue: 0.98), // near-white mint
                Color(red: 0.92, green: 0.98, blue: 0.99), // near-white mint-cyan
                Color(red: 0.90, green: 0.98, blue: 0.97)  // near-white seafoam
            ]
        case .green:
            return [
                Color(red: 0.20, green: 0.86, blue: 0.56), // vivid green
                Color(red: 0.14, green: 0.74, blue: 0.46), // deep green
                Color(red: 0.12, green: 0.66, blue: 0.42), // forest green
                
                Color(red: 0.44, green: 0.94, blue: 0.66), // bright spring
                Color(red: 0.34, green: 0.86, blue: 0.74), // green-mint
                Color(red: 0.24, green: 0.82, blue: 0.58), // soft green
                
                Color(red: 0.95, green: 0.99, blue: 0.97), // near-white green
                Color(red: 0.92, green: 0.99, blue: 0.98), // near-white spring
                Color(red: 0.90, green: 0.98, blue: 0.96)  // near-white mint-green
            ]
        case .purple:
            return [
                Color(red: 0.62, green: 0.48, blue: 0.98), // violet
                Color(red: 0.45, green: 0.35, blue: 0.92), // deep purple
                Color(red: 0.34, green: 0.44, blue: 0.96), // indigo-blue
                
                Color(red: 0.80, green: 0.62, blue: 1.00), // soft lilac
                Color(red: 0.60, green: 0.70, blue: 1.00), // periwinkle
                Color(red: 0.95, green: 0.70, blue: 0.96), // pink-lilac
                
                Color(red: 0.96, green: 0.96, blue: 1.00), // near-white violet
                Color(red: 0.94, green: 0.95, blue: 1.00), // near-white periwinkle
                Color(red: 0.93, green: 0.94, blue: 0.99)  // near-white purple
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


