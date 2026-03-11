import SwiftUI
import SwiftData
import Foundation

// MARK: - MuscleRelaxationSessionView

struct MuscleRelaxationSessionView: View {
    let exercise: RelaxationExercise
    let assignment: ExerciseAssignment?
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var timer = StepTimerController()
    @State private var currentStepIndex = 0
    @State private var sessionStartTime = Date()
    @State private var isAnimating = false
    @State private var showingFinishConfirmation = false
    @State private var showingCongratsSheet = false
    @State private var shouldDismissAfterCongrats = false
    
    @State private var sessionPhase: SessionPhase = .readingInstruction
    @State private var didHandlePhaseCompletion = false
    
    @State private var relaxationPulseTimer: Timer?
    @State private var readingPhaseTask: Task<Void, Never>?
    
    init(exercise: RelaxationExercise, assignment: ExerciseAssignment? = nil) {
        self.exercise = exercise
        self.assignment = assignment
    }
    
    private enum SessionPhase: Hashable {
        case readingInstruction
        case runningStep
    }
    
    private var muscleGroups: [MuscleGroup] {
        MuscleGroup.groups(for: exercise.type)
    }
    
    private var currentStep: MuscleGroup {
        muscleGroups[currentStepIndex]
    }
    
    private var isLastStep: Bool {
        currentStepIndex == muscleGroups.count - 1
    }
    
    private var currentPhaseDuration: TimeInterval {
        switch sessionPhase {
        case .readingInstruction:
            return readingDuration(for: currentStep)
        case .runningStep:
            return currentStep.duration
        }
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color.mint.opacity(0.1),
                    Color.green.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: Spacing.md) {
                // Muscle group name with progress
                VStack(spacing: Spacing.xs) {
                    Text(localizedStepName(currentStep))
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(TextColors.primary)
                        .multilineTextAlignment(.center)
                    
                    // Progress indicator
                    HStack(spacing: Spacing.xs) {
                        Text("Step \(currentStepIndex + 1) of \(muscleGroups.count)")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(TextColors.tertiary)
                        
                        Spacer()
                        
                        Text(formattedTotalDuration)
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(TextColors.tertiary)
                    }
                    
                    ProgressView(value: Double(currentStepIndex + 1), total: Double(muscleGroups.count))
                        .tint(.mint)
                }
                .padding(.horizontal)
                .padding(.top, Spacing.sm)
                
                Spacer()
                
                // Muscle animation
                ZStack {
                    // Animated circle representing muscle tension/relaxation
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.mint.opacity(isAnimating ? 0.7 : 0.4),
                                    Color.green.opacity(isAnimating ? 0.5 : 0.2)
                                ],
                                center: .center,
                                startRadius: 20,
                                endRadius: 100
                            )
                        )
                        .frame(width: 160, height: 160)
                        .scaleEffect(isAnimating ? 1.2 : 0.9)
                        .shadow(color: .mint.opacity(0.3), radius: isAnimating ? 25 : 15)
                    
                    // Phase overlay - use phase icons (bolt/leaf)
                    Image(systemName: currentStep.phase == .tension ? "bolt.fill" : "leaf.fill")
                        .font(.system(size: 46, weight: .semibold))
                        .foregroundStyle(.white)
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                }
                
                Group {
                    switch sessionPhase {
                    case .readingInstruction:
                        Text(localizedStepInstruction(currentStep))
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(TextColors.primary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(6)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 24)
                            .contentTransition(.opacity)
                            .animation(.easeInOut(duration: 0.2), value: currentStepIndex)
                    case .runningStep:
                // Timer countdown
                VStack(spacing: Spacing.xxs) {
                            Text(phaseTitle(for: currentStep.phase))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(currentStep.phase == .tension ? Color.orange : Color.mint)
                    
                    Text(formattedRemainingTime)
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(TextColors.primary)
                        }
                    }
                }
                
                Spacer()
                
                if sessionPhase == .runningStep {
                    // Instruction card (shown after the 5-second reading phase)
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack {
                        Image(systemName: "text.bubble")
                            .font(.body)
                            .foregroundStyle(.mint)
                        
                            Text("Instruction")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(TextColors.primary)
                    }
                    
                        Text(localizedStepInstruction(currentStep))
                        .font(.subheadline)
                        .foregroundStyle(TextColors.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .cardStyle(padding: Spacing.md)
                .padding(.horizontal)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    cleanupSession()
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.headline.weight(.semibold))
                }
                .accessibilityLabel("Sign out")
                .tint(.mint)
            }
            
            ToolbarItemGroup(placement: .bottomBar) {
                Button {
                    Task { @MainActor in
                        togglePlayPause()
                    }
                } label: {
                    Label(
                        timer.isRunning && !timer.isPaused ? "Pause" : "Start",
                        systemImage: timer.isRunning && !timer.isPaused ? "pause.fill" : "play.fill"
                    )
                }
                .tint(.mint)
                .accessibilityLabel(timer.isRunning && !timer.isPaused ? "Pause" : "Start")
                .disabled(sessionPhase == .readingInstruction)
                
                Spacer()
                
                Button {
                    showingFinishConfirmation = true
                } label: {
                    Label("Finish", systemImage: "flag.checkered")
                }
                .tint(.mint)
                .accessibilityLabel("Finish")
            }
        }
        .onAppear {
            sessionStartTime = Date()
            startReadingPhase()
        }
        .onDisappear {
            cleanupSession()
        }
        .onChange(of: timer.elapsedTime) { _, _ in
            handlePhaseCompletionIfNeeded()
        }
        .alert("End session?", isPresented: $showingFinishConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Finish") {
                finishSession()
            }
        } message: {
            Text("Are you sure you want to end the muscle relaxation session?")
        }
        .sheet(isPresented: $showingCongratsSheet, onDismiss: {
            guard shouldDismissAfterCongrats else { return }
            shouldDismissAfterCongrats = false
            dismiss()
        }) {
            RelaxationCongratsSessionModal(
                onDone: {
                    shouldDismissAfterCongrats = true
                    showingCongratsSheet = false
                }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
    
    // MARK: - Helper Properties
    
    private var formattedRemainingTime: String {
        let remaining = timer.remainingTime(for: currentPhaseDuration)
        let seconds = Int(ceil(remaining))
        return "\(seconds)"
    }
    
    private var formattedTotalDuration: String {
        let elapsed = Date().timeIntervalSince(sessionStartTime)
        let minutes = Int(elapsed) / 60
        let seconds = Int(elapsed) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    // MARK: - Actions
    
    private func startReadingPhase() {
        readingPhaseTask?.cancel()
        readingPhaseTask = nil
        
        didHandlePhaseCompletion = false
        sessionPhase = .readingInstruction
        stopRelaxationPulse()
        
        // Do not use the StepTimerController for this phase, so we can guarantee a strict 5s.
        timer.stop()
        timer.reset()
        
        // Keep the visual calm during the reading phase.
        withAnimation(.easeInOut(duration: 0.2)) {
            isAnimating = false
        }
        
        // Deterministic 5-second reading phase.
        readingPhaseTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(5))
            guard !Task.isCancelled else { return }
            guard sessionPhase == .readingInstruction else { return }
            startRunningPhase()
        }
    }
    
    private func startRunningPhase() {
        readingPhaseTask?.cancel()
        readingPhaseTask = nil
        
        didHandlePhaseCompletion = false
        sessionPhase = .runningStep
        
        timer.reset()
        timer.start()
        
        startAnimation()
        HapticFeedback.impact(.medium)
    }
    
    private func startAnimation() {
        stopRelaxationPulse()
        
        // Initial state based on phase
        isAnimating = currentStep.phase == .relaxation
        
        // Animate based on phase
        if currentStep.phase == .tension {
            // Tension: start relaxed, then tense
            withAnimation(.easeIn(duration: 1.5).delay(0.5)) {
                isAnimating = true
            }
        } else {
            // Relaxation: start tense, then relax with breathing rhythm
            withAnimation(.easeOut(duration: 2.0)) {
                isAnimating = false
            }
            
            // Add gentle breathing animation (ensure the timer is invalidated between steps)
            relaxationPulseTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
                Task { @MainActor in
                    guard sessionPhase == .runningStep else { return }
                    withAnimation(.easeInOut(duration: 3.0)) {
                        isAnimating.toggle()
                    }
                }
            }
        }
    }
    
    private func finishSession() {
        cleanupSession()
        
        let totalDuration = Date().timeIntervalSince(sessionStartTime)
        
        // Save session result
        let dataManager = DataManager(modelContext: modelContext)
        do {
            try dataManager.createRelaxationSessionResult(
                type: exercise.type,
                duration: totalDuration
            )
            
            if let assignment {
                try dataManager.markAssignmentCompletedIfNeeded(assignment: assignment)
            }
            
            HapticFeedback.success()
        } catch {
            print("Error saving relaxation session: \(error)")
            HapticFeedback.error()
        }
        
        showingCongratsSheet = true
    }
    
    private func finishSessionAutomaticallyIfLastStep() {
        guard isLastStep else { return }
        finishSession()
    }
    
    private func cleanupSession() {
        readingPhaseTask?.cancel()
        readingPhaseTask = nil
        
        timer.stop()
        stopRelaxationPulse()
    }
    
    private func stopRelaxationPulse() {
        relaxationPulseTimer?.invalidate()
        relaxationPulseTimer = nil
    }
    
    private func handlePhaseCompletionIfNeeded() {
        guard timer.isRunning, !timer.isPaused else { return }
        guard !didHandlePhaseCompletion else { return }
        guard timer.isExpired(for: currentPhaseDuration) else { return }
        
        didHandlePhaseCompletion = true
        timer.stop()
        
        switch sessionPhase {
        case .readingInstruction:
            // Reading phase is handled by a dedicated 5-second Task.
            return
        case .runningStep:
            if isLastStep {
                finishSessionAutomaticallyIfLastStep()
            } else {
                withAnimation(.easeInOut(duration: 0.25)) {
                    currentStepIndex += 1
                }
                HapticFeedback.selection()
                startReadingPhase()
            }
        }
    }
    
    private func togglePlayPause() {
        guard sessionPhase == .runningStep else { return }
        
        if timer.isRunning && !timer.isPaused {
            timer.pause()
        } else if timer.isPaused {
            timer.resume()
        } else {
            timer.start()
        }
    }
    
    /// The reading phase lasts **at least 5 seconds**, and automatically extends for longer instructions.
    /// This keeps the UX consistent while making it realistically readable.
    private func readingDuration(for step: MuscleGroup) -> TimeInterval {
        let text = localizedStepInstruction(step)
        let words = text
            .split(whereSeparator: { $0.isWhitespace || $0.isNewline })
            .count
        
        // ~2.2 words/sec is a comfortable reading speed on mobile.
        let estimated = Double(words) / 2.2
        
        // Clamp to keep the app feeling snappy, but still readable.
        return max(5, min(12, ceil(estimated)))
    }
    
    private func phaseTitle(for phase: MuscleGroup.Phase) -> String {
        switch phase {
        case .tension:
            return String(localized: "Tense")
        case .relaxation:
            return String(localized: "Relax")
        }
    }
    
    private func localizedStepName(_ step: MuscleGroup) -> String {
        switch step.name {
        case "Hands & Forearms":
            return String(localized: "Hands & Forearms")
        case "Upper Arms":
            return String(localized: "Upper Arms")
        case "Shoulders":
            return String(localized: "Shoulders")
        case "Face & Jaw":
            return String(localized: "Face & Jaw")
        case "Chest & Back":
            return String(localized: "Chest & Back")
        case "Stomach":
            return String(localized: "Stomach")
        case "Legs & Thighs":
            return String(localized: "Legs & Thighs")
        case "Feet & Calves":
            return String(localized: "Feet & Calves")
        case "Upper Body":
            return String(localized: "Upper Body")
        case "Face":
            return String(localized: "Face")
        case "Core":
            return String(localized: "Core")
        case "Lower Body":
            return String(localized: "Lower Body")
        default:
            return step.name
        }
    }
    
    private func localizedStepInstruction(_ step: MuscleGroup) -> String {
        switch (step.name, step.phase) {
        case ("Hands & Forearms", .tension):
            return String(localized: "Clench both hands into fists. Feel the tension in your hands and forearms.")
        case ("Hands & Forearms", .relaxation):
            return String(localized: "Unclench your fists. Fully relax your arms and notice the difference between tension and relaxation.")
            
        case ("Upper Arms", .tension):
            return String(localized: "Bend your arms and tense your biceps. Squeeze as much as is comfortable.")
        case ("Upper Arms", .relaxation):
            return String(localized: "Lower your arms and relax them. Feel the tension leave your upper arms.")
            
        case ("Shoulders", .tension):
            return String(localized: "Raise your shoulders toward your ears. Hold and feel the tension.")
        case ("Shoulders", .relaxation):
            return String(localized: "Lower your shoulders to a natural position. Let them feel heavy and relaxed.")
            
        case ("Face & Jaw", .tension):
            return String(localized: "Scrunch your face: squeeze your eyes shut and clench your jaw.")
        case ("Face & Jaw", .relaxation):
            return String(localized: "Release the tension in your face. Relax your jaw and eyes.")
            
        case ("Chest & Back", .tension):
            return String(localized: "Take a deep breath and pull your shoulders back. Slightly arch your back.")
        case ("Chest & Back", .relaxation):
            return String(localized: "Exhale and relax your chest and back. Breathe calmly and naturally.")
            
        case ("Stomach", .tension):
            return String(localized: "Tense your stomach muscles. Make your belly firm.")
        case ("Stomach", .relaxation):
            return String(localized: "Relax your stomach muscles. Let your belly go soft.")
            
        case ("Legs & Thighs", .tension):
            return String(localized: "Tense your thigh muscles. Straighten your legs and make them stiff.")
        case ("Legs & Thighs", .relaxation):
            return String(localized: "Fully relax your legs. Feel them become heavy and loose.")
            
        case ("Feet & Calves", .tension):
            return String(localized: "Point your toes down and tense your calves and feet.")
        case ("Feet & Calves", .relaxation):
            return String(localized: "Release the tension in your feet and calves. Let them relax naturally.")
            
        case ("Upper Body", .tension):
            return String(localized: "Clench your fists, tense your arms, and raise your shoulders. Hold the overall tension.")
        case ("Upper Body", .relaxation):
            return String(localized: "Let everything go. Let your arms drop and shoulders relax. Feel the relief.")
            
        case ("Face", .tension):
            return String(localized: "Scrunch your face: squeeze your eyes shut and clench your jaw.")
        case ("Face", .relaxation):
            return String(localized: "Let the tension leave your face. Relax your jaw and eyes.")
            
        case ("Core", .tension):
            return String(localized: "Take a deep breath. Slightly arch your back and tense your stomach.")
        case ("Core", .relaxation):
            return String(localized: "Exhale and release the tension. Let your back and stomach relax.")
            
        case ("Lower Body", .tension):
            return String(localized: "Straighten your legs and point your toes down. Tense your thighs, calves, and feet.")
        case ("Lower Body", .relaxation):
            return String(localized: "Fully relax your legs. Feel them become heavy and calm.")
            
        default:
            return step.instruction
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        MuscleRelaxationSessionView(exercise: RelaxationExercise.predefinedExercises[0])
    }
    .modelContainer(for: [RelaxationSessionResult.self])
}
