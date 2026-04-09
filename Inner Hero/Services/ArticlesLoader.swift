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
    let sources: [ArticleSource]

    init(
        id: String,
        title: String,
        description: String,
        content: String,
        icon: String,
        category: String,
        readTime: Int,
        sources: [ArticleSource] = []
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.content = content
        self.icon = icon
        self.category = category
        self.readTime = readTime
        self.sources = sources
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case content
        case icon
        case category
        case readTime
        case sources
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        content = try container.decode(String.self, forKey: .content)
        icon = try container.decode(String.self, forKey: .icon)
        category = try container.decode(String.self, forKey: .category)
        readTime = try container.decode(Int.self, forKey: .readTime)
        sources = try container.decodeIfPresent([ArticleSource].self, forKey: .sources) ?? []
    }
}

struct ArticleSource: Identifiable, Codable, Hashable {
    let title: String
    let url: String

    var id: String { url }
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

