import Foundation
import Combine

class StepTimerController {
    private(set) var isRunning: Bool = false
    private(set) var elapsedTime: TimeInterval = 0
    private(set) var isPaused: Bool = false
    
    private var cancellable: AnyCancellable?
    private var startTime: Date?
    private var pausedDuration: TimeInterval = 0
    
    var onTimeUpdate: ((TimeInterval) -> Void)?
    
    func setElapsedTime(_ time: TimeInterval) {
        elapsedTime = time
        pausedDuration = time
        onTimeUpdate?(time)
    }
    
    func start() {
        guard !isRunning else { return }
        
        isRunning = true
        isPaused = false
        startTime = Date()
        
        cancellable = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateElapsedTime()
            }
    }
    
    private func updateElapsedTime() {
        guard let startTime = startTime, isRunning, !isPaused else { return }
        elapsedTime = Date().timeIntervalSince(startTime) + pausedDuration
        onTimeUpdate?(elapsedTime)
    }
    
    func pause() {
        guard isRunning, !isPaused else { return }
        
        isPaused = true
        pausedDuration = elapsedTime
        cancellable?.cancel()
    }
    
    func resume() {
        guard isPaused else { return }
        
        isPaused = false
        startTime = Date()
        
        cancellable = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateElapsedTime()
            }
    }
    
    func reset() {
        stop()
        elapsedTime = 0
        pausedDuration = 0
        startTime = nil
        onTimeUpdate?(0)
    }
    
    func stop() {
        isRunning = false
        isPaused = false
        cancellable?.cancel()
        cancellable = nil
        startTime = nil
    }
    
    func remainingTime(for duration: TimeInterval) -> TimeInterval {
        return max(0, duration - elapsedTime)
    }
    
    func isExpired(for duration: TimeInterval) -> Bool {
        return elapsedTime >= duration
    }
    
    deinit {
        stop()
    }
}
