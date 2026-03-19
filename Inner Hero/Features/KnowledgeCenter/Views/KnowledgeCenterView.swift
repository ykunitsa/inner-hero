import SwiftUI

struct KnowledgeCenterView: View {
    @Binding var path: NavigationPath

    @Environment(ArticlesStore.self) private var articlesStore
    @State private var query = ""
    @State private var appeared = false

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: Spacing.lg) {
                    if groupedArticles.isEmpty {
                        emptyStateView
                            .padding(.top, Spacing.xxl)
                    } else {
                        ForEach(Array(groupedArticles.enumerated()), id: \.element.category) { groupIndex, group in
                            articleSection(group: group, groupIndex: groupIndex)
                        }
                    }
                }
                .padding(.horizontal, Spacing.sm)
                .padding(.top, Spacing.md)
                .padding(.bottom, Spacing.xxl)
            }
            .homeBackground()
            .navigationTitle(String(localized: "Knowledge center"))
            .navigationBarTitleDisplayMode(.large)
            .searchable(
                text: $query,
                placement: .navigationBarDrawer(displayMode: .automatic),
                prompt: String(localized: "Search")
            )
            .navigationDestination(for: AppRoute.self) { route in
                AppRouteView(route: route)
            }
            .onAppear { appeared = true }
        }
    }

    // MARK: - Section

    private func articleSection(group: ArticleGroup, groupIndex: Int) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            SectionHeader(title: group.category)

            VStack(spacing: Spacing.xxs) {
                ForEach(Array(group.articles.enumerated()), id: \.element.id) { index, article in
                    NavigationLink(value: AppRoute.articleDetail(articleId: article.id)) {
                        ArticleRow(article: article)
                    }
                    .buttonStyle(.plain)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 12)
                    .animation(
                        AppAnimation.appear.delay(Double(groupIndex * 3 + index) * 0.04),
                        value: appeared
                    )
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: query.isEmpty ? "book.closed" : "magnifyingglass")
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(AppColors.accent.opacity(0.7))
                .accessibilityHidden(true)

            VStack(spacing: Spacing.xxs) {
                Text(query.isEmpty
                     ? String(localized: "No articles yet")
                     : String(localized: "No results"))
                    .appFont(.h2)
                    .foregroundStyle(TextColors.primary)

                Text(query.isEmpty
                     ? String(localized: "Articles are not available yet")
                     : String(localized: "No results for this search"))
                    .appFont(.body)
                    .foregroundStyle(TextColors.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, Spacing.lg)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Computed

    private var filteredArticles: [Article] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return articlesStore.allArticles }
        return articlesStore.allArticles.filter {
            $0.title.localizedCaseInsensitiveContains(trimmed)
            || $0.description.localizedCaseInsensitiveContains(trimmed)
            || $0.content.localizedCaseInsensitiveContains(trimmed)
        }
    }

    private var groupedArticles: [ArticleGroup] {
        Dictionary(grouping: filteredArticles, by: \.category)
            .map { ArticleGroup(category: $0.key, articles: $0.value.sorted {
                $0.title.localizedStandardCompare($1.title) == .orderedAscending
            }) }
            .sorted { $0.category.localizedStandardCompare($1.category) == .orderedAscending }
    }
}

// MARK: - ArticleGroup

private struct ArticleGroup {
    let category: String
    let articles: [Article]
}

// MARK: - ArticleRow

private struct ArticleRow: View {
    let article: Article

    var body: some View {
        HStack(spacing: Spacing.xs) {
            // Icon
            Image(systemName: article.icon)
                .font(.system(size: IconSize.glyph, weight: .medium))
                .foregroundStyle(AppColors.accent)
                .iconContainer(
                    size: IconSize.card,
                    backgroundColor: AppColors.accent.opacity(Opacity.softBackground),
                    cornerRadius: CornerRadius.sm
                )
                .accessibilityHidden(true)

            // Labels
            VStack(alignment: .leading, spacing: Spacing.xxxs) {
                Text(article.title)
                    .appFont(.bodyMedium)
                    .foregroundStyle(TextColors.primary)
                    .lineLimit(2)

                Text(article.description)
                    .appFont(.small)
                    .foregroundStyle(TextColors.secondary)
                    .lineLimit(2)

                // Meta
                HStack(spacing: Spacing.xs) {
                    Label(
                        String(format: NSLocalizedString("%d min", comment: ""), article.readTime),
                        systemImage: "clock"
                    )
                    .appFont(.smallMedium)
                    .foregroundStyle(AppColors.accent.opacity(0.8))
                }
                .padding(.top, 2)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppColors.gray400)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .cardStyle(cornerRadius: CornerRadius.lg, padding: 0)
    }
}

// MARK: - Preview

#Preview {
    KnowledgeCenterView(path: .constant(NavigationPath()))
        .environment(ArticlesStore())
}
