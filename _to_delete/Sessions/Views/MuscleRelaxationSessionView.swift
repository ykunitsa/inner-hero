import SwiftUI
import SwiftData
import Foundation

// MARK: - MuscleRelaxationSessionView

struct MuscleRelaxationSessionView: View {
    let exercise: RelaxationExercise
    let assignment: ExerciseAssignment?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel = RelaxationSessionViewModel()
    @State private var timer = StepTimerController()
    @State private var currentStepIndex = 0
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

    private var muscleGroups: [MuscleGroup] { MuscleGroup.groups(for: exercise.type) }
    private var currentStep: MuscleGroup { muscleGroups[currentStepIndex] }
    private var isLastStep: Bool { currentStepIndex == muscleGroups.count - 1 }

    private var currentPhaseDuration: TimeInterval {
        switch sessionPhase {
        case .readingInstruction: return readingDuration(for: currentStep)
        case .runningStep:        return currentStep.duration
        }
    }

    private var phaseColor: Color {
        currentStep.phase == .tension ? AppColors.State.warning : AppColors.positive
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    AppColors.positiveLight.opacity(0.5),
                    AppColors.gray100
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress
                VStack(spacing: Spacing.xxs) {
                    HStack {
                        Text("Step \(currentStepIndex + 1) of \(muscleGroups.count)")
                            .appFont(.smallMedium)
                            .foregroundStyle(TextColors.secondary)
                        Spacer()
                        Text(localizedStepName(currentStep))
                            .appFont(.smallMedium)
                            .foregroundStyle(TextColors.secondary)
                    }
                    StepProgressBar(
                        current: currentStepIndex + 1,
                        total: muscleGroups.count,
                        color: AppColors.positive
                    )
                }
                .padding(.horizontal, Spacing.sm)
                .padding(.top, Spacing.sm)

                Spacer()

                VStack(spacing: Spacing.xl) {
                    animationCircle
                    phaseContent
                        .id(sessionPhase)
                }

                Spacer()

                if sessionPhase == .runningStep {
                    instructionCard
                        .padding(.horizontal, Spacing.sm)
                        .padding(.bottom, Spacing.md)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                sessionControls
                    .padding(.horizontal, Spacing.sm)
                    .padding(.bottom, Spacing.sm)
            }
            .ignoresSafeArea(edges: .bottom)
            .animation(AppAnimation.standard, value: sessionPhase)
        }
        .navigationTitle(exercise.name)
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
                .accessibilityLabel("Close")
                .tint(AppColors.positive)
            }
        }
        .onAppear {
            viewModel.sessionStartTime = Date()
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
            Button("Finish") { finishSession() }
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

    // MARK: - Animation Circle

    private var animationCircle: some View {
        ZStack {
            Circle()
                .fill(phaseColor.opacity(Opacity.softBackground))
                .scaleEffect(isAnimating ? 1.35 : 1.0)

            Circle()
                .fill(phaseColor.opacity(isAnimating ? 0.55 : 0.25))
                .frame(width: 180, height: 180)
                .scaleEffect(isAnimating ? 1.15 : 0.9)
                .shadow(color: phaseColor.opacity(Opacity.standardShadow), radius: isAnimating ? 28 : 12)

            Image(systemName: currentStep.phase == .tension ? "bolt.fill" : "leaf.fill")
                .font(.system(size: 46, weight: .semibold))
                .foregroundStyle(.white)
                .scaleEffect(isAnimating ? 1.1 : 1.0)
                .contentTransition(.opacity)
                .animation(AppAnimation.standard, value: currentStep.phase)
        }
        .frame(width: 220, height: 220)
    }

    // MARK: - Phase Content

    @ViewBuilder
    private var phaseContent: some View {
        switch sessionPhase {
        case .readingInstruction:
            Text(localizedStepInstruction(currentStep))
                .appFont(.h2)
                .foregroundStyle(TextColors.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.lg)
                .contentTransition(.opacity)
                .animation(AppAnimation.standard, value: currentStepIndex)

        case .runningStep:
            VStack(spacing: Spacing.xs) {
                Text(phaseTitle(for: currentStep.phase))
                    .appFont(.h3)
                    .foregroundStyle(phaseColor)
                    .contentTransition(.opacity)
                    .animation(AppAnimation.standard, value: currentStep.phase)

                // Large size intentional: user's hands are occupied doing the exercise
                Text(formattedRemainingTime)
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(TextColors.primary)
                    .contentTransition(.numericText(countsDown: true))
                    .animation(AppAnimation.standard, value: formattedRemainingTime)
            }
        }
    }

    // MARK: - Instruction Card

    private var instructionCard: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: currentStep.phase == .tension ? "bolt.circle.fill" : "leaf.circle.fill")
                .font(.system(size: IconSize.glyph, weight: .medium))
                .foregroundStyle(phaseColor)
                .iconContainer(
                    size: IconSize.card,
                    backgroundColor: phaseColor.opacity(Opacity.softBackground),
                    cornerRadius: CornerRadius.sm
                )
                .contentTransition(.opacity)
                .animation(AppAnimation.standard, value: currentStep.phase)

            Text(localizedStepInstruction(currentStep))
                .appFont(.body)
                .foregroundStyle(TextColors.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .contentTransition(.opacity)
                .animation(AppAnimation.standard, value: currentStepIndex)

            Spacer(minLength: 0)
        }
        .cardStyle(cornerRadius: CornerRadius.md, padding: Spacing.xs)
    }

    // MARK: - Session Controls (BottomPillNavBar-style)

    private var sessionControls: some View {
        let isPlaying = timer.isRunning && !timer.isPaused
        let controlsEnabled = sessionPhase == .runningStep

        return HStack(spacing: 0) {
            // Left: elapsed time
            TimelineView(.periodic(from: viewModel.sessionStartTime, by: 1)) { context in
                VStack(spacing: 2) {
                    Text(formatDuration(context.date.timeIntervalSince(viewModel.sessionStartTime)))
                        .appFont(.mono)
                        .foregroundStyle(.white)
                    Text("Duration")
                        .appFont(.smallMedium)
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: TouchTarget.minimum)
            .contentShape(Rectangle())
            .accessibilityHidden(true)

            // Center: Play / Pause (disabled during reading phase)
            Button {
                Task { @MainActor in togglePlayPause() }
            } label: {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(
                        controlsEnabled
                            ? (isPlaying ? .white : Color.white.opacity(0.5))
                            : Color.white.opacity(0.25)
                    )
                    .frame(width: 36, height: 36)
                    .background(
                        Circle().fill(
                            controlsEnabled
                                ? (isPlaying ? Color.white.opacity(0.25) : Color.white.opacity(0.12))
                                : Color.white.opacity(0.06)
                        )
                    )
            }
            .buttonStyle(.plain)
            .touchTarget()
            .disabled(!controlsEnabled)
            .padding(.horizontal, Spacing.xxxs)
            .accessibilityLabel(isPlaying ? "Pause" : "Start")

            // Right: Finish
            Button {
                showingFinishConfirmation = true
            } label: {
                VStack(spacing: 2) {
                    Image(systemName: "flag.checkered")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundStyle(.white)
                    Text("Finish")
                        .appFont(.smallMedium)
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity)
                .frame(height: TouchTarget.minimum)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Finish session")
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xxs)
        .background(Capsule().fill(Color.black))
        .shadow(color: .black.opacity(0.22), radius: 16, y: 6)
        .environment(\.colorScheme, .dark)
    }

    // MARK: - Helper Properties

    private var formattedRemainingTime: String {
        let remaining = timer.remainingTime(for: currentPhaseDuration)
        let seconds = Int(ceil(remaining))
        return "\(seconds)"
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    // MARK: - Actions

    private func startReadingPhase() {
        readingPhaseTask?.cancel()
        readingPhaseTask = nil

        didHandlePhaseCompletion = false
        sessionPhase = .readingInstruction
        stopRelaxationPulse()

        // Do not use StepTimerController for this phase to guarantee a strict duration.
        timer.stop()
        timer.reset()

        withAnimation(AppAnimation.standard) {
            isAnimating = false
        }

        // Deterministic reading phase using async/await.
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

        isAnimating = currentStep.phase == .relaxation

        if currentStep.phase == .tension {
            withAnimation(.easeIn(duration: 1.5).delay(0.5)) {
                isAnimating = true
            }
        } else {
            withAnimation(.easeOut(duration: 2.0)) {
                isAnimating = false
            }

            relaxationPulseTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
                Task { @MainActor in
                    guard self.sessionPhase == .runningStep else { return }
                    withAnimation(.easeInOut(duration: 3.0)) {
                        self.isAnimating.toggle()
                    }
                }
            }
        }
    }

    private func finishSession() {
        cleanupSession()

        let totalDuration = Date().timeIntervalSince(viewModel.sessionStartTime)

        do {
            try viewModel.saveSession(
                type: exercise.type,
                duration: totalDuration,
                assignment: assignment,
                context: modelContext
            )
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
            return
        case .runningStep:
            if isLastStep {
                finishSessionAutomaticallyIfLastStep()
            } else {
                withAnimation(AppAnimation.standard) {
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

    /// Reading phase lasts at least 5s, extending for longer instructions (~2.2 words/sec reading speed).
    private func readingDuration(for step: MuscleGroup) -> TimeInterval {
        let words = localizedStepInstruction(step)
            .split(whereSeparator: { $0.isWhitespace || $0.isNewline })
            .count
        return max(5, min(12, ceil(Double(words) / 2.2)))
    }

    private func phaseTitle(for phase: MuscleGroup.Phase) -> String {
        switch phase {
        case .tension:    return String(localized: "Tense")
        case .relaxation: return String(localized: "Relax")
        }
    }

    private func localizedStepName(_ step: MuscleGroup) -> String {
        switch step.name {
        case "Hands & Forearms": return String(localized: "Hands & Forearms")
        case "Upper Arms":       return String(localized: "Upper Arms")
        case "Shoulders":        return String(localized: "Shoulders")
        case "Face & Jaw":       return String(localized: "Face & Jaw")
        case "Chest & Back":     return String(localized: "Chest & Back")
        case "Stomach":          return String(localized: "Stomach")
        case "Legs & Thighs":    return String(localized: "Legs & Thighs")
        case "Feet & Calves":    return String(localized: "Feet & Calves")
        case "Upper Body":       return String(localized: "Upper Body")
        case "Face":             return String(localized: "Face")
        case "Core":             return String(localized: "Core")
        case "Lower Body":       return String(localized: "Lower Body")
        default:                 return step.name
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
