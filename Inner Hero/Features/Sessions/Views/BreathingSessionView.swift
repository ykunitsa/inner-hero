import SwiftUI
import SwiftData

struct BreathingSessionView: View {
    let pattern: BreathingPattern
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var controller: BreathingController
    @State private var scale: CGFloat = 1.0
    @State private var showingFinishAlert = false
    
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
                Text(pattern.name)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(TextColors.primary)
                    .padding(.top, Spacing.lg)
                
                Spacer()
                
                // Breathing animation
                ZStack {
                    // Outer pulsing circles (Apple Watch style)
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [.teal, .mint],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3
                            )
                            .opacity(pulsingOpacity(for: index))
                            .scaleEffect(pulsingScale(for: index))
                    }
                    
                    // Main breathing circle
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.teal.opacity(0.6),
                                    Color.mint.opacity(0.4)
                                ],
                                center: .center,
                                startRadius: 20,
                                endRadius: 100
                            )
                        )
                        .frame(width: 200, height: 200)
                        .scaleEffect(scale)
                        .shadow(color: .teal.opacity(0.3), radius: 20)
                    
                    // Phase instruction
                    Text(controller.breathPhase.instruction)
                        .font(.title.weight(.medium))
                        .foregroundStyle(.white)
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
                        
                        Text("Duration")
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
                
                // Finish button
                Button {
                    showingFinishAlert = true
                } label: {
                    Text("Finish")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                                .fill(Color.teal)
                        )
                }
                .padding(.horizontal)
                .padding(.bottom, Spacing.md)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            controller.start()
        }
        .onDisappear {
            controller.stop()
        }
        .onChange(of: controller.breathPhase) { _, newPhase in
            animatePhaseChange(to: newPhase)
        }
        .alert("Finish Session", isPresented: $showingFinishAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Finish") {
                finishSession()
            }
        } message: {
            Text("Are you sure you want to finish this breathing session?")
        }
    }
    
    // MARK: - Helper Properties
    
    private var phaseIcon: String {
        switch controller.breathPhase {
        case .inhale: return "arrow.up.circle.fill"
        case .hold: return "pause.circle.fill"
        case .exhale: return "arrow.down.circle.fill"
        case .rest: return "moon.circle.fill"
        }
    }
    
    // MARK: - Animation Helpers
    
    private func pulsingOpacity(for index: Int) -> Double {
        let baseOpacity = 0.3
        let delay = Double(index) * 0.2
        return baseOpacity * (controller.isBreathing ? 1.0 : 0.5)
    }
    
    private func pulsingScale(for index: Int) -> CGFloat {
        let baseScale = 1.0 + (CGFloat(index) * 0.3)
        return scale * baseScale
    }
    
    private func animatePhaseChange(to phase: BreathingController.BreathPhase) {
        // Haptic feedback
        #if canImport(UIKit)
        HapticFeedback.impact(.medium)
        #endif
        
        let duration = phase.duration(for: controller.patternType)
        
        // Animate scale based on phase
        withAnimation(.easeInOut(duration: duration)) {
            switch phase {
            case .inhale:
                scale = 1.4
            case .hold:
                // Keep current scale
                break
            case .exhale:
                scale = 0.8
            case .rest:
                scale = 1.0
            }
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
        
        // Save session result
        let dataManager = DataManager(modelContext: modelContext)
        do {
            try dataManager.createBreathingSessionResult(
                patternType: pattern.type,
                duration: controller.elapsedTime
            )
            
            #if canImport(UIKit)
            HapticFeedback.success()
            #endif
        } catch {
            print("Error saving breathing session: \(error)")
            #if canImport(UIKit)
            HapticFeedback.error()
            #endif
        }
        
        dismiss()
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

