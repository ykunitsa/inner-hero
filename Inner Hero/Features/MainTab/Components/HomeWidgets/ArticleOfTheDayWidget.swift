import SwiftUI

struct ArticleOfTheDayWidget: View {
    let article: Article?
    
    var body: some View {
        Group {
            if let article {
                NavigationLink {
                    ArticleDetailView(article: article)
                } label: {
                    WidgetCard(minHeight: 120) {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Label("Статья дня", systemImage: "book.pages")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.purple)
                                Spacer()
                            }
                            
                            Text(article.title)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.primary)
                                .lineLimit(2)
                            
                            HStack(spacing: 10) {
                                Text(article.category)
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(.blue)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Capsule().fill(Color.blue.opacity(0.12)))
                                
                                Spacer(minLength: 0)
                                
                                Label {
                                    Text(String(format: NSLocalizedString("%d мин", comment: ""), article.readTime))
                                } icon: {
                                    Image(systemName: "clock")
                                }
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .buttonStyle(.plain)
            } else {
                WidgetCard(minHeight: 120) {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Статья дня", systemImage: "book.pages")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.purple)
                        
                        Text("Нет статей")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.primary)
                        
                        Text("Загляните позже")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
}

