import SwiftUI

struct ArticleCard: View {
    let article: Article
    @Environment(\.colorScheme) var colorScheme
    
    private static let cardHeight: CGFloat = 160
    
    var body: some View {
        NavigationLink {
            ArticleDetailView(article: article)
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: article.icon)
                        .font(.title3)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(Color.blue.opacity(0.1))
                        )
                    
                    Spacer()
                    
                    Text(article.category)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.blue.opacity(0.1))
                        )
                }
                
                Text(article.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(TextColors.primary)
                    .lineLimit(2)
                
                Text(article.description)
                    .font(.caption)
                    .foregroundStyle(TextColors.secondary)
                    .lineLimit(2)
                
                HStack {
                    Image(systemName: "clock")
                        .font(.caption2)
                        .foregroundStyle(TextColors.tertiary)
                    Text(String(format: NSLocalizedString("%d мин", comment: ""), article.readTime))
                        .font(.caption2)
                        .foregroundStyle(TextColors.tertiary)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: Self.cardHeight, maxHeight: Self.cardHeight, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        colorScheme == .dark
                        ? LinearGradient(
                            colors: [
                                Color(uiColor: .secondarySystemGroupedBackground),
                                Color(uiColor: .tertiarySystemGroupedBackground)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        : LinearGradient(
                            colors: [
                                Color(red: 0.98, green: 0.99, blue: 1.0),
                                Color(red: 0.96, green: 0.97, blue: 0.99)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.blue.opacity(colorScheme == .dark ? 0.3 : 0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}


