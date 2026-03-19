import SwiftUI
import SwiftData

struct BreathingSessionView: View {
    let pattern: BreathingPattern
    let assignment: ExerciseAssignment?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel = BreathingSessionViewModel()
    @State private var controller: BreathingController
    @State private var showingFinishConfirmation = false
    @State private var showingCongratsSheet = false
    @State private var shouldDismissAfterCongrats = false
    @State private var hapticsEngine = BreathingHapticsEngine()
    // Starts at exhale scale so the first inhale visibly animates in
    @State private var circleScale: CGFloat = 0.75

    init(pattern: BreathingPattern, assignment: ExerciseAssignment? = nil) {
        self.pattern = pattern
        self.assignment = assignment
        self._controller = State(initialValue: BreathingController(patternType: pattern.type))
    }

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
                Spacer()

                breathingCircleView

                Spacer()

                phaseCard
                    .padding(.horizontal, Spacing.sm)
                    .padding(.bottom, Spacing.md)

                sessionControls
                    .padding(.horizontal, Spacing.lg)
                    .padding(.bottom, Spacing.lg)
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .navigationTitle(pattern.localizedName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            controller.start()
            hapticsEngine.start()
            let duration = controller.breathPhase.duration(for: controller.patternType)
            hapticsEngine.handlePhaseChange(to: controller.breathPhase, duration: duration)
            // Animate from initial small state to the first phase
            withAnimation(.easeInOut(duration: duration)) {
                circleScale = scaleForPhase(controller.breathPhase)
            }
        }
        .onDisappear {
            controller.stop()
            hapticsEngine.stop()
        }
        .onChange(of: controller.breathPhase) { _, newPhase in
            let duration = newPhase.duration(for: controller.patternType)
            withAnimation(.easeInOut(duration: duration)) {
                circleScale = scaleForPhase(newPhase)
            }
            hapticsEngine.handlePhaseChange(to: newPhase, duration: duration)
        }
        .alert("End session?", isPresented: $showingFinishConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Finish") { finishSession() }
        } message: {
            Text("Are you sure you want to end the breathing session?")
        }
        .sheet(isPresented: $showingCongratsSheet, onDismiss: {
            guard shouldDismissAfterCongrats else { return }
            shouldDismissAfterCongrats = false
            dismiss()
        }) {
            CongratsSessionModal(
                onDone: {
                    shouldDismissAfterCongrats = true
                    showingCongratsSheet = false
                }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Breathing Circle

    private var breathingCircleView: some View {
        ZStack {
            // Soft background glow
            Circle()
                .fill(AppColors.positive.opacity(Opacity.softBackground))
                .scaleEffect(circleScale + 0.2)
            // Light-green stroke ring
            Circle()
                .stroke(AppColors.positiveLight, lineWidth: 16)
                .scaleEffect(circleScale + 0.1)
            // Main solid circle
            Circle()
                .fill(AppColors.positive)
                .scaleEffect(circleScale)
        }
        .frame(width: 240, height: 240)
    }

    // MARK: - Phase Info Card

    private var phaseCard: some View {
        let instruction = controller.isPaused
            ? String(localized: "Paused")
            : controller.breathPhase.instruction
        let icon = controller.isPaused ? "pause.circle.fill" : phaseIcon

        return HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(AppColors.positive)
                .iconContainer(
                    size: IconSize.hero,
                    backgroundColor: AppColors.positiveLight,
                    cornerRadius: CornerRadius.md
                )
                .contentTransition(.opacity)
                .animation(AppAnimation.standard, value: icon)

            Text(instruction)
                .appFont(.h2)
                .foregroundStyle(TextColors.primary)
                .contentTransition(.opacity)
                .animation(AppAnimation.standard, value: instruction)

            Spacer()
        }
        .cardStyle()
    }

    // MARK: - Session Controls (BottomPillNavBar-style)

    private var sessionControls: some View {
        let isPlaying = controller.isBreathing && !controller.isPaused

        return HStack(spacing: 0) {
            // Left: elapsed time
            VStack(spacing: 2) {
                Text(formatDuration(controller.elapsedTime))
                    .appFont(.mono)
                    .foregroundStyle(.white)
                Text("Duration")
                    .appFont(.smallMedium)
                    .foregroundStyle(.white.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
            .frame(height: TouchTarget.minimum)
            .contentShape(Rectangle())

            // Center: Play / Pause
            Button {
                togglePlayPause()
            } label: {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(isPlaying ? .white : Color.white.opacity(0.5))
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(isPlaying
                                  ? Color.white.opacity(0.25)
                                  : Color.white.opacity(0.12))
                    )
            }
            .buttonStyle(.plain)
            .touchTarget()
            .disabled(!controller.isBreathing && controller.elapsedTime > 0)
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

    private var phaseIcon: String {
        switch controller.breathPhase {
        case .inhale: return "arrow.up.circle.fill"
        case .hold:   return "pause.circle.fill"
        case .exhale: return "arrow.down.circle.fill"
        case .rest:   return "moon.circle.fill"
        }
    }

    private func scaleForPhase(_ phase: BreathingController.BreathPhase) -> CGFloat {
        switch phase {
        case .inhale:        return 1.0
        case .hold:          return 1.0
        case .exhale, .rest: return 0.75
        }
    }

    // MARK: - Formatting

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    // MARK: - Actions

    private func finishSession() {
        controller.stop()
        hapticsEngine.stop()

        do {
            try viewModel.saveSession(
                patternType: pattern.type,
                duration: controller.elapsedTime,
                assignment: assignment,
                context: modelContext
            )
            HapticFeedback.success()
        } catch {
            print("Error saving breathing session: \(error)")
            HapticFeedback.error()
        }

        showingCongratsSheet = true
    }

    private func togglePlayPause() {
        if controller.isBreathing && !controller.isPaused {
            controller.pause()
            hapticsEngine.stop()
        } else if controller.isBreathing && controller.isPaused {
            controller.resume()
            hapticsEngine.start()
            hapticsEngine.handlePhaseChange(
                to: controller.breathPhase,
                duration: controller.remainingTimeInCurrentPhase
            )
        } else {
            controller.start()
            hapticsEngine.start()
            hapticsEngine.handlePhaseChange(
                to: controller.breathPhase,
                duration: controller.remainingTimeInCurrentPhase
            )
        }
    }
}

#Preview {
    NavigationStack {
        BreathingSessionView(
            pattern: BreathingPattern.predefinedPatterns[0]
        )
    }
    .modelContainer(for: [BreathingSessionResult.self])
}
