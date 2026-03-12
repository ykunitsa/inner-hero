import Foundation
import SwiftData

@Observable
@MainActor
final class ActiveSessionViewModel {
    private(set) var session: ExposureSessionResult
    private(set) var steps: [ExposureStep]
    private(set) var assignment: ExerciseAssignment?

    var completedSteps: Set<Int> = []
    var selectedStepIndex: Int? = nil
    var showingCompletion: Bool = false
    var stepTimers: [Int: StepTimerController] = [:]
    var notes: String = ""

    var currentStepIndex: Int {
        if let selected = selectedStepIndex {
            return selected
        }
        for (index, _) in steps.enumerated() {
            if !completedSteps.contains(index) {
                return index
            }
        }
        return max(0, steps.count - 1)
    }

    var allStepsCompleted: Bool {
        completedSteps.count == steps.count
    }

    init(session: ExposureSessionResult, steps: [ExposureStep], assignment: ExerciseAssignment? = nil) {
        self.session = session
        self.steps = steps
        self.assignment = assignment
        var timers: [Int: StepTimerController] = [:]
        for (index, step) in steps.enumerated() {
            if step.hasTimer {
                timers[index] = StepTimerController()
            }
        }
        self.stepTimers = timers
    }

    func setup() {
        completedSteps = Set(session.completedStepIndices)
        for (index, time) in session.stepTimings {
            let timer = timer(for: index)
            timer.setElapsedTime(time)
        }
    }

    func cleanup() {
        for (_, t) in stepTimers {
            t.stop()
        }
    }

    func timer(for index: Int) -> StepTimerController {
        if let existing = stepTimers[index] {
            return existing
        }
        let newTimer = StepTimerController()
        stepTimers[index] = newTimer
        return newTimer
    }

    func toggleStepCompletion(_ index: Int) {
        if completedSteps.contains(index) {
            let indicesToInvalidate = completedSteps.filter { $0 >= index }
            for stepIndex in indicesToInvalidate {
                completedSteps.remove(stepIndex)
                session.markStepIncomplete(stepIndex)
                session.removeStepTime(stepIndex)
                stepTimers[stepIndex]?.reset()
            }
        } else {
            if index == currentStepIndex {
                selectedStepIndex = nil
            }
            completedSteps.insert(index)
            session.markStepCompleted(index)
            stepTimers[index]?.stop()
        }
    }

    func completeCurrentStep() {
        let targetIndex = currentStepIndex
        let isCompleting = !completedSteps.contains(targetIndex)
        toggleStepCompletion(targetIndex)
        selectedStepIndex = isCompleting ? nil : targetIndex
    }

    /// Call when user taps "Finish" on last step: mark last step complete, save progress, set showingCompletion = true.
    func finishSessionUI() {
        selectedStepIndex = nil
        completedSteps.insert(currentStepIndex)
        session.markStepCompleted(currentStepIndex)
        stepTimers[currentStepIndex]?.stop()
        showingCompletion = true
    }

    /// Persist completion (endAt, anxietyAfter, notes) and mark assignment completed. Call from CompleteSessionView on Save.
    func finishSession(anxietyAfter: Int, notes: String, context: ModelContext) async throws {
        session.endAt = Date()
        session.anxietyAfter = anxietyAfter
        session.notes = notes
        try context.save()
        if let assignment {
            try SessionCompletionService.markCompletedIfNeeded(assignmentId: assignment.id, context: context)
        }
    }

    func goToStep(_ index: Int) {
        guard index >= 0, index < steps.count else { return }
        selectedStepIndex = index
    }

    func saveProgress(context: ModelContext) {
        session.completedStepIndices = Array(completedSteps).sorted()
        for (index, t) in stepTimers {
            if t.elapsedTime > 0 {
                session.setStepTime(index, time: t.elapsedTime)
            }
        }
        if !notes.isEmpty {
            session.notes = notes
        }
        try? context.save()
    }
}
