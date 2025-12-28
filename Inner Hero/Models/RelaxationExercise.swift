import Foundation

// MARK: - RelaxationExercise Model

struct RelaxationExercise: Identifiable {
    let id = UUID()
    let type: RelaxationType
    let name: String
    let description: String
    let icon: String
    let duration: TimeInterval
    
    static let predefinedExercises: [RelaxationExercise] = [
        RelaxationExercise(
            type: .fullBody,
            name: "Full Body Relaxation",
            description: "Complete progressive muscle relaxation sequence targeting all major muscle groups. Releases deep tension throughout the body.",
            icon: "figure.mind.and.body",
            duration: 900 // 15 minutes
        ),
        RelaxationExercise(
            type: .short,
            name: "Quick Relaxation",
            description: "Shortened progressive muscle relaxation focusing on key tension areas. Perfect for quick stress relief during the day.",
            icon: "figure.stand",
            duration: 300 // 5 minutes
        )
    ]
}

