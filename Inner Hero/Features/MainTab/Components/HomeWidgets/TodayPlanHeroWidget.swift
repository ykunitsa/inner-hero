import SwiftUI

struct TodayPlanHeroWidget: View {
    let planned: Int
    let done: Int
    let next: PlannedUpcoming?
    
    private var accent: Color {
        .accentColor
    }
    
    private var progress: Double {
        planned == 0 ? 0 : Double(done) / Double(planned)
    }
    
    private var remaining: Int {
        max(0, planned - done)
    }
    
    var body: some View {
        WidgetCard(minHeight: 152) {
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                
                HStack(alignment: .center, spacing: 16) {
                    ProgressRingView(progress: progress, lineWidth: 12, tint: accent)
                        .frame(width: 56, height: 56)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("План на сегодня")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(accent)
                        
                        if planned == 0 {
                            Text("Нет задач")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(.primary)
                            
                            NavigationLink {
                                ExerciseScheduleView()
                            } label: {
                                Label("Открыть расписание", systemImage: "calendar")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(accent)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule(style: .continuous)
                                            .fill(accent.opacity(0.12))
                                    )
                            }
                            .buttonStyle(.plain)
                        } else {
                            Text(String(format: NSLocalizedString("Выполнено %d из %d", comment: ""), done, planned))
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(.primary)
                                .monospacedDigit()
                            
                            Text(
                                remaining == 0
                                ? String(localized: "Готово")
                                : String(format: NSLocalizedString("Осталось %d", comment: ""), remaining)
                            )
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                        
                        if let next {
                            HStack(spacing: 6) {
                                Image(systemName: "clock")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(next.date.formatted(date: .omitted, time: .shortened))
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.secondary)
                                Text("·")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(next.title)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            .padding(.top, 8)
                        }
                    }
                    .layoutPriority(1)
                    
                    Spacer(minLength: 0)
                    
                    if let next {
                        NavigationLink {
                            PlannedSessionLauncherView(assignmentId: next.assignmentId)
                        } label: {
                            Image(systemName: "play.fill")
                                .font(.headline)
                                .frame(width: 44, height: 44)
                                .background(
                                    Circle().fill(accent.opacity(0.12))
                                )
                                .overlay {
                                    Circle().strokeBorder(accent.opacity(0.18), lineWidth: 1)
                                }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Начать следующее упражнение")
                    }
                }
                
                Spacer(minLength: 0)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

