import Foundation

// MARK: - Breathing Animation Controller

@Observable
class BreathingController {
    var isBreathing: Bool = false
    var breathPhase: BreathPhase = .inhale
    var patternType: BreathingPatternType
    var elapsedTime: TimeInterval = 0
    
    private var timer: Timer?
    private var phaseTimer: Timer?
    
    init(patternType: BreathingPatternType) {
        self.patternType = patternType
    }
    
    enum BreathPhase {
        case inhale, hold, exhale, rest
        
        func duration(for patternType: BreathingPatternType) -> TimeInterval {
            switch patternType {
            case .box:
                // Box: 4-4-4-4
                return 4.0
            case .fourSix:
                // 4-6 breathing: 4 second inhale, 6 second exhale, no holds
                switch self {
                case .inhale: return 4.0
                case .exhale: return 6.0
                case .hold, .rest: return 0.0
                }
            case .paced:
                // Paced: 5-5 breathing with brief hold
                switch self {
                case .inhale: return 5.0
                case .hold: return 1.0
                case .exhale: return 5.0
                case .rest: return 1.0
                }
            }
        }
        
        var instruction: String {
            switch self {
            case .inhale: return "Inhale"
            case .hold: return "Hold"
            case .exhale: return "Exhale"
            case .rest: return "Rest"
            }
        }
        
        func next(for patternType: BreathingPatternType) -> BreathPhase {
            switch patternType {
            case .box:
                // Full cycle: inhale -> hold -> exhale -> rest
                switch self {
                case .inhale: return .hold
                case .hold: return .exhale
                case .exhale: return .rest
                case .rest: return .inhale
                }
            case .fourSix:
                // Simple cycle: inhale -> exhale
                switch self {
                case .inhale: return .exhale
                case .exhale: return .inhale
                case .hold, .rest: return .inhale
                }
            case .paced:
                // With brief holds: inhale -> hold -> exhale -> rest
                switch self {
                case .inhale: return .hold
                case .hold: return .exhale
                case .exhale: return .rest
                case .rest: return .inhale
                }
            }
        }
    }
    
    func start() {
        guard !isBreathing else { return }
        isBreathing = true
        elapsedTime = 0
        breathPhase = .inhale
        
        // Timer for elapsed time
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.elapsedTime += 0.1
        }
        
        // Start first phase
        scheduleNextPhase()
    }
    
    func stop() {
        isBreathing = false
        timer?.invalidate()
        timer = nil
        phaseTimer?.invalidate()
        phaseTimer = nil
    }
    
    private func scheduleNextPhase() {
        let duration = breathPhase.duration(for: patternType)
        
        // Skip phases with 0 duration
        if duration == 0 {
            breathPhase = breathPhase.next(for: patternType)
            scheduleNextPhase()
            return
        }
        
        phaseTimer?.invalidate()
        phaseTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            guard let self = self, self.isBreathing else { return }
            self.breathPhase = self.breathPhase.next(for: self.patternType)
            self.scheduleNextPhase()
        }
    }
    
    deinit {
        stop()
    }
}
