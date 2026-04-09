import SwiftUI
import SwiftData

struct ScheduledExercisesSection: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ExerciseAssignment.time) private var allAssignments: [ExerciseAssignment]
    @Query(sort: \Exposure.title) private var exposures: [Exposure]
    @Query(sort: \ActivationTask.title) private var activationTasks: [ActivationTask]
    
    private var upcomingExercises: [UpcomingExercise] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let endDate = calendar.date(byAdding: .day, value: 3, to: today) ?? today
        
        var exercises: [UpcomingExercise] = []
        
        for assignment in allAssignments where assignment.isActive {
            let timeComponents = calendar.dateComponents([.hour, .minute], from: assignment.time)
            
            // Generate dates for the next 3 days
            for dayOffset in 0..<3 {
                guard let date = calendar.date(byAdding: .day, value: dayOffset, to: today) else { continue }
                let weekday = calendar.component(.weekday, from: date)
                
                // Check if assignment is scheduled for this weekday
                if assignment.daysOfWeek.contains(weekday) {
                    var dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
                    dateComponents.hour = timeComponents.hour
                    dateComponents.minute = timeComponents.minute
                    
                    if let exerciseDate = calendar.date(from: dateComponents), exerciseDate >= Date() {
                        let exerciseName = assignment.displayTitle(exposures: exposures, activationTasks: activationTasks)
                        let exerciseType = assignment.exerciseType
                        let exerciseId = getExerciseId(for: assignment)
                        let exerciseIdentifier = getExerciseIdentifier(for: assignment)
                        
                        exercises.append(UpcomingExercise(
                            date: exerciseDate,
                            name: exerciseName,
                            exerciseType: exerciseType,
                            exerciseId: exerciseId,
                            exerciseIdentifier: exerciseIdentifier,
                            assignment: assignment
                        ))
                    }
                }
            }
        }
        
        return exercises.sorted { $0.date < $1.date }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            let accent = LinearGradient(
                colors: [.orange, .orange.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .font(.body)
                    .foregroundStyle(accent)
                Text("Scheduled exercises")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(accent)
            }
            
            if upcomingExercises.isEmpty {
                emptyStateView
            } else {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ],
                    spacing: 12
                ) {
                    ForEach(upcomingExercises.prefix(5)) { exercise in
                        ScheduledExerciseCard(exercise: exercise)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Text("No scheduled exercises")
                .font(.subheadline)
                .foregroundStyle(TextColors.secondary)
            
            NavigationLink(value: AppRoute.exerciseSchedule) {
                Text("Create schedule")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.orange)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private func getExerciseId(for assignment: ExerciseAssignment) -> UUID? {
        switch assignment.exerciseType {
        case .exposure:
            return assignment.exposureId
        case .behavioralActivation:
            return assignment.activityId
        default:
            return nil
        }
    }
    
    private func getExerciseIdentifier(for assignment: ExerciseAssignment) -> String? {
        switch assignment.exerciseType {
        case .breathing:
            return assignment.breathingPattern?.rawValue
        case .relaxation:
            return assignment.relaxation?.rawValue
        case .grounding:
            return assignment.grounding?.rawValue
        default:
            return nil
        }
    }
}

// MARK: - Upcoming Exercise Model

struct UpcomingExercise: Identifiable {
    let id = UUID()
    let date: Date
    let name: String
    let exerciseType: ExerciseType
    let exerciseId: UUID?
    let exerciseIdentifier: String?
    let assignment: ExerciseAssignment
}

// MARK: - Scheduled Exercise Card

struct ScheduledExerciseCard: View {
    let exercise: UpcomingExercise
    @Environment(\.colorScheme) var colorScheme
    
    private static let cardHeight: CGFloat = 160
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: exercise.assignment.displayIcon)
                    .font(.title3)
                    .foregroundStyle(colorForExerciseType(exercise.exerciseType))
                
                Spacer()
                
                Text(formatDate(exercise.date))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(TextColors.secondary)
            }
            
            Text(exercise.name)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(TextColors.primary)
                .lineLimit(2)
            
            Text(formatTime(exercise.date))
                .font(.caption)
                .foregroundStyle(TextColors.tertiary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: Self.cardHeight, maxHeight: Self.cardHeight, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    colorScheme == .dark
                    ? LinearGradient(
                        colors: [
                            Color(uiColor: .secondarySystemGroupedBackground),
                            Color(uiColor: .tertiarySystemGroupedBackground)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    : LinearGradient(
                        colors: [
                            Color(red: 0.98, green: 0.99, blue: 1.0),
                            Color(red: 0.96, green: 0.97, blue: 0.99)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(colorForExerciseType(exercise.exerciseType).opacity(colorScheme == .dark ? 0.3 : 0.2), lineWidth: 1)
        )
    }
    
    private func colorForExerciseType(_ type: ExerciseType) -> Color {
        switch type {
        case .exposure:
            return .blue
        case .breathing:
            return .teal
        case .relaxation:
            return .mint
        case .grounding:
            return .purple
        case .behavioralActivation:
            return .green
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return String(localized: "Today")
        } else if calendar.isDateInTomorrow(date) {
            return String(localized: "Tomorrow")
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "d MMM"
            formatter.locale = .current
            return formatter.string(from: date)
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}


