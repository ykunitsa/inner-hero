import Foundation
import SwiftUI

@Observable
final class StepTimerController {
    var isRunning: Bool = false
    var elapsedTime: TimeInterval = 0
    var isPaused: Bool = false

    private var tickTask: Task<Void, Never>?
    private var startDate: Date?
    private var pausedElapsedTime: TimeInterval = 0

    func setElapsedTime(_ time: TimeInterval) {
        elapsedTime = time
        pausedElapsedTime = time
    }

    func start() {
        guard !isRunning || isPaused else { return }

        if isPaused {
            resume()
            return
        }

        isRunning = true
        isPaused = false
        startDate = Date.now
        pausedElapsedTime = 0

        tickTask = Task { @MainActor [weak self] in
            await self?.runTickLoop()
        }
    }

    func pause() {
        guard isRunning && !isPaused else { return }

        isPaused = true
        pausedElapsedTime = elapsedTime

        tickTask?.cancel()
        tickTask = nil
    }

    func resume() {
        guard isPaused else { return }

        isPaused = false
        startDate = Date.now

        tickTask = Task { @MainActor [weak self] in
            await self?.runTickLoop()
        }
    }

    func reset() {
        stop()
        elapsedTime = 0
        pausedElapsedTime = 0
        startDate = nil
    }

    func stop() {
        isRunning = false
        isPaused = false
        tickTask?.cancel()
        tickTask = nil
        startDate = nil
    }

    func remainingTime(for duration: TimeInterval) -> TimeInterval {
        return max(0, duration - elapsedTime)
    }

    func isExpired(for duration: TimeInterval) -> Bool {
        return elapsedTime >= duration
    }

    private func runTickLoop() async {
        while isRunning && !isPaused {
            try? await Task.sleep(for: .seconds(1))
            guard isRunning, !isPaused, let start = startDate else { return }
            elapsedTime = Date.now.timeIntervalSince(start) + pausedElapsedTime
        }
    }

    deinit {
        stop()
    }
}
