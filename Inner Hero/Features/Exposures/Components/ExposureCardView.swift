import SwiftUI
import SwiftData

struct ExposureCardView: View {
    @Environment(\.colorScheme) private var colorScheme

    let exposure: Exposure
    let assignment: ExerciseAssignment?
    
    init(exposure: Exposure, assignment: ExerciseAssignment? = nil) {
        self.exposure = exposure
        self.assignment = assignment
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            Divider()
            metadataRow
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
        VStack(alignment: .leading, spacing: 8) {
            Text(exposure.title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(TextColors.primary)
                .multilineTextAlignment(.leading)
            
            Text(exposure.exposureDescription)
                .font(.body)
                .foregroundStyle(TextColors.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
    }
    
    private var metadataRow: some View {
        HStack(spacing: 12) {
            if let assignment = assignment, assignment.isActive {
                ScheduleIndicatorView(assignment: assignment)
            }
            
            Spacer(minLength: 0)
            
            HStack(spacing: 10) {
                statItem(systemName: "list.bullet", value: exposure.steps.count)
                statItem(systemName: "chart.bar", value: exposure.sessionResults.count)
                
                if let assignment = assignment, assignment.isActive {
                    Image(systemName: "calendar.badge.checkmark")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                        .accessibilityLabel("Запланировано")
                }
            }
            .frame(alignment: .trailing)
        }
        .accessibilityElement(children: .combine)
    }
    
    private func statItem(systemName: String, value: Int) -> some View {
        HStack(spacing: 4) {
            Image(systemName: systemName)
                .font(.caption2)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .cyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Text("\(value)")
                .font(.caption2)
                .foregroundStyle(TextColors.secondary)
        }
    }
}
