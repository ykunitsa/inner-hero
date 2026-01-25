import SwiftUI

struct ProgressRingView: View {
    let progress: Double // 0...1
    var lineWidth: CGFloat = 12
    var tint: Color = .blue
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var clampedProgress: Double {
        min(1, max(0, progress))
    }
    
    private var trackOpacity: Double {
        colorScheme == .dark ? 0.22 : 0.14
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(tint.opacity(trackOpacity), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            
            Circle()
                .trim(from: 0, to: clampedProgress)
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.45), value: clampedProgress)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Прогресс")
        .accessibilityValue("\(Int(clampedProgress * 100)) процентов")
    }
}

