import SwiftUI

struct KnowledgeCenterView: View {
    @EnvironmentObject private var articlesStore: ArticlesStore
    @State private var query = ""
    
    var body: some View {
        NavigationStack {
            List {
                if groupedArticles.isEmpty {
                    ContentUnavailableView {
                        Label("Нет статей", systemImage: "book")
                    } description: {
                        Text(query.isEmpty ? "Статьи пока недоступны" : "По запросу ничего не найдено")
                    }
                } else {
                    ForEach(groupedArticles, id: \.category) { group in
                        Section(group.category) {
                            ForEach(group.articles) { article in
                                KnowledgeCenterArticleRow(article: article)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(TopMeshGradientBackground())
            .navigationTitle("Центр знаний")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "Поиск")
        }
    }
    
    private var filteredArticles: [Article] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return articlesStore.allArticles }
        
        return articlesStore.allArticles.filter { article in
            article.title.localizedCaseInsensitiveContains(trimmed)
            || article.description.localizedCaseInsensitiveContains(trimmed)
            || article.content.localizedCaseInsensitiveContains(trimmed)
        }
    }
    
    private var groupedArticles: [ArticleGroup] {
        let grouped = Dictionary(grouping: filteredArticles, by: \.category)
        
        return grouped
            .map { (category: $0.key, articles: $0.value) }
            .map { group in
                ArticleGroup(
                    category: group.category,
                    articles: group.articles.sorted { lhs, rhs in
                        lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
                    }
                )
            }
            .sorted { lhs, rhs in
                lhs.category.localizedStandardCompare(rhs.category) == .orderedAscending
            }
    }
}

private struct ArticleGroup {
    let category: String
    let articles: [Article]
}

private struct KnowledgeCenterArticleRow: View {
    let article: Article
    
    var body: some View {
        NavigationLink {
            ArticleDetailView(article: article)
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: article.icon)
                    .font(.title3)
                    .foregroundStyle(.blue)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(Color.blue.opacity(0.12))
                    )
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(article.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(TextColors.primary)
                        .lineLimit(2)
                    
                    Text(article.description)
                        .font(.caption)
                        .foregroundStyle(TextColors.secondary)
                        .lineLimit(2)
                    
                    HStack(spacing: 10) {
                        Label("\(article.readTime) мин", systemImage: "clock")
                            .labelStyle(.titleAndIcon)
                        
                        Text(article.category)
                    }
                    .font(.caption2)
                    .foregroundStyle(TextColors.tertiary)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

#Preview {
    KnowledgeCenterView()
        .environmentObject(ArticlesStore())
}


