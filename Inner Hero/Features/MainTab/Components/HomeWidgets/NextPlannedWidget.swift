import SwiftUI

struct NextPlannedWidget: View {
    let next: PlannedUpcoming?
    
    private func relativeDayLabel(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return String(localized: "Today") }
        if calendar.isDateInTomorrow(date) { return String(localized: "Tomorrow") }
        return date.formatted(.dateTime.day().month(.abbreviated))
    }
    
    var body: some View {
        Group {
            if let next {
                NavigationLink(value: AppRoute.plannedSession(assignmentId: next.assignmentId)) {
                    WidgetCard(minHeight: 120) {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(alignment: .firstTextBaseline) {
                                Label("Next", systemImage: "calendar.badge.clock")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.blue)
                                Spacer()
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(relativeDayLabel(for: next.date))
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(.secondary)
                                
                                Text(next.date.formatted(date: .omitted, time: .shortened))
                                    .font(.title3.weight(.semibold).monospacedDigit())
                                    .foregroundStyle(.primary)
                            }
                            
                            Text(next.title)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }
                }
                .buttonStyle(.plain)
            } else {
                NavigationLink(value: AppRoute.exerciseSchedule) {
                    WidgetCard(minHeight: 120) {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Next", systemImage: "calendar.badge.clock")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.blue)
                            
                            Text("No tasks")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(.primary)
                            
                            Text("Open schedule")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.blue)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

