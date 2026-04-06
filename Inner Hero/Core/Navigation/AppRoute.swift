import Foundation

// MARK: - App Route

/// Centralized navigation routes. All associated types are Hashable for use with NavigationPath.
enum AppRoute: Hashable {
    case exposureDetail(exposureId: UUID)
    case exposureSession(sessionId: UUID)
    case breathingDetail(patternType: BreathingPatternType)
    case breathingSession(patternType: BreathingPatternType)
    case relaxationDetail(relaxationType: RelaxationType)
    case relaxationSession(relaxationType: RelaxationType)
    case groundingSession(groundingType: GroundingType)
    case baMain
    case baActiveSession(sessionId: UUID)
    case sessionHistory(exposureId: UUID)
    case sessionDetail(sessionId: UUID)
    case articleDetail(articleId: String)
    case settingsAppearance
    case settingsPrivacy
    case settingsData
    case settingsAbout
    case exerciseList(ExerciseListRoute)
    case plannedSession(assignmentId: UUID)
    case editExposure(exposureId: UUID)
    case exerciseSchedule
    case groundingDetail(groundingType: GroundingType)
    case sessionHistoryBreathing(patternType: BreathingPatternType)
    case sessionHistoryGrounding(groundingType: GroundingType)
}

// MARK: - Exercise List Route

enum ExerciseListRoute: String, Hashable {
    case exposures
    case breathing
    case relaxation
    case grounding
    case activation
}
