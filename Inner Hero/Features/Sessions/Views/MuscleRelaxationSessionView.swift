import SwiftUI
import SwiftData
import Foundation

// MARK: - MuscleRelaxationSessionView

struct MuscleRelaxationSessionView: View {
    let exercise: RelaxationExercise
    let assignment: ExerciseAssignment?
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var timer = StepTimerController()
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
                        Text("Шаг \(currentStepIndex + 1) из \(muscleGroups.count)")
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
                        
                            Text("Инструкция")
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
                .accessibilityLabel("Выйти")
                .tint(.mint)
            }
            
            ToolbarItemGroup(placement: .bottomBar) {
                Button {
                    togglePlayPause()
                } label: {
                    Label(
                        timer.isRunning && !timer.isPaused ? "Пауза" : "Пуск",
                        systemImage: timer.isRunning && !timer.isPaused ? "pause.fill" : "play.fill"
                    )
                }
                .tint(.mint)
                .accessibilityLabel(timer.isRunning && !timer.isPaused ? "Пауза" : "Пуск")
                .disabled(sessionPhase == .readingInstruction)
                
                Spacer()
                
                Button {
                    showingFinishConfirmation = true
                } label: {
                    Label("Финиш", systemImage: "flag.checkered")
                }
                .tint(.mint)
                .accessibilityLabel("Финиш")
            }
        }
        .onAppear {
            sessionStartTime = Date()
            startReadingPhase()
        }
        .onDisappear {
            cleanupSession()
        }
        .onReceive(timer.$elapsedTime) { _ in
            handlePhaseCompletionIfNeeded()
        }
        .alert("Завершить сеанс?", isPresented: $showingFinishConfirmation) {
            Button("Отмена", role: .cancel) { }
            Button("Завершить") {
                finishSession()
            }
        } message: {
            Text("Вы уверены, что хотите завершить сеанс мышечной релаксации?")
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
            return "Напрячь"
        case .relaxation:
            return "Расслабить"
        }
    }
    
    private func localizedStepName(_ step: MuscleGroup) -> String {
        switch step.name {
        case "Hands & Forearms":
            return "Кисти и предплечья"
        case "Upper Arms":
            return "Плечи и бицепсы"
        case "Shoulders":
            return "Плечи"
        case "Face & Jaw":
            return "Лицо и челюсть"
        case "Chest & Back":
            return "Грудь и спина"
        case "Stomach":
            return "Живот"
        case "Legs & Thighs":
            return "Ноги и бёдра"
        case "Feet & Calves":
            return "Стопы и икры"
        case "Upper Body":
            return "Верхняя часть тела"
        case "Face":
            return "Лицо"
        case "Core":
            return "Кор"
        case "Lower Body":
            return "Нижняя часть тела"
        default:
            return step.name
        }
    }
    
    private func localizedStepInstruction(_ step: MuscleGroup) -> String {
        switch (step.name, step.phase) {
        case ("Hands & Forearms", .tension):
            return "Сожмите обе кисти в кулаки. Почувствуйте напряжение в кистях и предплечьях."
        case ("Hands & Forearms", .relaxation):
            return "Разожмите кулаки. Полностью расслабьте руки и отметьте разницу между напряжением и расслаблением."
            
        case ("Upper Arms", .tension):
            return "Согните руки и напрягите бицепсы. Сожмите мышцы настолько, насколько комфортно."
        case ("Upper Arms", .relaxation):
            return "Опустите руки и расслабьте их. Почувствуйте, как напряжение уходит из верхней части рук."
            
        case ("Shoulders", .tension):
            return "Поднимите плечи к ушам. Удерживайте и ощущайте напряжение."
        case ("Shoulders", .relaxation):
            return "Опустите плечи в естественное положение. Дайте им стать тяжёлыми и расслабленными."
            
        case ("Face & Jaw", .tension):
            return "Сильно наморщите лицо: зажмурьте глаза и сожмите челюсть."
        case ("Face & Jaw", .relaxation):
            return "Отпустите напряжение в лице. Челюсть слегка разожмите, глаза расслабьте."
            
        case ("Chest & Back", .tension):
            return "Сделайте глубокий вдох и отведите плечи назад. Слегка прогните спину."
        case ("Chest & Back", .relaxation):
            return "Выдохните и расслабьте грудь и спину. Дышите спокойно и естественно."
            
        case ("Stomach", .tension):
            return "Напрягите мышцы живота. Сделайте живот твёрдым."
        case ("Stomach", .relaxation):
            return "Расслабьте мышцы живота. Пусть живот станет мягким."
            
        case ("Legs & Thighs", .tension):
            return "Напрягите мышцы бёдер. Выпрямите ноги и сделайте их более жёсткими."
        case ("Legs & Thighs", .relaxation):
            return "Полностью расслабьте ноги. Почувствуйте, как они становятся тяжёлыми и свободными."
            
        case ("Feet & Calves", .tension):
            return "Опустите носки вниз и напрягите икры и стопы."
        case ("Feet & Calves", .relaxation):
            return "Отпустите напряжение в стопах и икрах. Дайте им расслабиться естественно."
            
        case ("Upper Body", .tension):
            return "Сожмите кулаки, напрягите руки и поднимите плечи. Удерживайте общее напряжение."
        case ("Upper Body", .relaxation):
            return "Отпустите всё. Пусть руки опустятся, а плечи расслабятся. Почувствуйте облегчение."
            
        case ("Face", .tension):
            return "Наморщите лицо: зажмурьте глаза и сожмите челюсть."
        case ("Face", .relaxation):
            return "Пусть напряжение уйдёт из лица. Расслабьте челюсть и глаза."
            
        case ("Core", .tension):
            return "Сделайте глубокий вдох. Слегка прогните спину и напрягите живот."
        case ("Core", .relaxation):
            return "Выдохните и отпустите напряжение. Пусть спина и живот расслабятся."
            
        case ("Lower Body", .tension):
            return "Выпрямите ноги и направьте носки вниз. Напрягите бёдра, икры и стопы."
        case ("Lower Body", .relaxation):
            return "Полностью расслабьте ноги. Почувствуйте, как они становятся тяжёлыми и спокойными."
            
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
