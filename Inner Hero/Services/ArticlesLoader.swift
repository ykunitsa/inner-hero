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
    private static var cachedArticles: [Article]?
    
    static func loadArticles() -> [Article] {
        if let cached = cachedArticles {
            return cached
        }
        
        guard let url = Bundle.main.url(forResource: "Articles", withExtension: "json") else {
            print("⚠️ Articles.json not found in bundle")
            return []
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let container = try decoder.decode(ArticlesContainer.self, from: data)
            cachedArticles = container.articles
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
}


