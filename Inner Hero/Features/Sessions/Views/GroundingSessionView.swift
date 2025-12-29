import SwiftUI
import SwiftData

// MARK: - GroundingSessionView

struct GroundingSessionView: View {
    let exercise: GroundingExercise
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var sessionStartTime = Date()
    @State private var currentStepIndex = 0
    @State private var showingFinishAlert = false
    
    private var steps: [GroundingStep] {
        [
            GroundingStep(number: 5, title: "Посмотрите вокруг", prompt: "Назовите 5 вещей, которые вы видите"),
            GroundingStep(number: 4, title: "Почувствуйте опору", prompt: "Назовите 4 вещи, которые вы можете потрогать"),
            GroundingStep(number: 3, title: "Прислушайтесь", prompt: "Назовите 3 звука, которые вы слышите"),
            GroundingStep(number: 2, title: "Уловите запахи", prompt: "Назовите 2 запаха, которые вы чувствуете"),
            GroundingStep(number: 1, title: "Вкус", prompt: "Назовите 1 вкус, который вы ощущаете")
        ]
    }
    
    private var currentStep: GroundingStep {
        steps[currentStepIndex]
    }
    
    private var isFirstStep: Bool {
        currentStepIndex == 0
    }
    
    private var isLastStep: Bool {
        currentStepIndex == steps.count - 1
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
                        Text("Шаг \(currentStepIndex + 1) из \(steps.count)")
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
                        
                        Text("\(currentStep.number)")
                            .font(.system(size: 64, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .accessibilityLabel("Шаг \(currentStep.number)")
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
                
                HStack(spacing: 12) {
                    Button {
                        goBack()
                    } label: {
                        Text("Назад")
                            .font(.headline)
                            .foregroundStyle(isFirstStep ? TextColors.tertiary : TextColors.primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                                    .fill(Color.white.opacity(0.65))
                            )
                    }
                    .disabled(isFirstStep)
                    
                    Button {
                        if isLastStep {
                            showingFinishAlert = true
                        } else {
                            goNext()
                        }
                    } label: {
                        Text(isLastStep ? "Завершить" : "Дальше")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                                    .fill(Color.purple)
                            )
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, Spacing.md)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            sessionStartTime = Date()
        }
        .alert("Завершить упражнение?", isPresented: $showingFinishAlert) {
            Button("Отмена", role: .cancel) { }
            Button("Завершить") {
                finishSession()
            }
        } message: {
            Text("Вы уверены, что хотите завершить это упражнение?")
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
            HapticFeedback.success()
        } catch {
            print("Error saving grounding session: \(error)")
            HapticFeedback.error()
        }
        
        dismiss()
    }
    
    // MARK: - Formatting
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - GroundingStep

private struct GroundingStep: Identifiable {
    let id = UUID()
    let number: Int
    let title: String
    let prompt: String
}

#Preview {
    NavigationStack {
        GroundingSessionView(exercise: GroundingExercise.predefinedExercises[0])
    }
    .modelContainer(for: [GroundingSessionResult.self], inMemory: true)
}


