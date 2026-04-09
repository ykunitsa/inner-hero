import SwiftUI
import SwiftData

struct PlannedSessionLauncherView: View {
    @Query(sort: \ExerciseAssignment.time) private var allAssignments: [ExerciseAssignment]
    @Query(sort: \Exposure.title) private var exposures: [Exposure]
    
    let assignmentId: UUID
    
    @State private var exposureToStart: Exposure?
    @State private var currentExposureSession: ExposureSessionResult?
    
    private var assignment: ExerciseAssignment? {
        allAssignments.first(where: { $0.id == assignmentId })
    }
    
    var body: some View {
        Group {
            if let assignment {
                destination(for: assignment)
            } else {
                ContentUnavailableView(
                    String(localized: "Assignment not found"),
                    systemImage: "exclamationmark.triangle",
                    description: Text(String(localized: "The schedule may have been removed or changed."))
                )
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    
    @ViewBuilder
    private func destination(for assignment: ExerciseAssignment) -> some View {
        switch assignment.exerciseType {
        case .breathing:
            if let type = assignment.breathingPattern,
               let pattern = BreathingPattern.predefinedPatterns.first(where: { $0.type == type }) {
                BreathingSessionView(pattern: pattern, assignment: assignment)
            } else {
                missingDestinationView
            }
            
        case .grounding:
            if let type = assignment.grounding,
               let exercise = GroundingExercise.predefinedExercises.first(where: { $0.type == type }) {
                GroundingSessionView(exercise: exercise, assignment: assignment)
            } else {
                missingDestinationView
            }
            
        case .relaxation:
            if let type = assignment.relaxation,
               let exercise = RelaxationExercise.predefinedExercises.first(where: { $0.type == type }) {
                MuscleRelaxationSessionView(exercise: exercise, assignment: assignment)
            } else {
                missingDestinationView
            }
            
        case .behavioralActivation:
            BehavioralActivationRootView()
            
        case .exposure:
            if let id = assignment.exposureId,
               let exposure = exposures.first(where: { $0.id == id }) {
                exposureFlow(exposure: exposure, assignment: assignment)
            } else {
                missingDestinationView
            }
        }
    }
    
    private var missingDestinationView: some View {
        ContentUnavailableView(
            String(localized: "Exercise unavailable"),
            systemImage: "questionmark.circle",
            description: Text(String(localized: "Could not find data to start the exercise."))
        )
        .padding()
    }
    
    @ViewBuilder
    private func exposureFlow(exposure: Exposure, assignment: ExerciseAssignment) -> some View {
        ExposureDetailView(
            exposure: exposure,
            onStartSession: {
                exposureToStart = exposure
            }
        )
        .sheet(item: $exposureToStart) { item in
            StartSessionSheet(exposure: item) { session in
                currentExposureSession = session
            }
        }
        .navigationDestination(item: $currentExposureSession) { session in
            if let exposure = session.exposure {
                ActiveSessionView(session: session, exposure: exposure, assignment: assignment)
            }
        }
    }
}

