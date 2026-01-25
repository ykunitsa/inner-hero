import SwiftUI

struct ArticleDetailView: View {
    let article: Article

    @Environment(\.colorScheme) private var colorScheme

    private var backgroundGradient: LinearGradient {
        // Keep the same visual idea in light mode, but switch to a dark-friendly palette in dark mode.
        let colors: [Color] = if colorScheme == .dark {
            [
                Color(red: 0.07, green: 0.09, blue: 0.13),
                Color(red: 0.10, green: 0.12, blue: 0.18)
            ]
        } else {
            [
                Color(red: 0.95, green: 0.97, blue: 1.0),
                Color(red: 0.92, green: 0.95, blue: 0.98)
            ]
        }

        return LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: article.icon)
                            .font(.system(size: 50))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .cyan],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                            .background(
                                Circle().fill(.thinMaterial)
                            )
                        
                        Spacer()
                        
                        Text(article.category)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.tint)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule().fill(.thinMaterial)
                            )
                    }
                    
                    Text(article.title)
                        .font(.title.weight(.semibold))
                        .foregroundStyle(TextColors.primary)
                    
                    HStack(spacing: 16) {
                        HStack(spacing: 6) {
                            Image(systemName: "clock")
                                .font(.caption)
                            Text("\(article.readTime) мин чтения")
                                .font(.caption)
                        }
                        .foregroundStyle(TextColors.secondary)
                        
                        HStack(spacing: 6) {
                            Image(systemName: "book.fill")
                                .font(.caption)
                            Text("Образование")
                                .font(.caption)
                        }
                        .foregroundStyle(TextColors.secondary)
                    }
                }
                
                Divider()
                
                // Content
                Text(article.content)
                    .font(.body)
                    .foregroundStyle(TextColors.primary)
                    .lineSpacing(8)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(20)
        }
        .background {
            ZStack {
                Rectangle()
                    .fill(.background)
                    .ignoresSafeArea()

                backgroundGradient
                    .opacity(colorScheme == .dark ? 0.35 : 1.0)
                    .ignoresSafeArea()
            }
        }
        .navigationTitle("Статья")
        .navigationBarTitleDisplayMode(.inline)
    }
}


