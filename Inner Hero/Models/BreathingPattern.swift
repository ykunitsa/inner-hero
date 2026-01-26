import Foundation

// MARK: - BreathingPattern Model

struct BreathingPattern: Identifiable {
    let id = UUID()
    let type: BreathingPatternType
    let name: String
    let description: String
    let icon: String
    
    static let predefinedPatterns: [BreathingPattern] = [
        BreathingPattern(
            type: .box,
            name: String(localized: "Box Breathing"),
            description: String(
                localized: "Equal-length inhale, hold, exhale, and hold phases. Used by Navy SEALs to maintain calm under pressure and improve focus."
            ),
            icon: "square.dashed"
        ),
        BreathingPattern(
            type: .fourSix,
            name: String(localized: "4-6 Breathing"),
            description: String(
                localized: "Inhale for 4 seconds, exhale for 6 seconds. Activates the parasympathetic nervous system to reduce anxiety and promote relaxation."
            ),
            icon: "waveform.path"
        ),
        BreathingPattern(
            type: .paced,
            name: String(localized: "Paced Breathing"),
            description: String(
                localized: "Slow, rhythmic breathing at a controlled rate. Helps regulate heart rate variability and reduces physiological arousal."
            ),
            icon: "metronome"
        )
    ]
}

// MARK: - Localization Helpers

extension BreathingPattern {
    var localizedName: String {
        name
    }
    
    var localizedDescription: String {
        description
    }
}

