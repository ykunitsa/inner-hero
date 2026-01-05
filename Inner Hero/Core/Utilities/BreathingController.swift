import Foundation

// MARK: - Breathing Animation Controller

@Observable
class BreathingController {
    var isBreathing: Bool = false
    var isPaused: Bool = false
    var breathPhase: BreathPhase = .inhale
    var patternType: BreathingPatternType
    var elapsedTime: TimeInterval = 0
    
    private var timer: Timer?
    private var phaseTimer: Timer?
    private var phaseStartDate: Date?
    private var phaseRemaining: TimeInterval = 0
    
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
            case .inhale: return "Вдох"
            case .hold: return "Задержка"
            case .exhale: return "Выдох"
            case .rest: return "Отдых"
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
        if isBreathing {
            if isPaused {
                resume()
            }
            return
        }
        isBreathing = true
        isPaused = false
        elapsedTime = 0
        breathPhase = .inhale
        
        // Timer for elapsed time
        startElapsedTimer()
        
        // Start first phase
        scheduleNextPhase()
    }
    
    func stop() {
        isBreathing = false
        isPaused = false
        stopElapsedTimer()
        phaseTimer?.invalidate()
        phaseTimer = nil
        phaseStartDate = nil
        phaseRemaining = 0
    }

    func pause() {
        guard isBreathing, !isPaused else { return }
        isPaused = true
        stopElapsedTimer()

        if let phaseStartDate {
            let elapsedInPhase = Date().timeIntervalSince(phaseStartDate)
            phaseRemaining = max(0, phaseRemaining - elapsedInPhase)
        }

        phaseTimer?.invalidate()
        phaseTimer = nil
        self.phaseStartDate = nil
    }

    func resume() {
        guard isBreathing, isPaused else { return }
        isPaused = false
        startElapsedTimer()

        if phaseRemaining <= 0 {
            scheduleNextPhase()
        } else {
            schedulePhaseTimer(duration: phaseRemaining)
        }
    }

    var remainingTimeInCurrentPhase: TimeInterval {
        if !isBreathing { return 0 }
        if isPaused { return max(0, phaseRemaining) }
        guard let phaseStartDate else { return max(0, phaseRemaining) }
        let elapsedInPhase = Date().timeIntervalSince(phaseStartDate)
        return max(0, phaseRemaining - elapsedInPhase)
    }
    
    private func scheduleNextPhase() {
        let duration = breathPhase.duration(for: patternType)
        
        // Skip phases with 0 duration
        if duration == 0 {
            breathPhase = breathPhase.next(for: patternType)
            scheduleNextPhase()
            return
        }
        
        phaseRemaining = duration
        schedulePhaseTimer(duration: duration)
    }

    private func schedulePhaseTimer(duration: TimeInterval) {
        phaseTimer?.invalidate()
        phaseStartDate = Date()

        phaseTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            guard let self else { return }
            guard self.isBreathing, !self.isPaused else { return }
            self.phaseStartDate = nil
            self.phaseRemaining = 0
            self.breathPhase = self.breathPhase.next(for: self.patternType)
            self.scheduleNextPhase()
        }
    }

    private func startElapsedTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.elapsedTime += 0.1
        }
    }

    private func stopElapsedTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    deinit {
        stop()
    }
}
