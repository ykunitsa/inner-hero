import Foundation

// MARK: - Article Model

struct Article: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let content: String
    let icon: String
    let category: String
    let readTime: Int
}

// MARK: - Articles Container

struct ArticlesContainer: Codable {
    let articles: [Article]
}

// MARK: - Articles Loader

enum ArticlesLoader {
    private static var cachedArticlesByLocalization: [String: [Article]] = [:]
    
    static func loadArticles() -> [Article] {
        let localizationKey = resolvedLocalizationKey()
        if let cached = cachedArticlesByLocalization[localizationKey] {
            return cached
        }
        
        guard let url = localizedArticlesURL(for: localizationKey) else {
            print("⚠️ Articles.json not found in bundle")
            return []
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let container = try decoder.decode(ArticlesContainer.self, from: data)
            cachedArticlesByLocalization[localizationKey] = container.articles
            return container.articles
        } catch {
            print("⚠️ Error loading articles: \(error)")
            return []
        }
    }
    
    static func getArticle(by id: String) -> Article? {
        return loadArticles().first { $0.id == id }
    }
    
    static func getArticles(by category: String) -> [Article] {
        return loadArticles().filter { $0.category == category }
    }

    private static func resolvedLocalizationKey() -> String {
        let available = Bundle.main.localizations
        for preferred in Locale.preferredLanguages {
            if available.contains(preferred) {
                return preferred
            }
            if let languageCode = Locale(identifier: preferred).languageCode,
               available.contains(languageCode) {
                return languageCode
            }
        }
        
        if available.contains("Base") {
            return "Base"
        }
        
        return available.first ?? "Base"
    }
    
    private static func localizedArticlesURL(for localizationKey: String) -> URL? {
        if let localizedURL = Bundle.main.url(
            forResource: "Articles",
            withExtension: "json",
            subdirectory: nil,
            localization: localizationKey
        ) {
            return localizedURL
        }
        
        return Bundle.main.url(forResource: "Articles", withExtension: "json")
    }
}


