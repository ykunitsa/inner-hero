import Foundation

// MARK: - GroundingType

enum GroundingType: String, Codable {
    case fiveFourThreeTwoOne
}

// MARK: - GroundingInstructionStep

struct GroundingInstructionStep: Identifiable {
    let id = UUID()
    let number: Int
    let title: String
    let prompt: String
}

// MARK: - GroundingExercise

struct GroundingExercise: Identifiable {
    let id = UUID()
    let type: GroundingType
    let name: String
    let description: String
    let icon: String
    let estimatedDuration: TimeInterval
    
    static let predefinedExercises: [GroundingExercise] = [
        GroundingExercise(
            type: .fiveFourThreeTwoOne,
            name: "5-4-3-2-1",
            description: "Техника заземления: найдите 5 предметов, которые видите, 4 ощущения от прикосновения, 3 звука, 2 запаха (или ощущения воздуха) и 1 вкус.",
            icon: "brain.head.profile",
            estimatedDuration: 120
        )
    ]
    
    var instructionSteps: [GroundingInstructionStep] {
        switch type {
        case .fiveFourThreeTwoOne:
            return [
                GroundingInstructionStep(
                    number: 5,
                    title: "Осмотритесь",
                    prompt: "Найдите 5 предметов вокруг и задержите на каждом взгляд на секунду."
                ),
                GroundingInstructionStep(
                    number: 4,
                    title: "Опора",
                    prompt: "Найдите 4 ощущения от прикосновения: одежда, стул, пол, предмет в руках."
                ),
                GroundingInstructionStep(
                    number: 3,
                    title: "Звуки",
                    prompt: "Отметьте 3 звука: ближний, дальний и самый тихий."
                ),
                GroundingInstructionStep(
                    number: 2,
                    title: "Запахи",
                    prompt: "Поймайте 2 запаха или просто 2 ощущения воздуха."
                ),
                GroundingInstructionStep(
                    number: 1,
                    title: "Вкус",
                    prompt: "Заметьте 1 вкус во рту или сделайте маленький глоток воды и почувствуйте вкус."
                )
            ]
        }
    }
}


