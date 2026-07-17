import SwiftUI
import SwiftData

// MARK: - GroundingSessionView

struct GroundingSessionView: View {
    let exercise: GroundingExercise
    let assignment: ExerciseAssignment?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel = GroundingSessionViewModel()
    @State private var currentStepIndex = 0
    @State private var showingFinishConfirmation = false
    @State private var showingCongratsSheet = false
    @State private var shouldDismissAfterCongrats = false

    init(exercise: GroundingExercise, assignment: ExerciseAssignment? = nil) {
        self.exercise = exercise
        self.assignment = assignment
    }

    private var steps: [GroundingInstructionStep] { exercise.instructionSteps }
    private var currentStep: GroundingInstructionStep { steps[currentStepIndex] }
    private var isFirstStep: Bool { currentStepIndex == 0 }
    private var isLastStep: Bool { currentStepIndex == steps.count - 1 }

    private var stepIconSystemName: String {
        switch currentStep.number {
        case 5: return "eye.fill"
        case 4: return "hand.raised.fill"
        case 3: return "ear.fill"
        case 2:
            if #available(iOS 17.0, *) { return "nose.fill" } else { return "wind" }
        case 1:
            if #available(iOS 17.0, *) { return "mouth.fill" } else { return "cup.and.saucer.fill" }
        default: return "sparkles"
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
                    .init(iconSystemName: "eye.circle.fill",          text: "If you like, repeat another round—at your own pace."),
                    .init(iconSystemName: "hand.raised.circle.fill",  text: "You relied on your senses—that's a skill that strengthens with practice."),
                    .init(iconSystemName: "heart.circle.fill",         text: "Even a small step is self-care.")
                ],
                primaryButtonTitle: "Great"
            )
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    AppColors.accentLight.opacity(0.5),
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
                        Text("Step \(currentStepIndex + 1) of \(steps.count)")
                            .appFont(.smallMedium)
                            .foregroundStyle(TextColors.secondary)
                        Spacer()
                    }
                    StepProgressBar(current: currentStepIndex + 1, total: steps.count, color: AppColors.accent)
                }
                .padding(.horizontal, Spacing.sm)
                .padding(.top, Spacing.sm)

                Spacer()

                stepCard
                    .padding(.horizontal, Spacing.sm)

                Spacer()

                navigationControls
                    .padding(.horizontal, Spacing.sm)
                    .padding(.bottom, Spacing.sm)
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            viewModel.sessionStartTime = Date()
        }
        .alert("End exercise?", isPresented: $showingFinishConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Finish") { finishSession() }
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

    // MARK: - Step Card

    private var stepCard: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: stepIconSystemName)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(AppColors.accent)
                .iconContainer(
                    size: IconSize.hero,
                    backgroundColor: AppColors.accentLight,
                    cornerRadius: CornerRadius.md
                )
                .contentTransition(.opacity)
                .animation(AppAnimation.standard, value: currentStepIndex)
                .accessibilityHidden(true)

            VStack(spacing: Spacing.sm) {
                Text(currentStep.title)
                    .appFont(.display)
                    .foregroundStyle(TextColors.primary)
                    .multilineTextAlignment(.center)
                    .contentTransition(.opacity)
                    .animation(AppAnimation.standard, value: currentStepIndex)

                Text(currentStep.prompt)
                    .appFont(.h2)
                    .foregroundStyle(TextColors.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .contentTransition(.opacity)
                    .animation(AppAnimation.standard, value: currentStepIndex)
            }
        }
        .frame(maxWidth: .infinity)
        .cardStyle()
    }

    // MARK: - Navigation Controls (BottomPillNavBar-style)

    private var navigationControls: some View {
        HStack(spacing: 0) {
            // Left: Back
            Button {
                goBack()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(isFirstStep ? .white.opacity(0.25) : .white)
                    .frame(maxWidth: .infinity)
                    .frame(height: TouchTarget.minimum)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(isFirstStep)
            .accessibilityLabel("Previous step")

            // Center: Elapsed timer
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
            .accessibilityHidden(true)

            // Right: Next → or Finish (on last step)
            Button {
                if isLastStep {
                    showingFinishConfirmation = true
                } else {
                    goNext()
                }
            } label: {
                Group {
                    if isLastStep {
                        VStack(spacing: 2) {
                            Image(systemName: "flag.checkered")
                                .font(.system(size: 17, weight: .regular))
                                .foregroundStyle(.white)
                            Text("Finish")
                                .appFont(.smallMedium)
                                .foregroundStyle(.white)
                        }
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: TouchTarget.minimum)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .animation(AppAnimation.fast, value: isLastStep)
            .accessibilityLabel(isLastStep ? "Finish exercise" : "Next step")
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xxs)
        .background(Capsule().fill(Color.black))
        .shadow(color: .black.opacity(0.22), radius: 16, y: 6)
        .environment(\.colorScheme, .dark)
    }

    // MARK: - Actions

    private func goBack() {
        guard currentStepIndex > 0 else { return }
        withAnimation(AppAnimation.standard) {
            currentStepIndex -= 1
        }
        HapticFeedback.selection()
    }

    private func goNext() {
        guard currentStepIndex < steps.count - 1 else { return }
        withAnimation(AppAnimation.standard) {
            currentStepIndex += 1
        }
        HapticFeedback.selection()
    }

    private func finishSession() {
        let elapsed = Date().timeIntervalSince(viewModel.sessionStartTime)

        do {
            try viewModel.saveSession(
                type: exercise.type,
                duration: elapsed,
                assignment: assignment,
                context: modelContext
            )
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
