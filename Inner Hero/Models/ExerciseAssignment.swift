import Foundation
import SwiftData

// MARK: - ExerciseType Enum

enum ExerciseType: String, Codable {
    case exposure
    case breathing
    case relaxation
    case grounding
    case behavioralActivation
}

// MARK: - ExerciseAssignment Model

@Model
final class ExerciseAssignment {
    @Attribute(.unique) var id: UUID
    var exerciseType: ExerciseType
    var daysOfWeek: [Int]
    var time: Date
    var isActive: Bool
    var createdAt: Date
    
    // Specific exercise references
    var exposureId: UUID?
    var breathingPatternType: String?
    var relaxationType: String?
    var groundingType: String?
    var activityListId: UUID?
    
    // Notification identifier
    var notificationId: String?
    
    init(
        id: UUID = UUID(),
        exerciseType: ExerciseType,
        daysOfWeek: [Int] = [],
        time: Date,
        isActive: Bool = true,
        createdAt: Date = Date(),
        exposureId: UUID? = nil,
        breathingPatternType: BreathingPatternType? = nil,
        relaxationType: RelaxationType? = nil,
        groundingType: GroundingType? = nil,
        activityListId: UUID? = nil,
        notificationId: String? = nil
    ) {
        self.id = id
        self.exerciseType = exerciseType
        self.daysOfWeek = daysOfWeek
        self.time = time
        self.isActive = isActive
        self.createdAt = createdAt
        self.exposureId = exposureId
        self.breathingPatternType = breathingPatternType?.rawValue
        self.relaxationType = relaxationType?.rawValue
        self.groundingType = groundingType?.rawValue
        self.activityListId = activityListId
        self.notificationId = notificationId
    }
    
    // MARK: - Helper Methods
    
    var breathingPattern: BreathingPatternType? {
        get {
            guard let rawValue = breathingPatternType else { return nil }
            return BreathingPatternType(rawValue: rawValue)
        }
        set {
            breathingPatternType = newValue?.rawValue
        }
    }
    
    var relaxation: RelaxationType? {
        get {
            guard let rawValue = relaxationType else { return nil }
            return RelaxationType(rawValue: rawValue)
        }
        set {
            relaxationType = newValue?.rawValue
        }
    }
    
    var grounding: GroundingType? {
        get {
            guard let rawValue = groundingType else { return nil }
            return GroundingType(rawValue: rawValue)
        }
        set {
            groundingType = newValue?.rawValue
        }
    }
    
    func getLocalizedDayNames() -> [String] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        
        return daysOfWeek.sorted().map { dayNumber in
            // Convert to weekday: 1 = Sunday, 2 = Monday, ..., 7 = Saturday
            // Calendar uses 1 = Sunday, 2 = Monday, etc.
            let weekday = dayNumber
            return formatter.shortWeekdaySymbols[weekday - 1]
        }
    }
    
    func getDayNamesString() -> String {
        let names = getLocalizedDayNames()
        if names.isEmpty {
            return "Не выбрано"
        } else if names.count == 7 {
            return "Каждый день"
        } else if daysOfWeek.sorted() == [2, 3, 4, 5, 6] {
            return "Будни"
        } else if daysOfWeek.sorted() == [1, 7] {
            return "Выходные"
        } else {
            return names.joined(separator: ", ")
        }
    }
    
    func setWeekdays() {
        daysOfWeek = [2, 3, 4, 5, 6] // Monday to Friday
    }
    
    func setWeekends() {
        daysOfWeek = [1, 7] // Sunday and Saturday
    }
    
    func setAllDays() {
        daysOfWeek = [1, 2, 3, 4, 5, 6, 7]
    }
    
    func toggleDay(_ day: Int) {
        if daysOfWeek.contains(day) {
            daysOfWeek.removeAll { $0 == day }
        } else {
            daysOfWeek.append(day)
            daysOfWeek.sort()
        }
    }
    
    func hasDay(_ day: Int) -> Bool {
        return daysOfWeek.contains(day)
    }
}
