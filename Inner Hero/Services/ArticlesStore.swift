import Combine
import Foundation

@MainActor
final class ArticlesStore: ObservableObject {
    @Published private(set) var allArticles: [Article]
    @Published private(set) var featuredArticles: [Article]
    
    init(loader: @MainActor () -> [Article] = { ArticlesLoader.loadArticles() }) {
        let loaded = loader()
        self.allArticles = loaded
        self.featuredArticles = Array(loaded.shuffled().prefix(2))
    }
}


