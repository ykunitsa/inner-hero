import SwiftUI

struct WidgetCard<Content: View>: View {
    let minHeight: CGFloat
    let content: Content
    
    @Environment(\.colorScheme) private var colorScheme
    
    init(minHeight: CGFloat = 120, @ViewBuilder content: () -> Content) {
        self.minHeight = minHeight
        self.content = content()
    }
    
    private var strokeOpacity: Double {
        colorScheme == .dark ? 0.18 : 0.07
    }

    private var shadowOpacity: Double {
        colorScheme == .dark ? 0.28 : 0.08
    }
    
    var body: some View {
        content
            .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .topLeading)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(.primary.opacity(strokeOpacity), lineWidth: 1)
            }
            .shadow(color: .black.opacity(shadowOpacity), radius: 10, x: 0, y: 6)
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

