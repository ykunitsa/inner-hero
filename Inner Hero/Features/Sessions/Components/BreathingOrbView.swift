import SwiftUI

struct BreathingOrbView: View {
    let phase: BreathingController.BreathPhase
    let phaseDuration: TimeInterval
    let isActive: Bool

    @State private var orbScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.85
    @State private var highlightOpacity: Double = 0.45

    var body: some View {
        ZStack {
            // Outer soft glow
            Circle()
                .fill(Color.teal.opacity(0.10))
                .blur(radius: 14)
                .opacity(glowOpacity)

            // Main orb
            ZStack {
                Circle()
                    .fill(Color.teal.opacity(0.70))

                // Inner depth
                Circle()
                    .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
                    .blur(radius: 0.6)
            }
            .frame(width: 220, height: 220)
            .scaleEffect(orbScale)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            // Seed a phase-appropriate start value so the very first inhale animates (instead of snapping).
            orbScale = phaseStartScale(for: phase)
            applyPhaseAppearance(phase, animated: false)

            // Trigger the phase animation on the next run loop tick (fixes “first inhale doesn’t animate”).
            DispatchQueue.main.async {
                applyPhase(phase, duration: phaseDuration, animated: true)
            }
        }
        .onChange(of: phase) { _, newPhase in
            applyPhase(newPhase, duration: phaseDuration, animated: true)
        }
        .onChange(of: isActive) { _, _ in
            applyPhaseAppearance(phase, animated: true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        switch phase {
        case .inhale: return "Вдох"
        case .hold: return "Задержка"
        case .exhale: return "Выдох"
        case .rest: return "Пауза"
        }
    }

    private func applyPhase(_ phase: BreathingController.BreathPhase, duration: TimeInterval, animated: Bool) {
        let d = max(0.12, duration)
        let animation: Animation = .easeInOut(duration: d)

        let targetScale: CGFloat = {
            switch phase {
            case .inhale:
                return 1.35
            case .hold:
                return orbScale
            case .exhale:
                return 0.85
            case .rest:
                // Rest should not make the orb grow.
                return orbScale
            }
        }()

        let targetGlowOpacity: Double = {
            guard isActive else { return 0.65 }
            switch phase {
            case .inhale: return 0.95
            case .hold: return 0.90
            case .exhale: return 0.80
            case .rest: return 0.75
            }
        }()

        let targetHighlightOpacity: Double = {
            guard isActive else { return 0.35 }
            switch phase {
            case .inhale: return 0.55
            case .hold: return 0.50
            case .exhale: return 0.40
            case .rest: return 0.38
            }
        }()

        if animated {
            withAnimation(animation) {
                if phase != .hold && phase != .rest { orbScale = targetScale }
                glowOpacity = targetGlowOpacity
                highlightOpacity = targetHighlightOpacity
            }
        } else {
            if phase != .hold && phase != .rest { orbScale = targetScale }
            glowOpacity = targetGlowOpacity
            highlightOpacity = targetHighlightOpacity
        }
    }

    private func applyPhaseAppearance(_ phase: BreathingController.BreathPhase, animated: Bool) {
        let d = max(0.12, phaseDuration)
        let animation: Animation = .easeInOut(duration: d)

        let targetGlowOpacity: Double = {
            guard isActive else { return 0.65 }
            switch phase {
            case .inhale: return 0.95
            case .hold: return 0.90
            case .exhale: return 0.80
            case .rest: return 0.75
            }
        }()

        let targetHighlightOpacity: Double = {
            guard isActive else { return 0.35 }
            switch phase {
            case .inhale: return 0.55
            case .hold: return 0.50
            case .exhale: return 0.40
            case .rest: return 0.38
            }
        }()

        if animated {
            withAnimation(animation) {
                glowOpacity = targetGlowOpacity
                highlightOpacity = targetHighlightOpacity
            }
        } else {
            glowOpacity = targetGlowOpacity
            highlightOpacity = targetHighlightOpacity
        }
    }

    private func phaseStartScale(for phase: BreathingController.BreathPhase) -> CGFloat {
        switch phase {
        case .inhale:
            return 1.0
        case .hold:
            return 1.35
        case .exhale:
            return 1.35
        case .rest:
            return 0.85
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        BreathingOrbView(phase: .inhale, phaseDuration: 4, isActive: true)
            .frame(height: 320)
            .padding()
    }
}


