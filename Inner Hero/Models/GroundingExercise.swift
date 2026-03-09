import Foundation

// MARK: - GroundingType

enum GroundingType: String, Codable {
    case fiveFourThreeTwoOne
}

// MARK: - GroundingInstructionStep

struct GroundingInstructionStep: Identifiable {
    let id = UUID()
    let number: Int
    let title: String
    let prompt: String
}

// MARK: - GroundingExercise

struct GroundingExercise: Identifiable {
    let id = UUID()
    let type: GroundingType
    let name: String
    let description: String
    let icon: String
    let estimatedDuration: TimeInterval
    
    static var predefinedExercises: [GroundingExercise] {
        [
            GroundingExercise(
                type: .fiveFourThreeTwoOne,
                name: String(localized: "5-4-3-2-1"),
                description: String(
                    localized: "Grounding technique: find 5 things you see, 4 things you touch, 3 sounds, 2 smells (or air sensations), and 1 taste."
                ),
                icon: "brain.head.profile",
                estimatedDuration: 120
            )
        ]
    }
    
    var instructionSteps: [GroundingInstructionStep] {
        switch type {
        case .fiveFourThreeTwoOne:
            return [
                GroundingInstructionStep(
                    number: 5,
                    title: String(localized: "Look around"),
                    prompt: String(localized: "Find 5 objects around you and hold your gaze on each for a second.")
                ),
                GroundingInstructionStep(
                    number: 4,
                    title: String(localized: "Support"),
                    prompt: String(localized: "Find 4 touch sensations: clothes, chair, floor, object in your hands.")
                ),
                GroundingInstructionStep(
                    number: 3,
                    title: String(localized: "Sounds"),
                    prompt: String(localized: "Notice 3 sounds: near, far, and the quietest.")
                ),
                GroundingInstructionStep(
                    number: 2,
                    title: String(localized: "Smells"),
                    prompt: String(localized: "Catch 2 smells or just 2 sensations of the air.")
                ),
                GroundingInstructionStep(
                    number: 1,
                    title: String(localized: "Taste"),
                    prompt: String(localized: "Notice 1 taste in your mouth or take a small sip of water and notice the taste.")
                )
            ]
        }
    }
}


