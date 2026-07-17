import Foundation

// MARK: - RelaxationExercise Model

struct RelaxationExercise: Identifiable {
    let id = UUID()
    let type: RelaxationType
    let name: String
    let description: String
    let icon: String
    let duration: TimeInterval
    
    static var predefinedExercises: [RelaxationExercise] {
        [
            RelaxationExercise(
                type: .fullBody,
                name: String(localized: "Full Body Relaxation"),
                description: String(
                    localized: "Full sequence of progressive muscle relaxation for all major muscle groups. Helps release deep tension throughout the body."
                ),
                icon: "figure.mind.and.body",
                duration: 900 // 15 minutes
            ),
            RelaxationExercise(
                type: .short,
                name: String(localized: "Quick Relaxation"),
                description: String(
                    localized: "Short version of progressive muscle relaxation focusing on key tension areas. Good for quick stress relief during the day."
                ),
                icon: "figure.stand",
                duration: 300 // 5 minutes
            )
        ]
    }
}

