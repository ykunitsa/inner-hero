import Foundation
import SwiftData

// MARK: - FavoriteExercise Model

@Model
final class FavoriteExercise {
    @Attribute(.unique) var id: UUID
    var exerciseType: ExerciseType
    var exerciseId: UUID?
    var exerciseIdentifier: String?
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        exerciseType: ExerciseType,
        exerciseId: UUID? = nil,
        exerciseIdentifier: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.exerciseType = exerciseType
        self.exerciseId = exerciseId
        self.exerciseIdentifier = exerciseIdentifier
        self.createdAt = createdAt
    }
    
    // MARK: - Helper Methods
    
    func matches(exerciseType: ExerciseType, exerciseId: UUID? = nil, exerciseIdentifier: String? = nil) -> Bool {
        guard self.exerciseType == exerciseType else { return false }
        
        if let exerciseId = exerciseId, let selfExerciseId = self.exerciseId {
            return exerciseId == selfExerciseId
        }
        
        if let exerciseIdentifier = exerciseIdentifier, let selfIdentifier = self.exerciseIdentifier {
            return exerciseIdentifier == selfIdentifier
        }
        
        return false
    }
}


