import Foundation

// MARK: - Breathing Animation Controller

@Observable
class BreathingController {
    var isBreathing: Bool = false
    var breathPhase: BreathPhase = .inhale
    
    enum BreathPhase {
        case inhale, hold, exhale, rest
        
        var duration: TimeInterval {
            switch self {
            case .inhale: return 4.0
            case .hold: return 2.0
            case .exhale: return 6.0
            case .rest: return 2.0
            }
        }
        
        var instruction: String {
            switch self {
            case .inhale: return "Вдохните медленно..."
            case .hold: return "Задержите дыхание..."
            case .exhale: return "Выдохните медленно..."
            case .rest: return "Расслабьтесь..."
            }
        }
        
        var next: BreathPhase {
            switch self {
            case .inhale: return .hold
            case .hold: return .exhale
            case .exhale: return .rest
            case .rest: return .inhale
            }
        }
    }
}
