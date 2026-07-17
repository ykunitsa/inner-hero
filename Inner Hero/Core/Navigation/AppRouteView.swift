import SwiftUI

// MARK: - App Route View

struct AppRouteView: View {
    let route: AppRoute

    @Environment(ArticlesStore.self) private var articlesStore

    var body: some View {
        switch route {
        case .articleDetail(let articleId):
            if let article = articlesStore.allArticles.first(where: { $0.id == articleId }) {
                ArticleDetailView(article: article)
            } else {
                ContentUnavailableView(
                    String(localized: "Article not found"),
                    systemImage: "questionmark.circle",
                    description: Text(String(localized: "The item may have been removed or is unavailable."))
                )
                .padding()
            }

        case .settings:
            SettingsView()

        case .settingsAppearance:
            AppearanceSettingsView()

        case .settingsPrivacy:
            PrivacySettingsView()
        }
    }
}
