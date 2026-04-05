import Foundation
import SwiftData

@Model
final class BASession {
    @Attribute(.unique) var id: UUID
    var activity: BAActivity?
    var statusRaw: String
    var moodBefore: Int
    var moodAfter: Int?
    var avoidanceContext: String?
    var scheduledFor: Date
    var implementationPlace: String?
    var startedAt: Date?
    var completedAt: Date?
    var expectedOutcomeRaw: String?
    var createdAt: Date

    // MARK: - Computed

    var status: BAStatus {
        BAStatus(rawValue: statusRaw) ?? .planned
    }

    var expectedOutcome: ExpectedOutcome? {
        ExpectedOutcome(rawValue: expectedOutcomeRaw ?? "")
    }

    var moodDelta: Int? {
        guard let after = moodAfter else { return nil }
        return after - moodBefore
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(scheduledFor)
    }

    var elapsedTime: TimeInterval? {
        guard let start = startedAt else { return nil }
        return Date().timeIntervalSince(start)
    }

    // MARK: - Methods

    func start() {
        statusRaw = BAStatus.active.rawValue
        startedAt = Date()
    }

    func complete(moodAfter: Int, outcome: ExpectedOutcome) {
        self.moodAfter = moodAfter
        expectedOutcomeRaw = outcome.rawValue
        completedAt = Date()
        statusRaw = BAStatus.completed.rawValue
    }

    // MARK: - Init

    init(
        id: UUID = UUID(),
        activity: BAActivity? = nil,
        statusRaw: String = BAStatus.planned.rawValue,
        moodBefore: Int,
        moodAfter: Int? = nil,
        avoidanceContext: String? = nil,
        scheduledFor: Date,
        implementationPlace: String? = nil,
        startedAt: Date? = nil,
        completedAt: Date? = nil,
        expectedOutcomeRaw: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.activity = activity
        self.statusRaw = statusRaw
        self.moodBefore = moodBefore
        self.moodAfter = moodAfter
        self.avoidanceContext = avoidanceContext
        self.scheduledFor = scheduledFor
        self.implementationPlace = implementationPlace
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.expectedOutcomeRaw = expectedOutcomeRaw
        self.createdAt = createdAt
    }
}
