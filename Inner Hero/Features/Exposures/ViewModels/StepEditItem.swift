import Foundation

struct StepEditItem: Identifiable, Equatable {
    let id: UUID
    var text: String
    var hasTimer: Bool
    var timerMinutes: Int
    var timerSeconds: Int
    
    init(
        id: UUID = UUID(),
        text: String,
        hasTimer: Bool,
        timerMinutes: Int,
        timerSeconds: Int
    ) {
        self.id = id
        self.text = text
        self.hasTimer = hasTimer
        self.timerMinutes = timerMinutes
        self.timerSeconds = timerSeconds
    }
    
    var timerDuration: Int {
        timerMinutes * 60 + timerSeconds
    }
}
