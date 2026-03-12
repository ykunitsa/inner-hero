import Foundation

extension ExerciseAssignment {

    // MARK: - Display

    /// Full display title with type prefix (e.g. "Exposure: Public speaking", "Breathing: Box Breathing").
    /// Use empty arrays when exposures/activityLists are not available (e.g. notifications).
    func displayTitle(exposures: [Exposure], activityLists: [ActivityList]) -> String {
        switch exerciseType {
        case .exposure:
            if let id = exposureId,
               let exposure = exposures.first(where: { $0.id == id }) {
                return String(format: NSLocalizedString("Exposure: %@", comment: ""), exposure.localizedTitle)
            }
            return String(localized: "Exposure")

        case .breathing:
            if let type = breathingPattern {
                let name = BreathingPattern.predefinedPatterns.first(where: { $0.type == type })?.name ?? type.rawValue
                return String(format: NSLocalizedString("Breathing: %@", comment: ""), name)
            }
            return String(localized: "Breathing")

        case .relaxation:
            if let type = relaxation {
                let name = RelaxationExercise.predefinedExercises.first(where: { $0.type == type })?.name ?? type.rawValue
                return String(format: NSLocalizedString("Relaxation: %@", comment: ""), name)
            }
            return String(localized: "Relaxation")

        case .grounding:
            if let type = grounding {
                let name = GroundingExercise.predefinedExercises.first(where: { $0.type == type })?.name ?? type.rawValue
                return String(format: NSLocalizedString("Grounding: %@", comment: ""), name)
            }
            return String(localized: "Grounding")

        case .behavioralActivation:
            if let id = activityListId,
               let list = activityLists.first(where: { $0.id == id }) {
                return String(format: NSLocalizedString("Activation: %@", comment: ""), list.localizedTitle)
            }
            return String(localized: "Behavioral activation")
        }
    }

    /// Subtitle for schedule context (e.g. "Mon, Wed, Fri" or "Every day").
    func displaySubtitle() -> String {
        getDayNamesString()
    }

    /// SF Symbol name for the exercise type.
    var displayIcon: String {
        switch exerciseType {
        case .exposure:
            return "leaf.circle.fill"
        case .breathing:
            return "wind"
        case .relaxation:
            return "figure.mind.and.body"
        case .grounding:
            return "brain.head.profile"
        case .behavioralActivation:
            return "figure.walk"
        }
    }
}
