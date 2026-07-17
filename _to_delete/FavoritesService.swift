import Foundation
import SwiftData

/// Stateless helper for favorite exercise logic. Use with `@Query`-backed `favorites` in views for reactive `isFavorite`.
struct FavoritesService {
    
    // MARK: - Toggle
    
    /// Finds a matching favorite by criteria; if found, deletes it and returns `false`, otherwise inserts one and returns `true`.
    /// Performs fetch via `context` internally. Call from main actor; pass `modelContext` from environment.
    @discardableResult
    static func toggle(
        type: ExerciseType,
        exerciseId: UUID? = nil,
        identifier: String? = nil,
        context: ModelContext
    ) throws -> Bool {
        let allFavorites = try fetchAll(context: context)
        if let existing = allFavorites.first(where: { favorite in
            favorite.matches(exerciseType: type, exerciseId: exerciseId, exerciseIdentifier: identifier)
        }) {
            context.delete(existing)
            try context.save()
            return false
        } else {
            let favorite = FavoriteExercise(
                exerciseType: type,
                exerciseId: exerciseId,
                exerciseIdentifier: identifier
            )
            context.insert(favorite)
            try context.save()
            return true
        }
    }
    
    // MARK: - Check (no fetch)
    
    /// Returns whether the exercise is in the given favorites array. Use with `@Query private var favorites: [FavoriteExercise]` for reactive UI.
    static func isFavorite(
        type: ExerciseType,
        exerciseId: UUID? = nil,
        identifier: String? = nil,
        in favorites: [FavoriteExercise]
    ) -> Bool {
        favorites.contains { favorite in
            favorite.matches(exerciseType: type, exerciseId: exerciseId, exerciseIdentifier: identifier)
        }
    }
    
    // MARK: - Private
    
    private static func fetchAll(context: ModelContext) throws -> [FavoriteExercise] {
        let descriptor = FetchDescriptor<FavoriteExercise>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }
}
