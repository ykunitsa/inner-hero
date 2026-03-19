import SwiftUI

struct ArticleDetailView: View {
    let article: Article

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                articleHeader
                Divider()
                    .padding(.vertical, Spacing.xxxs)
                articleContent
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.xxl)
        }
        .homeBackground()
        .navigationTitle(article.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Header

    private var articleHeader: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Icon + title + category — one unified block like ArticleRow
            HStack(spacing: Spacing.xs) {
                Image(systemName: article.icon)
                    .font(.system(size: IconSize.glyph, weight: .medium))
                    .foregroundStyle(AppColors.accent)
                    .iconContainer(
                        size: IconSize.card,
                        backgroundColor: AppColors.accent.opacity(Opacity.softBackground),
                        cornerRadius: CornerRadius.sm
                    )
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(article.title)
                        .appFont(.h3)
                        .foregroundStyle(TextColors.primary)

                    Text(article.category)
                        .appFont(.small)
                        .foregroundStyle(AppColors.accent.opacity(0.8))
                }
            }

            // Meta row
            HStack(spacing: Spacing.sm) {
                Label(
                    String(format: NSLocalizedString("%d min read", comment: ""), article.readTime),
                    systemImage: "clock"
                )
                .appFont(.small)
                .foregroundStyle(TextColors.secondary)

                Label(
                    String(localized: "Education"),
                    systemImage: "book.fill"
                )
                .appFont(.small)
                .foregroundStyle(TextColors.secondary)
            }
        }
    }

    // MARK: - Content

    private var articleContent: some View {
        Text(article.content)
            .appFont(.bodyLarge)
            .foregroundStyle(TextColors.primary)
            .lineSpacing(AppTextStyle.bodyLarge.lineSpacing + 2)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ArticleDetailView(article: Article(
            id: "preview",
            title: "Understanding Anxiety",
            description: "What anxiety is and how it affects our lives",
            content: "Anxiety is a natural reaction of the body to stressful situations. It helps us stay alert and ready to act. However, when anxiety becomes excessive or constant, it can interfere with daily life.",
            icon: "brain.head.profile",
            category: "Anxiety",
            readTime: 5
        ))
    }
}
