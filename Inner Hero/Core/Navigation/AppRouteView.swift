import SwiftUI
import SwiftData

// MARK: - App Route View

struct AppRouteView: View {
    let route: AppRoute

    @Environment(\.modelContext) private var modelContext
    @Environment(ArticlesStore.self) private var articlesStore

    @State private var exposureDetailStartSheet: Exposure?
    @State private var exposureDetailActiveSession: ExposureSessionResult?

    @Query(sort: \Exposure.title) private var exposures: [Exposure]
    @Query(sort: \ActivityList.title) private var activityLists: [ActivityList]
    @Query(sort: \ExerciseAssignment.time) private var allAssignments: [ExerciseAssignment]
    @Query(sort: \ExposureSessionResult.startAt, order: .reverse) private var allSessions: [ExposureSessionResult]

    var body: some View {
        routeContent
    }

    @ViewBuilder
    private var routeContent: some View {
        switch route {
        case .exposureDetail(let exposureId):
            if let exposure = exposures.first(where: { $0.id == exposureId }) {
                ExposureDetailView(
                    exposure: exposure,
                    onStartSession: { exposureDetailStartSheet = exposure }
                )
                .sheet(item: $exposureDetailStartSheet) { exp in
                    StartSessionSheet(exposure: exp) { session in
                        exposureDetailActiveSession = session
                    }
                }
                .navigationDestination(item: $exposureDetailActiveSession) { session in
                    if let exposure = session.exposure {
                        ActiveSessionView(session: session, exposure: exposure, assignment: nil)
                    }
                }
            } else {
                contentUnavailable(route: "Exposure")
            }

        case .exposureSession(let sessionId):
            if let session = allSessions.first(where: { $0.id == sessionId }),
               let exposure = session.exposure {
                ActiveSessionView(session: session, exposure: exposure, assignment: nil)
            } else {
                contentUnavailable(route: "Session")
            }

        case .breathingDetail(let patternType):
            if let pattern = BreathingPattern.predefinedPatterns.first(where: { $0.type == patternType }) {
                BreathingPatternDetailView(pattern: pattern)
            } else {
                contentUnavailable(route: "Breathing")
            }

        case .breathingSession(let patternType):
            if let pattern = BreathingPattern.predefinedPatterns.first(where: { $0.type == patternType }) {
                BreathingSessionView(pattern: pattern)
            } else {
                contentUnavailable(route: "Breathing")
            }

        case .relaxationDetail(let relaxationType):
            if let exercise = RelaxationExercise.predefinedExercises.first(where: { $0.type == relaxationType }) {
                RelaxationExerciseDetailView(exercise: exercise)
            } else {
                contentUnavailable(route: "Relaxation")
            }

        case .relaxationSession(let relaxationType):
            if let exercise = RelaxationExercise.predefinedExercises.first(where: { $0.type == relaxationType }) {
                MuscleRelaxationSessionView(exercise: exercise)
            } else {
                contentUnavailable(route: "Relaxation")
            }

        case .groundingSession(let groundingType):
            if let exercise = GroundingExercise.predefinedExercises.first(where: { $0.type == groundingType }) {
                GroundingSessionView(exercise: exercise)
            } else {
                contentUnavailable(route: "Grounding")
            }

        case .activationView(let activityListId, let assignmentId):
            if let activation = activityLists.first(where: { $0.id == activityListId }) {
                let assignment = assignmentId.flatMap { id in allAssignments.first(where: { $0.id == id }) }
                ActivationDetailView(activation: activation, assignment: assignment)
            } else {
                contentUnavailable(route: "Activation")
            }

        case .sessionHistory(let exposureId):
            if let exposure = exposures.first(where: { $0.id == exposureId }) {
                SessionHistoryView(exposure: exposure)
            } else {
                contentUnavailable(route: "History")
            }

        case .sessionDetail(let sessionId):
            if let session = allSessions.first(where: { $0.id == sessionId }) {
                SessionDetailView(session: session)
            } else {
                contentUnavailable(route: "Session")
            }

        case .articleDetail(let articleId):
            if let article = articlesStore.allArticles.first(where: { $0.id == articleId }) {
                ArticleDetailView(article: article)
            } else {
                contentUnavailable(route: "Article")
            }

        case .settingsAppearance:
            AppearanceSettingsView()

        case .settingsPrivacy:
            PrivacySettingsView()

        case .settingsData:
            DataSettingsView()

        case .settingsAbout:
            AboutView()

        case .exerciseList(let listRoute):
            exerciseListView(for: listRoute)

        case .plannedSession(let assignmentId):
            PlannedSessionLauncherView(assignmentId: assignmentId)

        case .editExposure(let exposureId):
            if let exposure = exposures.first(where: { $0.id == exposureId }) {
                EditExposureView(exposure: exposure)
            } else {
                contentUnavailable(route: "Exposure")
            }

        case .exerciseSchedule:
            ExerciseScheduleView()

        case .groundingDetail(let groundingType):
            if let exercise = GroundingExercise.predefinedExercises.first(where: { $0.type == groundingType }) {
                GroundingExerciseDetailView(exercise: exercise)
            } else {
                contentUnavailable(route: "Grounding")
            }

        case .sessionHistoryBreathing(let patternType):
            let title = BreathingPattern.predefinedPatterns.first(where: { $0.type == patternType })?.localizedName ?? patternType.rawValue
            BreathingSessionHistoryView(patternType: patternType, title: title)

        case .sessionHistoryGrounding(let groundingType):
            let title = GroundingExercise.predefinedExercises.first(where: { $0.type == groundingType })?.name ?? groundingType.rawValue
            GroundingSessionHistoryView(type: groundingType, title: title)
        }
    }

    @ViewBuilder
    private func exerciseListView(for listRoute: ExerciseListRoute) -> some View {
        switch listRoute {
            case .exposures: ExposuresListView()
            case .breathing: BreathingExercisesView()
            case .relaxation: MuscleRelaxationListView()
            case .grounding: GroundingExercisesView()
            case .activation: BAMainView()
        }
    }

    private func contentUnavailable(route: String) -> some View {
        ContentUnavailableView(
            String(localized: "\(route) not found"),
            systemImage: "questionmark.circle",
            description: Text(String(localized: "The item may have been removed or is unavailable."))
        )
        .padding()
    }
}
