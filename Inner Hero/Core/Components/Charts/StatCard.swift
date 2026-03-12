import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    
    private enum Layout {
        static let cardSpacing: CGFloat = 8
        static let cardPadding: CGFloat = 16
        static let cornerRadius: CGFloat = 12
    }
    
    var body: some View {
        VStack(spacing: Layout.cardSpacing) {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2.weight(.bold))
                .foregroundStyle(color)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 44)
        .padding(Layout.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: Layout.cornerRadius, style: .continuous)
                .fill(.background.tertiary)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}
