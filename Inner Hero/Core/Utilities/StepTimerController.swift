import Foundation
import Combine
import SwiftUI

class StepTimerController: ObservableObject {
    @Published var isRunning: Bool = false
    @Published var elapsedTime: TimeInterval = 0
    @Published var isPaused: Bool = false
    
    private var timer: Timer.TimerPublisher?
    private var cancellable: AnyCancellable?
    private var startDate: Date?
    private var pausedElapsedTime: TimeInterval = 0
    
    var onTimeUpdate: ((TimeInterval) -> Void)?
    
    func setElapsedTime(_ time: TimeInterval) {
        elapsedTime = time
        pausedElapsedTime = time
        onTimeUpdate?(time)
    }
    
    func start() {
        guard !isRunning || isPaused else { return }
        
        if isPaused {
            // Resume from pause
            resume()
            return
        }
        
        // Start fresh
        isRunning = true
        isPaused = false
        startDate = Date.now
        pausedElapsedTime = 0
        
        // Create and connect timer
        timer = Timer.publish(every: 1, on: .main, in: .common)
        cancellable = timer?.autoconnect().sink { [weak self] firedDate in
            guard let self = self, let startDate = self.startDate else { return }
            self.elapsedTime = firedDate.timeIntervalSince(startDate) + self.pausedElapsedTime
            self.onTimeUpdate?(self.elapsedTime)
        }
    }
    
    func pause() {
        guard isRunning && !isPaused else { return }
        
        isPaused = true
        pausedElapsedTime = elapsedTime
        
        // Cancel timer connection
        cancellable?.cancel()
        cancellable = nil
        timer = nil
    }
    
    func resume() {
        guard isPaused else { return }
        
        isPaused = false
        startDate = Date.now
        
        // Recreate and connect timer
        timer = Timer.publish(every: 1, on: .main, in: .common)
        cancellable = timer?.autoconnect().sink { [weak self] firedDate in
            guard let self = self, let startDate = self.startDate else { return }
            self.elapsedTime = firedDate.timeIntervalSince(startDate) + self.pausedElapsedTime
            self.onTimeUpdate?(self.elapsedTime)
        }
    }
    
    func reset() {
        stop()
        elapsedTime = 0
        pausedElapsedTime = 0
        startDate = nil
        onTimeUpdate?(0)
    }
    
    func stop() {
        isRunning = false
        isPaused = false
        cancellable?.cancel()
        cancellable = nil
        timer = nil
        startDate = nil
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
