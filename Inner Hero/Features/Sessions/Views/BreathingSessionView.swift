import SwiftUI
import SwiftData

struct BreathingSessionView: View {
    let pattern: BreathingPattern
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var controller: BreathingController
    @State private var showingFinishConfirmation = false
    @State private var showingCongratsSheet = false
    @State private var shouldDismissAfterCongrats = false
    @State private var hapticsEngine = BreathingHapticsEngine()
    
    init(pattern: BreathingPattern) {
        self.pattern = pattern
        self._controller = State(initialValue: BreathingController(patternType: pattern.type))
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color.teal.opacity(0.1),
                    Color.mint.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: Spacing.xl) {
                // Pattern name
                Text(pattern.localizedName)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(TextColors.primary)
                    .padding(.top, Spacing.lg)
                
                Spacer()
                
                // Breathing animation
                ZStack {
                    BreathingOrbView(
                        phase: controller.breathPhase,
                        phaseDuration: controller.breathPhase.duration(for: controller.patternType),
                        isActive: controller.isBreathing && !controller.isPaused
                    )
                    
                    // Phase instruction
                    Text(displayedInstruction)
                        .font(.title.weight(.medium))
                        .foregroundStyle(.white)
                        .contentTransition(.opacity)
                        .animation(.easeInOut(duration: 0.22), value: displayedInstruction)
                }
                .frame(height: 300)
                
                Spacer()
                
                // Info section
                VStack(spacing: Spacing.md) {
                    // Current phase
                    HStack {
                        Image(systemName: phaseIcon)
                            .font(.title3)
                            .foregroundStyle(.teal)
                            .frame(width: 30)
                        
                        Text(controller.breathPhase.instruction)
                            .font(.headline)
                            .foregroundStyle(TextColors.primary)
                        
                        Spacer()
                    }
                    
                    Divider()
                    
                    // Elapsed time
                    HStack {
                        Image(systemName: "timer")
                            .font(.title3)
                            .foregroundStyle(.teal)
                            .frame(width: 30)
                        
                        Text("Длительность")
                            .font(.headline)
                            .foregroundStyle(TextColors.primary)
                        
                        Spacer()
                        
                        Text(formatDuration(controller.elapsedTime))
                            .font(.headline.monospacedDigit())
                            .foregroundStyle(TextColors.secondary)
                    }
                }
                .cardStyle()
                .padding(.horizontal)
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
                .accessibilityLabel("Выйти")
                .tint(.teal)
            }
            
            ToolbarItemGroup(placement: .bottomBar) {
                Button {
                    togglePlayPause()
                } label: {
                    Label(
                        controller.isBreathing && !controller.isPaused ? "Пауза" : "Пуск",
                        systemImage: controller.isBreathing && !controller.isPaused ? "pause.fill" : "play.fill"
                    )
                }
                .tint(.teal)
                .disabled(!controller.isBreathing && controller.elapsedTime > 0)
                .accessibilityLabel(controller.isBreathing && !controller.isPaused ? "Пауза" : "Пуск")
                
                Spacer()
                
                Button {
                    showingFinishConfirmation = true
                } label: {
                    Label("Финиш", systemImage: "flag.checkered")
                }
                .tint(.teal)
                .accessibilityLabel("Финиш")
            }
        }
        .onAppear {
            controller.start()
            hapticsEngine.start()
            hapticsEngine.handlePhaseChange(
                to: controller.breathPhase,
                duration: controller.breathPhase.duration(for: controller.patternType)
            )
        }
        .onDisappear {
            controller.stop()
            hapticsEngine.stop()
        }
        .onChange(of: controller.breathPhase) { _, newPhase in
            animatePhaseChange(to: newPhase)
            hapticsEngine.handlePhaseChange(
                to: newPhase,
                duration: newPhase.duration(for: controller.patternType)
            )
        }
        .alert("Завершить сессию?", isPresented: $showingFinishConfirmation) {
            Button("Отмена", role: .cancel) { }
            Button("Завершить") {
                finishSession()
            }
        } message: {
            Text("Вы уверены, что хотите завершить дыхательную сессию?")
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
    
    // MARK: - Helper Properties
    
    private var displayedInstruction: String {
        controller.isPaused ? "Пауза" : controller.breathPhase.instruction
    }
    
    private var phaseIcon: String {
        switch controller.breathPhase {
        case .inhale: return "arrow.up.circle.fill"
        case .hold: return "pause.circle.fill"
        case .exhale: return "arrow.down.circle.fill"
        case .rest: return "moon.circle.fill"
        }
    }
    
    private func animatePhaseChange(to phase: BreathingController.BreathPhase) {
        // Visuals are driven by BreathingOrbView; this stays as a hook for haptics.
        // Haptics are implemented separately via CoreHaptics (see BreathingHapticsEngine).
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
        
        // Save session result
        let dataManager = DataManager(modelContext: modelContext)
        do {
            try dataManager.createBreathingSessionResult(
                patternType: pattern.type,
                duration: controller.elapsedTime
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

