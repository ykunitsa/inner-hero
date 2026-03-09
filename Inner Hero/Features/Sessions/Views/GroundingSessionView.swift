import SwiftUI
import SwiftData

// MARK: - GroundingSessionView

struct GroundingSessionView: View {
    let exercise: GroundingExercise
    let assignment: ExerciseAssignment?
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var sessionStartTime = Date()
    @State private var currentStepIndex = 0
    @State private var showingFinishConfirmation = false
    @State private var showingCongratsSheet = false
    @State private var shouldDismissAfterCongrats = false
    
    init(exercise: GroundingExercise, assignment: ExerciseAssignment? = nil) {
        self.exercise = exercise
        self.assignment = assignment
    }
    
    private var steps: [GroundingInstructionStep] {
        exercise.instructionSteps
    }
    
    private var currentStep: GroundingInstructionStep {
        steps[currentStepIndex]
    }
    
    private var isFirstStep: Bool {
        currentStepIndex == 0
    }
    
    private var isLastStep: Bool {
        currentStepIndex == steps.count - 1
    }
    
    private var stepIconSystemName: String {
        switch currentStep.number {
        case 5:
            return "eye.fill"
        case 4:
            return "hand.raised.fill"
        case 3:
            return "ear.fill"
        case 2:
            if #available(iOS 17.0, *) {
                return "nose.fill"
            } else {
                return "wind"
            }
        case 1:
            if #available(iOS 17.0, *) {
                return "mouth.fill"
            } else {
                return "cup.and.saucer.fill"
            }
        default:
            return "sparkles"
        }
    }
    
    private var congratsConfiguration: CongratsSessionModal.Configuration {
        switch exercise.type {
        case .fiveFourThreeTwoOne:
            return CongratsSessionModal.Configuration(
                palette: .purpleIndigo,
                topIconSystemName: "sparkles",
                title: "Well done!",
                subtitle: "You brought your attention to the present moment—that really helps.",
                messages: [
                    .init(iconSystemName: "eye.circle.fill", text: "If you like, repeat another round—at your own pace."),
                    .init(iconSystemName: "hand.raised.circle.fill", text: "You relied on your senses—that's a skill that strengthens with practice."),
                    .init(iconSystemName: "heart.circle.fill", text: "Even a small step is self-care.")
                ],
                primaryButtonTitle: "Great"
            )
        }
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.purple.opacity(0.10),
                    Color.indigo.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: Spacing.md) {
                VStack(spacing: Spacing.xs) {
                    Text(exercise.name)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(TextColors.primary)
                        .multilineTextAlignment(.center)
                    
                    HStack {
                        Text("Step \(currentStepIndex + 1) of \(steps.count)")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(TextColors.tertiary)
                        
                        Spacer()
                        
                        TimelineView(.periodic(from: sessionStartTime, by: 1)) { context in
                            Text(formatDuration(context.date.timeIntervalSince(sessionStartTime)))
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(TextColors.tertiary)
                        }
                    }
                    
                    ProgressView(value: Double(currentStepIndex + 1), total: Double(steps.count))
                        .tint(.purple)
                }
                .padding(.horizontal)
                .padding(.top, Spacing.sm)
                
                Spacer()
                
                VStack(spacing: Spacing.sm) {
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color.purple.opacity(0.55),
                                        Color.indigo.opacity(0.35)
                                    ],
                                    center: .center,
                                    startRadius: 20,
                                    endRadius: 120
                                )
                            )
                            .frame(width: 180, height: 180)
                            .shadow(color: .purple.opacity(0.25), radius: 18)
                        
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(.white.opacity(0.18))
                                    .frame(width: 50, height: 50)
                                
                                Image(systemName: stepIconSystemName)
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundStyle(.white)
                            }
                            .accessibilityHidden(true)
                            
                            Text("\(currentStep.number)")
                                .font(.system(size: 64, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .accessibilityLabel("Step \(currentStep.number)")
                        }
                    }
                    
                    Text(currentStep.title)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(TextColors.primary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Text(currentStep.prompt)
                        .font(.body)
                        .foregroundStyle(TextColors.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.lg)
                }
                
                Spacer()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.headline.weight(.semibold))
                }
                .accessibilityLabel("Sign out")
                .tint(.purple)
            }
            
            ToolbarItemGroup(placement: .bottomBar) {
                HStack(spacing: 12) {
                    Button {
                        goBack()
                    } label: {
                        Label("Back", systemImage: "chevron.left")
                            .padding(.leading, 8)
                            .padding(.trailing, 4)
                    }
                    .disabled(isFirstStep)
                    .accessibilityLabel("Back")
                    
                    Divider()

                    Button {
                        goNext()
                    } label: {
                        Label("Next", systemImage: "chevron.right")
                            .padding(.leading, 4)
                            .padding(.trailing, 8)
                    }
                    .disabled(isLastStep)
                    .accessibilityLabel("Next")
                }
                .tint(.purple)
                
                Spacer()
                
                Button {
                    showingFinishConfirmation = true
                } label: {
                    Label("Finish", systemImage: "flag.checkered")
                }
                .disabled(!isLastStep)
                .accessibilityLabel("Finish")
                .tint(.purple)
            }
        }
        .onAppear {
            sessionStartTime = Date()
        }
        .alert("End exercise?", isPresented: $showingFinishConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Finish") {
                finishSession()
            }
        } message: {
            Text("Are you sure you want to end this exercise?")
        }
        .sheet(isPresented: $showingCongratsSheet, onDismiss: {
            guard shouldDismissAfterCongrats else { return }
            shouldDismissAfterCongrats = false
            dismiss()
        }) {
            CongratsSessionModal(
                configuration: congratsConfiguration,
                onDone: {
                    shouldDismissAfterCongrats = true
                    showingCongratsSheet = false
                }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
    
    // MARK: - Actions
    
    private func goBack() {
        guard currentStepIndex > 0 else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            currentStepIndex -= 1
        }
        HapticFeedback.selection()
    }
    
    private func goNext() {
        guard currentStepIndex < steps.count - 1 else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            currentStepIndex += 1
        }
        HapticFeedback.selection()
    }
    
    private func finishSession() {
        let elapsed = Date().timeIntervalSince(sessionStartTime)
        
        let dataManager = DataManager(modelContext: modelContext)
        do {
            try dataManager.createGroundingSessionResult(
                type: exercise.type,
                duration: elapsed
            )
            
            if let assignment {
                try dataManager.markAssignmentCompletedIfNeeded(assignment: assignment)
            }
            HapticFeedback.success()
        } catch {
            print("Error saving grounding session: \(error)")
            HapticFeedback.error()
            dismiss()
            return
        }
        showingCongratsSheet = true
    }
    
    // MARK: - Formatting
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    NavigationStack {
        GroundingSessionView(exercise: GroundingExercise.predefinedExercises[0])
    }
    .modelContainer(for: [GroundingSessionResult.self], inMemory: true)
}


