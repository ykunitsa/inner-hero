import Foundation

// MARK: - GroundingType

enum GroundingType: String, Codable {
    case fiveFourThreeTwoOne
}

// MARK: - GroundingExercise

struct GroundingExercise: Identifiable {
    let id = UUID()
    let type: GroundingType
    let name: String
    let description: String
    let icon: String
    let estimatedDuration: TimeInterval
    
    static let predefinedExercises: [GroundingExercise] = [
        GroundingExercise(
            type: .fiveFourThreeTwoOne,
            name: "5-4-3-2-1",
            description: "Техника заземления: перенесите внимание на 5 вещей, которые видите, 4 — которые можете потрогать, 3 — которые слышите, 2 — которые чувствуете на запах, и 1 — на вкус.",
            icon: "brain.head.profile",
            estimatedDuration: 120
        )
    ]
}


