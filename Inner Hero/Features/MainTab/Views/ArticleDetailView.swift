import SwiftUI

struct ArticleDetailView: View {
    let article: Article
    
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
                                Circle()
                                    .fill(Color.blue.opacity(0.1))
                            )
                        
                        Spacer()
                        
                        Text(article.category)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.blue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color.blue.opacity(0.1))
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
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.97, blue: 1.0),
                    Color(red: 0.92, green: 0.95, blue: 0.98)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .navigationTitle("Статья")
        .navigationBarTitleDisplayMode(.inline)
    }
}


