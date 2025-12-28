import SwiftUI
import SwiftData

struct ScheduleIndicatorView: View {
    let assignment: ExerciseAssignment
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "calendar.badge.clock")
                .font(.caption)
                .foregroundStyle(.orange)
            
            Text(timeString)
                .font(.caption.weight(.medium))
                .foregroundStyle(TextColors.secondary)
            
            Text(assignment.getDayNamesString())
                .font(.caption)
                .foregroundStyle(TextColors.tertiary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.orange.opacity(0.1))
        )
    }
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: assignment.time)
    }
}

#Preview {
    @Previewable @State var assignment = ExerciseAssignment(
        exerciseType: .exposure,
        daysOfWeek: [2, 3, 4, 5, 6],
        time: Date()
    )
    
    return ScheduleIndicatorView(assignment: assignment)
        .padding()
}


