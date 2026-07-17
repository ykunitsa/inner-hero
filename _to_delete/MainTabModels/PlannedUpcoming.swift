import Foundation

struct PlannedUpcoming: Identifiable, Hashable {
    let id: UUID
    let date: Date
    let assignmentId: UUID
    let title: String
    
    init(date: Date, assignment: ExerciseAssignment, title: String) {
        self.id = UUID()
        self.date = date
        self.assignmentId = assignment.id
        self.title = title
    }
}

