import Foundation
import Observation

@MainActor
@Observable
final class ArticlesStore {
    private(set) var allArticles: [Article]
    private(set) var featuredArticles: [Article]
    
    init(loader: @MainActor () -> [Article] = { ArticlesLoader.loadArticles() }) {
        let loaded = loader()
        self.allArticles = loaded
        self.featuredArticles = Array(loaded.shuffled().prefix(2))
    }
}
