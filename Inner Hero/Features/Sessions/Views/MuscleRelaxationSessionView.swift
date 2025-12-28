import SwiftUI
import SwiftData

// MARK: - MuscleRelaxationSessionView

struct MuscleRelaxationSessionView: View {
    let exercise: RelaxationExercise
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var timer = StepTimerController()
    @State private var currentStepIndex = 0
    @State private var sessionStartTime = Date()
    @State private var isAnimating = false
    @State private var showingFinishAlert = false
    
    private var muscleGroups: [MuscleGroup] {
        MuscleGroup.groups(for: exercise.type)
    }
    
    private var currentStep: MuscleGroup {
        muscleGroups[currentStepIndex]
    }
    
    private var isLastStep: Bool {
        currentStepIndex == muscleGroups.count - 1
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
                    Text(currentStep.name)
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
                    
                    // Phase overlay - muscle icon
                    Image(systemName: currentStep.icon)
                        .font(.system(size: 50))
                        .foregroundStyle(.white)
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                }
                
                // Timer countdown
                VStack(spacing: Spacing.xxs) {
                    Text(currentStep.phase == .tension ? "Tense" : "Relax")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(currentStep.phase == .tension ? Color.orange : Color.mint)
                    
                    Text(formattedRemainingTime)
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(TextColors.primary)
                }
                
                Spacer()
                
                // Instruction card
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack {
                        Image(systemName: "text.bubble")
                            .font(.body)
                            .foregroundStyle(.mint)
                        
                        Text("Instructions")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(TextColors.primary)
                    }
                    
                    Text(currentStep.instruction)
                        .font(.subheadline)
                        .foregroundStyle(TextColors.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .cardStyle(padding: Spacing.md)
                .padding(.horizontal)
                
                // Next button
                Button {
                    handleNextButton()
                } label: {
                    Text(isLastStep ? "Finish" : "Next")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                                .fill(isLastStep ? Color.green : Color.mint)
                        )
                }
                .padding(.horizontal)
                .padding(.bottom, Spacing.xs)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            sessionStartTime = Date()
            startCurrentStep()
        }
        .onDisappear {
            timer.stop()
        }
        .alert("Finish Session?", isPresented: $showingFinishAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Finish") {
                finishSession()
            }
        } message: {
            Text("Are you sure you want to finish this relaxation session?")
        }
    }
    
    // MARK: - Helper Properties
    
    private var formattedRemainingTime: String {
        let remaining = timer.remainingTime(for: currentStep.duration)
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
    
    private func startCurrentStep() {
        timer.reset()
        timer.start()
        startAnimation()
        
        #if canImport(UIKit)
        HapticFeedback.impact(.medium)
        #endif
    }
    
    private func startAnimation() {
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
            
            // Add gentle breathing animation
            Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
                guard currentStepIndex < muscleGroups.count else { return }
                withAnimation(.easeInOut(duration: 3.0)) {
                    isAnimating.toggle()
                }
            }
        }
    }
    
    private func handleNextButton() {
        if isLastStep {
            showingFinishAlert = true
        } else {
            moveToNextStep()
        }
    }
    
    private func moveToNextStep() {
        timer.stop()
        
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStepIndex += 1
        }
        
        #if canImport(UIKit)
        HapticFeedback.selection()
        #endif
        
        // Small delay before starting next step
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            startCurrentStep()
        }
    }
    
    private func finishSession() {
        timer.stop()
        
        let totalDuration = Date().timeIntervalSince(sessionStartTime)
        
        // Save session result
        let dataManager = DataManager(modelContext: modelContext)
        do {
            try dataManager.createRelaxationSessionResult(
                type: exercise.type,
                duration: totalDuration
            )
            
            #if canImport(UIKit)
            HapticFeedback.success()
            #endif
        } catch {
            print("Error saving relaxation session: \(error)")
            #if canImport(UIKit)
            HapticFeedback.error()
            #endif
        }
        
        dismiss()
    }
}

// MARK: - MuscleGroup Model

private struct MuscleGroup {
    let name: String
    let instruction: String
    let icon: String
    let duration: TimeInterval
    let phase: Phase
    
    enum Phase {
        case tension
        case relaxation
    }
    
    static func groups(for type: RelaxationType) -> [MuscleGroup] {
        switch type {
        case .fullBody:
            return fullBodySequence
        case .short:
            return shortSequence
        }
    }
    
    private static let fullBodySequence: [MuscleGroup] = [
        // Hands and forearms
        MuscleGroup(
            name: "Hands & Forearms",
            instruction: "Make tight fists with both hands. Feel the tension in your hands and forearms.",
            icon: "hand.raised.fill",
            duration: 7,
            phase: .tension
        ),
        MuscleGroup(
            name: "Hands & Forearms",
            instruction: "Release your fists. Let your hands relax completely. Notice the difference between tension and relaxation.",
            icon: "hand.raised.fill",
            duration: 15,
            phase: .relaxation
        ),
        
        // Upper arms
        MuscleGroup(
            name: "Upper Arms",
            instruction: "Bend your arms and tense your biceps. Make them as tight as possible.",
            icon: "figure.strengthtraining.traditional",
            duration: 7,
            phase: .tension
        ),
        MuscleGroup(
            name: "Upper Arms",
            instruction: "Let your arms drop and relax. Feel the tension flowing away from your upper arms.",
            icon: "figure.strengthtraining.traditional",
            duration: 15,
            phase: .relaxation
        ),
        
        // Shoulders
        MuscleGroup(
            name: "Shoulders",
            instruction: "Raise your shoulders up toward your ears. Hold them high and feel the tension.",
            icon: "figure.arms.open",
            duration: 7,
            phase: .tension
        ),
        MuscleGroup(
            name: "Shoulders",
            instruction: "Let your shoulders drop down naturally. Feel them becoming heavy and relaxed.",
            icon: "figure.arms.open",
            duration: 15,
            phase: .relaxation
        ),
        
        // Face and jaw
        MuscleGroup(
            name: "Face & Jaw",
            instruction: "Scrunch up your face. Squeeze your eyes shut and clench your jaw tightly.",
            icon: "face.smiling",
            duration: 7,
            phase: .tension
        ),
        MuscleGroup(
            name: "Face & Jaw",
            instruction: "Release all tension from your face. Let your jaw drop slightly and relax your eyes.",
            icon: "face.smiling",
            duration: 15,
            phase: .relaxation
        ),
        
        // Chest and back
        MuscleGroup(
            name: "Chest & Back",
            instruction: "Take a deep breath and pull your shoulders back. Arch your back slightly.",
            icon: "lungs.fill",
            duration: 7,
            phase: .tension
        ),
        MuscleGroup(
            name: "Chest & Back",
            instruction: "Exhale and let your chest and back relax completely. Breathe naturally.",
            icon: "lungs.fill",
            duration: 15,
            phase: .relaxation
        ),
        
        // Stomach
        MuscleGroup(
            name: "Stomach",
            instruction: "Tighten your stomach muscles. Make your abdomen hard and tense.",
            icon: "figure.core.training",
            duration: 7,
            phase: .tension
        ),
        MuscleGroup(
            name: "Stomach",
            instruction: "Release your stomach muscles. Let your belly be soft and relaxed.",
            icon: "figure.core.training",
            duration: 15,
            phase: .relaxation
        ),
        
        // Legs
        MuscleGroup(
            name: "Legs & Thighs",
            instruction: "Tighten your thigh muscles. Straighten your legs and make them rigid.",
            icon: "figure.walk",
            duration: 7,
            phase: .tension
        ),
        MuscleGroup(
            name: "Legs & Thighs",
            instruction: "Let your legs relax completely. Feel them becoming heavy and loose.",
            icon: "figure.walk",
            duration: 15,
            phase: .relaxation
        ),
        
        // Feet
        MuscleGroup(
            name: "Feet & Calves",
            instruction: "Point your toes downward and tense your calves and feet.",
            icon: "shoeprints.fill",
            duration: 7,
            phase: .tension
        ),
        MuscleGroup(
            name: "Feet & Calves",
            instruction: "Release all tension from your feet and calves. Let them rest naturally.",
            icon: "shoeprints.fill",
            duration: 15,
            phase: .relaxation
        ),
    ]
    
    private static let shortSequence: [MuscleGroup] = [
        // Combined upper body
        MuscleGroup(
            name: "Upper Body",
            instruction: "Make fists, tense your arms, and raise your shoulders. Hold all this tension.",
            icon: "figure.strengthtraining.traditional",
            duration: 7,
            phase: .tension
        ),
        MuscleGroup(
            name: "Upper Body",
            instruction: "Release everything. Let your arms drop and shoulders fall. Feel the relaxation.",
            icon: "figure.strengthtraining.traditional",
            duration: 15,
            phase: .relaxation
        ),
        
        // Face
        MuscleGroup(
            name: "Face",
            instruction: "Scrunch your face. Squeeze your eyes and clench your jaw.",
            icon: "face.smiling",
            duration: 7,
            phase: .tension
        ),
        MuscleGroup(
            name: "Face",
            instruction: "Let all tension melt away from your face. Relax your jaw and eyes.",
            icon: "face.smiling",
            duration: 15,
            phase: .relaxation
        ),
        
        // Core
        MuscleGroup(
            name: "Core",
            instruction: "Take a deep breath. Arch your back and tighten your stomach.",
            icon: "figure.core.training",
            duration: 7,
            phase: .tension
        ),
        MuscleGroup(
            name: "Core",
            instruction: "Exhale and release. Let your back settle and stomach soften.",
            icon: "figure.core.training",
            duration: 15,
            phase: .relaxation
        ),
        
        // Lower body
        MuscleGroup(
            name: "Lower Body",
            instruction: "Straighten your legs and point your toes. Tense your thighs, calves, and feet.",
            icon: "figure.walk",
            duration: 7,
            phase: .tension
        ),
        MuscleGroup(
            name: "Lower Body",
            instruction: "Let your legs relax completely. Feel them becoming heavy and at ease.",
            icon: "figure.walk",
            duration: 15,
            phase: .relaxation
        ),
    ]
}

// MARK: - Preview

#Preview {
    NavigationStack {
        MuscleRelaxationSessionView(exercise: RelaxationExercise.predefinedExercises[0])
    }
    .modelContainer(for: [RelaxationSessionResult.self])
}
