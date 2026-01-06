import SwiftUI
import SwiftData

struct RelaxationExerciseCardView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    let exercise: RelaxationExercise
    let assignment: ExerciseAssignment?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            Divider()
            footerRow
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.thinMaterial)
                .shadow(
                    color: .black.opacity(colorScheme == .dark ? 0.35 : 0.06),
                    radius: 10,
                    x: 0,
                    y: 4
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(.primary.opacity(colorScheme == .dark ? 0.18 : 0.06), lineWidth: 1)
        )
    }
    
    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: exercise.icon)
                .font(.title2)
                .foregroundStyle(.mint)
                .frame(width: 40)
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(exercise.name)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(TextColors.primary)
                    .multilineTextAlignment(.leading)
                
                Text(exercise.description)
                    .font(.body)
                    .foregroundStyle(TextColors.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer(minLength: 0)
        }
    }
    
    private var footerRow: some View {
        HStack(spacing: 12) {
            if let assignment, assignment.isActive {
                ScheduleIndicatorView(assignment: assignment)
            } else {
                Text(formattedDuration)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(TextColors.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.mint.opacity(0.10))
                    )
            }
            
            Spacer(minLength: 0)
            
            HStack(spacing: 10) {
                statItem(systemName: "list.number", value: stepsCount)
                statItem(systemName: "timer", text: formattedDurationPlain)
                
                if let assignment, assignment.isActive {
                    Image(systemName: "calendar.badge.checkmark")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                        .accessibilityLabel("Запланировано")
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
    
    private var stepsCount: Int {
        MuscleGroup.groups(for: exercise.type).count
    }
    
    private var formattedDuration: String {
        let minutes = Int(exercise.duration / 60)
        return "\(minutes) мин"
    }
    
    private var formattedDurationPlain: String {
        let minutes = Int(exercise.duration / 60)
        return "\(minutes) мин"
    }
    
    private func statItem(systemName: String, value: Int) -> some View {
        HStack(spacing: 4) {
            Image(systemName: systemName)
                .font(.caption2)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.mint, .teal],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Text("\(value)")
                .font(.caption2)
                .foregroundStyle(TextColors.secondary)
        }
    }
    
    private func statItem(systemName: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: systemName)
                .font(.caption2)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.mint, .teal],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Text(text)
                .font(.caption2)
                .foregroundStyle(TextColors.secondary)
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        RelaxationExerciseCardView(exercise: RelaxationExercise.predefinedExercises[0], assignment: nil)
        RelaxationExerciseCardView(
            exercise: RelaxationExercise.predefinedExercises[1],
            assignment: ExerciseAssignment(exerciseType: .relaxation, time: Date(), relaxationType: .short)
        )
    }
    .padding()
    .background(TopMeshGradientBackground(palette: .mint))
    .modelContainer(for: [ExerciseAssignment.self], inMemory: true)
}


