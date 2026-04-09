import Foundation
import SwiftData

// MARK: - SessionStatus

// Storage contract: rawValues are persisted in SwiftData. NEVER rename rawValue strings — only add new cases.
enum SessionStatus: String, Codable {
    case planned    = "planned"
    case inProgress = "in_progress"
    case completed  = "completed"
    case abandoned  = "abandoned"
    case skipped    = "skipped"
}

// MARK: - ActivationSession Model

@Model
final class ActivationSession {
    @Attribute(.unique) var id: UUID
    var activityId: UUID
    /// ExerciseAssignment.id for daily/weekly recurring sessions; nil for one-time or ad-hoc.
    var assignmentId: UUID?

    var statusRaw: String       // SessionStatus.rawValue

    var moodBefore: Int?
    var moodAfter: Int?
    /// Cached at completion: moodAfter - moodBefore. Nil if either mood was not recorded.
    var moodDelta: Int?

    var barrierNote: String?
    var reflectionNote: String?

    /// Set when the session was created from a schedule (one-time or recurring).
    var plannedFor: Date?
    var startedAt: Date?
    var completedAt: Date?
    /// Actual duration in minutes; computed from startedAt/completedAt at completion.
    var actualMinutes: Int?

    var createdAt: Date

    init(
        id: UUID = UUID(),
        activityId: UUID,
        assignmentId: UUID? = nil,
        status: SessionStatus = .planned,
        moodBefore: Int? = nil,
        moodAfter: Int? = nil,
        moodDelta: Int? = nil,
        barrierNote: String? = nil,
        reflectionNote: String? = nil,
        plannedFor: Date? = nil,
        startedAt: Date? = nil,
        completedAt: Date? = nil,
        actualMinutes: Int? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.activityId = activityId
        self.assignmentId = assignmentId
        self.statusRaw = status.rawValue
        self.moodBefore = moodBefore
        self.moodAfter = moodAfter
        self.moodDelta = moodDelta
        self.barrierNote = barrierNote
        self.reflectionNote = reflectionNote
        self.plannedFor = plannedFor
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.actualMinutes = actualMinutes
        self.createdAt = createdAt
    }

    var status: SessionStatus {
        get { SessionStatus(rawValue: statusRaw) ?? .planned }
        set { statusRaw = newValue.rawValue }
    }
}
