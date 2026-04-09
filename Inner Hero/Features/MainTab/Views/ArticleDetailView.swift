import SwiftUI

struct ArticleDetailView: View {
    let article: Article

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                articleHeader
                medicalDisclaimer
                Divider()
                    .padding(.vertical, Spacing.xxxs)
                articleContent
                if !article.sources.isEmpty {
                    Divider()
                        .padding(.vertical, Spacing.xxxs)
                    sourcesSection
                }
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

    // MARK: - Sources

    private var sourcesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(sourcesTitle)
                .appFont(.h3)
                .foregroundStyle(TextColors.primary)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                ForEach(Array(article.sources.enumerated()), id: \.element.id) { index, source in
                    if let url = URL(string: source.url), !source.url.isEmpty {
                        Link(destination: url) {
                            HStack(alignment: .top, spacing: Spacing.xxs) {
                                Text("\(index + 1).")
                                    .appFont(.smallMedium)
                                    .foregroundStyle(TextColors.secondary)

                                Text(source.title)
                                    .appFont(.smallMedium)
                                    .foregroundStyle(AppColors.accent)
                                    .multilineTextAlignment(.leading)

                                Image(systemName: "arrow.up.right.square")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(AppColors.accent.opacity(0.9))
                                    .padding(.top, 1)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Disclaimer

    private var medicalDisclaimer: some View {
        Text(disclaimerText)
            .appFont(.small)
            .foregroundStyle(TextColors.secondary)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.accent.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous))
            .accessibilityLabel(disclaimerText)
    }

    // MARK: - Localized Text

    private var isRussian: Bool {
        Locale.preferredLanguages.first?.lowercased().hasPrefix("ru") == true
    }

    private var sourcesTitle: String {
        isRussian ? "Источники" : "Sources"
    }

    private var disclaimerText: String {
        if isRussian {
            return "Информация в этой статье носит образовательный характер и не заменяет консультацию, диагностику или лечение у квалифицированного медицинского специалиста."
        }
        return "Information in this article is educational and does not replace professional medical advice, diagnosis, or treatment."
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
