import Foundation

// MARK: - RelaxationExercise Model

struct RelaxationExercise: Identifiable {
    let id = UUID()
    let type: RelaxationType
    let name: String
    let description: String
    let icon: String
    let duration: TimeInterval
    
    static let predefinedExercises: [RelaxationExercise] = [
        RelaxationExercise(
            type: .fullBody,
            name: "Расслабление всего тела",
            description: "Полная последовательность прогрессивной мышечной релаксации для всех основных групп мышц. Помогает снять глубокое напряжение по всему телу.",
            icon: "figure.mind.and.body",
            duration: 900 // 15 minutes
        ),
        RelaxationExercise(
            type: .short,
            name: "Быстрая релаксация",
            description: "Короткая версия прогрессивной мышечной релаксации с фокусом на ключевых зонах напряжения. Подходит для быстрого снятия стресса в течение дня.",
            icon: "figure.stand",
            duration: 300 // 5 minutes
        )
    ]
}

