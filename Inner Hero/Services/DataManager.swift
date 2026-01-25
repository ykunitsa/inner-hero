import Foundation
import SwiftData

@Observable
final class DataManager {
    private let modelContext: ModelContext
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Exposure Operations
    
    @discardableResult
    func createExposure(
        title: String,
        description: String,
        steps: [ExposureStep] = []
    ) throws -> Exposure {
        let exposure = Exposure(
            title: title,
            exposureDescription: description,
            steps: steps
        )
        
        modelContext.insert(exposure)
        try saveContext()
        return exposure
    }
    
    func fetchAllExposures(sortBy sortDescriptors: [SortDescriptor<Exposure>] = []) throws -> [Exposure] {
        let descriptor = FetchDescriptor<Exposure>(sortBy: sortDescriptors)
        return try modelContext.fetch(descriptor)
    }
    
    func deleteExposure(_ exposure: Exposure) throws {
        modelContext.delete(exposure)
        try saveContext()
    }
    
    // MARK: - ExposureSessionResult Operations
    
    @discardableResult
    func createSessionResult(
        for exposure: Exposure,
        anxietyBefore: Int,
        notes: String = ""
    ) throws -> ExposureSessionResult {
        let session = ExposureSessionResult(
            exposure: exposure,
            anxietyBefore: anxietyBefore,
            notes: notes
        )
        
        modelContext.insert(session)
        try saveContext()
        return session
    }
    
    func fetchAllSessionResults(sortBy sortDescriptors: [SortDescriptor<ExposureSessionResult>] = []) throws -> [ExposureSessionResult] {
        let descriptor = FetchDescriptor<ExposureSessionResult>(sortBy: sortDescriptors)
        return try modelContext.fetch(descriptor)
    }
    
    func fetchSessionResults(for exposure: Exposure, sortBy sortDescriptors: [SortDescriptor<ExposureSessionResult>] = []) throws -> [ExposureSessionResult] {
        let defaultSort = [SortDescriptor<ExposureSessionResult>(\.startAt, order: .reverse)]
        let allResults = try fetchAllSessionResults(sortBy: sortDescriptors.isEmpty ? defaultSort : sortDescriptors)
        return allResults.filter { $0.exposure?.id == exposure.id }
    }
    
    func completeSession(
        _ session: ExposureSessionResult,
        anxietyAfter: Int,
        notes: String? = nil
    ) throws {
        session.endAt = Date()
        session.anxietyAfter = anxietyAfter
        if let notes = notes {
            session.notes = notes
        }
        try saveContext()
    }
    
    func deleteSessionResult(_ session: ExposureSessionResult) throws {
        modelContext.delete(session)
        try saveContext()
    }
    
    // MARK: - BreathingSessionResult Operations
    
    @discardableResult
    func createBreathingSessionResult(
        patternType: BreathingPatternType,
        duration: TimeInterval
    ) throws -> BreathingSessionResult {
        let session = BreathingSessionResult(
            duration: duration,
            patternType: patternType
        )
        
        modelContext.insert(session)
        try saveContext()
        return session
    }
    
    func fetchAllBreathingSessions(sortBy sortDescriptors: [SortDescriptor<BreathingSessionResult>] = []) throws -> [BreathingSessionResult] {
        let descriptor = FetchDescriptor<BreathingSessionResult>(sortBy: sortDescriptors)
        return try modelContext.fetch(descriptor)
    }
    
    // MARK: - RelaxationSessionResult Operations
    
    @discardableResult
    func createRelaxationSessionResult(
        type: RelaxationType,
        duration: TimeInterval
    ) throws -> RelaxationSessionResult {
        let session = RelaxationSessionResult(
            duration: duration,
            type: type
        )
        
        modelContext.insert(session)
        try saveContext()
        return session
    }
    
    func fetchAllRelaxationSessions(sortBy sortDescriptors: [SortDescriptor<RelaxationSessionResult>] = []) throws -> [RelaxationSessionResult] {
        let descriptor = FetchDescriptor<RelaxationSessionResult>(sortBy: sortDescriptors)
        return try modelContext.fetch(descriptor)
    }
    
    // MARK: - GroundingSessionResult Operations
    
    @discardableResult
    func createGroundingSessionResult(
        type: GroundingType,
        duration: TimeInterval
    ) throws -> GroundingSessionResult {
        let session = GroundingSessionResult(
            duration: duration,
            type: type
        )
        
        modelContext.insert(session)
        try saveContext()
        return session
    }
    
    func fetchAllGroundingSessions(sortBy sortDescriptors: [SortDescriptor<GroundingSessionResult>] = []) throws -> [GroundingSessionResult] {
        let descriptor = FetchDescriptor<GroundingSessionResult>(sortBy: sortDescriptors)
        return try modelContext.fetch(descriptor)
    }
    
    // MARK: - ActivityList Operations
    
    @discardableResult
    func createActivityList(
        title: String,
        activities: [String] = [],
        isPredefined: Bool = false
    ) throws -> ActivityList {
        let activityList = ActivityList(
            title: title,
            activities: activities,
            isPredefined: isPredefined
        )
        
        modelContext.insert(activityList)
        try saveContext()
        return activityList
    }
    
    func fetchAllActivityLists(sortBy sortDescriptors: [SortDescriptor<ActivityList>] = []) throws -> [ActivityList] {
        let descriptor = FetchDescriptor<ActivityList>(sortBy: sortDescriptors)
        return try modelContext.fetch(descriptor)
    }
    
    func updateActivityList(_ activityList: ActivityList, title: String, activities: [String]) throws {
        activityList.title = title
        activityList.activities = activities
        try saveContext()
    }
    
    func deleteActivityList(_ activityList: ActivityList) throws {
        modelContext.delete(activityList)
        try saveContext()
    }
    
    // MARK: - BehavioralActivationSession Operations
    
    @discardableResult
    func createBehavioralActivationSession(
        selectedActivity: String,
        pleasureRating: Int? = nil
    ) throws -> BehavioralActivationSession {
        let session = BehavioralActivationSession(
            selectedActivity: selectedActivity,
            pleasureRating: pleasureRating
        )
        
        modelContext.insert(session)
        try saveContext()
        return session
    }
    
    func completeBehavioralActivationSession(
        _ session: BehavioralActivationSession,
        pleasureRating: Int
    ) throws {
        session.completedAt = Date()
        session.pleasureRating = pleasureRating
        try saveContext()
    }
    
    func fetchAllBehavioralActivationSessions(sortBy sortDescriptors: [SortDescriptor<BehavioralActivationSession>] = []) throws -> [BehavioralActivationSession] {
        let descriptor = FetchDescriptor<BehavioralActivationSession>(sortBy: sortDescriptors)
        return try modelContext.fetch(descriptor)
    }
    
    // MARK: - ExerciseAssignment Operations
    
    @discardableResult
    func createExerciseAssignment(
        exerciseType: ExerciseType,
        daysOfWeek: [Int],
        time: Date,
        isActive: Bool = true,
        exposureId: UUID? = nil,
        breathingPatternType: BreathingPatternType? = nil,
        relaxationType: RelaxationType? = nil,
        groundingType: GroundingType? = nil,
        activityListId: UUID? = nil
    ) throws -> ExerciseAssignment {
        // Always create a new assignment (multiple schedules per exercise are allowed)
        let assignment = ExerciseAssignment(
            exerciseType: exerciseType,
            daysOfWeek: daysOfWeek,
            time: time,
            isActive: isActive,
            exposureId: exposureId,
            breathingPatternType: breathingPatternType,
            relaxationType: relaxationType,
            groundingType: groundingType,
            activityListId: activityListId
        )
        
        modelContext.insert(assignment)
        try saveContext()
        return assignment
    }
    
    func fetchAllExerciseAssignments(sortBy sortDescriptors: [SortDescriptor<ExerciseAssignment>] = []) throws -> [ExerciseAssignment] {
        let descriptor = FetchDescriptor<ExerciseAssignment>(sortBy: sortDescriptors)
        return try modelContext.fetch(descriptor)
    }
    
    func fetchActiveExerciseAssignments() throws -> [ExerciseAssignment] {
        let allAssignments = try fetchAllExerciseAssignments()
        return allAssignments.filter { $0.isActive }
    }
    
    func fetchAssignmentsForExposure(_ exposure: Exposure) throws -> [ExerciseAssignment] {
        let allAssignments = try fetchAllExerciseAssignments()
        return allAssignments.filter { $0.exerciseType == .exposure && $0.exposureId == exposure.id }
    }
    
    func fetchAssignmentsForBreathingPattern(_ patternType: BreathingPatternType) throws -> [ExerciseAssignment] {
        let allAssignments = try fetchAllExerciseAssignments()
        return allAssignments.filter { 
            $0.exerciseType == .breathing && $0.breathingPattern == patternType 
        }
    }
    
    func fetchAssignmentsForRelaxationType(_ relaxationType: RelaxationType) throws -> [ExerciseAssignment] {
        let allAssignments = try fetchAllExerciseAssignments()
        return allAssignments.filter { 
            $0.exerciseType == .relaxation && $0.relaxation == relaxationType 
        }
    }
    
    func fetchAssignmentsForGroundingType(_ groundingType: GroundingType) throws -> [ExerciseAssignment] {
        let allAssignments = try fetchAllExerciseAssignments()
        return allAssignments.filter {
            $0.exerciseType == .grounding && $0.grounding == groundingType
        }
    }
    
    // MARK: - Single Assignment Fetch Methods
    
    func fetchAssignmentForExposure(_ exposure: Exposure) throws -> ExerciseAssignment? {
        let assignments = try fetchAssignmentsForExposure(exposure)
        return assignments.first
    }
    
    func fetchAssignmentForBreathingPattern(_ patternType: BreathingPatternType) throws -> ExerciseAssignment? {
        let assignments = try fetchAssignmentsForBreathingPattern(patternType)
        return assignments.first
    }
    
    func fetchAssignmentForRelaxationType(_ relaxationType: RelaxationType) throws -> ExerciseAssignment? {
        let assignments = try fetchAssignmentsForRelaxationType(relaxationType)
        return assignments.first
    }
    
    func fetchAssignmentForGroundingType(_ groundingType: GroundingType) throws -> ExerciseAssignment? {
        let assignments = try fetchAssignmentsForGroundingType(groundingType)
        return assignments.first
    }
    
    func updateExerciseAssignment(
        _ assignment: ExerciseAssignment,
        daysOfWeek: [Int]? = nil,
        time: Date? = nil,
        isActive: Bool? = nil
    ) throws {
        if let daysOfWeek = daysOfWeek {
            assignment.daysOfWeek = daysOfWeek
        }
        if let time = time {
            assignment.time = time
        }
        if let isActive = isActive {
            assignment.isActive = isActive
        }
        try saveContext()
    }
    
    func deleteExerciseAssignment(_ assignment: ExerciseAssignment) throws {
        modelContext.delete(assignment)
        try saveContext()
    }
    
    // MARK: - FavoriteExercise Operations
    
    func toggleFavorite(
        exerciseType: ExerciseType,
        exerciseId: UUID? = nil,
        exerciseIdentifier: String? = nil
    ) throws -> Bool {
        // Check if already favorite
        let allFavorites = try fetchAllFavorites()
        if let existing = allFavorites.first(where: { favorite in
            favorite.matches(exerciseType: exerciseType, exerciseId: exerciseId, exerciseIdentifier: exerciseIdentifier)
        }) {
            // Remove from favorites
            modelContext.delete(existing)
            try saveContext()
            return false
        } else {
            // Add to favorites
            let favorite = FavoriteExercise(
                exerciseType: exerciseType,
                exerciseId: exerciseId,
                exerciseIdentifier: exerciseIdentifier
            )
            modelContext.insert(favorite)
            try saveContext()
            return true
        }
    }
    
    func isFavorite(
        exerciseType: ExerciseType,
        exerciseId: UUID? = nil,
        exerciseIdentifier: String? = nil
    ) throws -> Bool {
        let allFavorites = try fetchAllFavorites()
        return allFavorites.contains { favorite in
            favorite.matches(exerciseType: exerciseType, exerciseId: exerciseId, exerciseIdentifier: exerciseIdentifier)
        }
    }
    
    func fetchAllFavorites(sortBy sortDescriptors: [SortDescriptor<FavoriteExercise>] = []) throws -> [FavoriteExercise] {
        let defaultSort = [SortDescriptor<FavoriteExercise>(\.createdAt, order: .reverse)]
        let descriptor = FetchDescriptor<FavoriteExercise>(sortBy: sortDescriptors.isEmpty ? defaultSort : sortDescriptors)
        return try modelContext.fetch(descriptor)
    }
    
    func deleteFavorite(_ favorite: FavoriteExercise) throws {
        modelContext.delete(favorite)
        try saveContext()
    }
    
    // MARK: - Batch Operations
    
    func deleteAllData() throws {
        try modelContext.delete(model: Exposure.self)
        try modelContext.delete(model: ExposureSessionResult.self)
        try modelContext.delete(model: BreathingSessionResult.self)
        try modelContext.delete(model: RelaxationSessionResult.self)
        try modelContext.delete(model: GroundingSessionResult.self)
        try modelContext.delete(model: ExerciseCompletion.self)
        try modelContext.delete(model: ActivityList.self)
        try modelContext.delete(model: BehavioralActivationSession.self)
        try modelContext.delete(model: ExerciseAssignment.self)
        try modelContext.delete(model: FavoriteExercise.self)
        try saveContext()
    }
    
    // MARK: - ExerciseCompletion (Plan completion)
    
    /// Idempotently marks a scheduled assignment as completed for the given day (startOfDay).
    /// Uses `ExerciseCompletion.uniqueKey` to avoid duplicates.
    @discardableResult
    func markAssignmentCompletedIfNeeded(
        assignment: ExerciseAssignment,
        day: Date = Date(),
        calendar: Calendar = .current
    ) throws -> ExerciseCompletion {
        let dayStart = calendar.startOfDay(for: day)
        let uniqueKey = "\(assignment.id.uuidString)|\(Int(dayStart.timeIntervalSince1970))"
        
        let descriptor = FetchDescriptor<ExerciseCompletion>(
            predicate: #Predicate { $0.uniqueKey == uniqueKey }
        )
        
        if let existing = try modelContext.fetch(descriptor).first {
            return existing
        }
        
        let completion = ExerciseCompletion(day: dayStart, assignment: assignment, calendar: calendar)
        modelContext.insert(completion)
        try saveContext()
        return completion
    }
    
    // MARK: - Analytics Operations
    
    func getAverageAnxietyBefore(for exposure: Exposure, in period: TimePeriod) throws -> Double? {
        let sessions = try fetchSessionResults(for: exposure)
        let completedSessions = filterSessionsByPeriod(sessions, period: period)
            .filter { $0.endAt != nil }
        
        guard !completedSessions.isEmpty else { return nil }
        
        let sum = completedSessions.reduce(0) { $0 + $1.anxietyBefore }
        return Double(sum) / Double(completedSessions.count)
    }
    
    func getAverageAnxietyAfter(for exposure: Exposure, in period: TimePeriod) throws -> Double? {
        let sessions = try fetchSessionResults(for: exposure)
        let completedSessions = filterSessionsByPeriod(sessions, period: period)
            .filter { $0.endAt != nil && $0.anxietyAfter != nil }
        
        guard !completedSessions.isEmpty else { return nil }
        
        let sum = completedSessions.compactMap { $0.anxietyAfter }.reduce(0, +)
        return Double(sum) / Double(completedSessions.count)
    }
    
    func getTrendDirection(for exposure: Exposure, in period: TimePeriod) throws -> ChartStatistics.TrendDirection {
        guard let avgBefore = try getAverageAnxietyBefore(for: exposure, in: period),
              let avgAfter = try getAverageAnxietyAfter(for: exposure, in: period) else {
            return .stable
        }
        
        let change = avgAfter - avgBefore
        
        if change < -0.5 {
            return .improving
        } else if change > 0.5 {
            return .worsening
        } else {
            return .stable
        }
    }
    
    private func filterSessionsByPeriod(_ sessions: [ExposureSessionResult], period: TimePeriod) -> [ExposureSessionResult] {
        let cutoffDate = Calendar.current.date(
            byAdding: .day,
            value: -period.daysCount,
            to: Date()
        ) ?? Date()
        
        return sessions.filter { $0.startAt >= cutoffDate }
    }
    
    // MARK: - Private Helpers
    
    private func saveContext() throws {
        try modelContext.save()
    }
}
