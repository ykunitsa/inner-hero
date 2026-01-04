import SwiftUI
import SwiftData

struct HomeView: View {
    @State private var appeared = false
    private let articles = ArticlesLoader.loadArticles()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 24) {
                    ScheduledExercisesSection()
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                        .animation(.easeOut(duration: 0.3).delay(0.0), value: appeared)
                    
                    FavoritesSection()
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                        .animation(.easeOut(duration: 0.3).delay(0.1), value: appeared)
                    
                    articlesSection
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                        .animation(.easeOut(duration: 0.3).delay(0.2), value: appeared)
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 40)
            }
            .background(TopMeshGradientBackground())
            .navigationTitle("Сводка")
            .navigationBarTitleDisplayMode(.large)
            .opacity(appeared ? 1 : 0)
            .animation(.easeIn(duration: 0.3), value: appeared)
            .onAppear {
                appeared = true
            }
        }
    }
    
    private var articlesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            let accent = LinearGradient(
                colors: [.purple, .indigo],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            HStack {
                Image(systemName: "book.fill")
                    .font(.body)
                    .foregroundStyle(accent)
                Text("Образовательные статьи")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(accent)
            }
            
            if articles.isEmpty {
                emptyArticlesView
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(articles) { article in
                        ArticleCard(article: article)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
    }
    
    private var emptyArticlesView: some View {
        VStack(spacing: 8) {
            Text("Нет доступных статей")
                .font(.subheadline)
                .foregroundStyle(TextColors.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [ExerciseAssignment.self, FavoriteExercise.self, Exposure.self, ActivityList.self], inMemory: true)
}


