import SwiftUI
import SwiftData

struct ExerciseScheduleSection: View {
    @Environment(\.modelContext) private var modelContext
    
    let assignment: ExerciseAssignment?
    let exerciseType: ExerciseType
    let exposureId: UUID?
    let breathingPatternType: BreathingPatternType?
    let relaxationType: RelaxationType?
    let activityListId: UUID?
    
    @State private var showScheduleSheet = false
    @State private var showDeleteAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .font(.body)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.orange, .orange.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Text("Расписание")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(TextColors.primary)
            }
            
            if let assignment = assignment {
                scheduleInfoView(assignment: assignment)
            } else {
                createScheduleButton
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
        .sheet(isPresented: $showScheduleSheet) {
            ScheduleExerciseView(
                assignment: assignment,
                preSelectedExposureId: exposureId,
                preSelectedBreathingPattern: breathingPatternType,
                preSelectedRelaxationType: relaxationType,
                preSelectedActivityListId: activityListId
            )
        }
        .alert("Удалить расписание?", isPresented: $showDeleteAlert) {
            Button("Отмена", role: .cancel) { }
            Button("Удалить", role: .destructive) {
                deleteSchedule()
            }
        } message: {
            Text("Вы уверены, что хотите удалить это расписание?")
        }
    }
    
    private func scheduleInfoView(assignment: ExerciseAssignment) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "clock")
                            .font(.caption)
                            .foregroundStyle(TextColors.secondary)
                        Text(timeString(from: assignment.time))
                            .font(.body.weight(.medium))
                            .foregroundStyle(TextColors.primary)
                    }
                    
                    HStack(spacing: 8) {
                        Image(systemName: "calendar")
                            .font(.caption)
                            .foregroundStyle(TextColors.secondary)
                        Text(assignment.getDayNamesString())
                            .font(.subheadline)
                            .foregroundStyle(TextColors.secondary)
                    }
                }
                
                Spacer()
                
                Toggle("", isOn: Binding(
                    get: { assignment.isActive },
                    set: { newValue in
                        toggleSchedule(assignment, isActive: newValue)
                    }
                ))
                .labelsHidden()
            }
            
            Divider()
            
            HStack(spacing: 12) {
                Spacer(minLength: 0)
                Button {
                    showScheduleSheet = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "pencil")
                            .font(.caption)
                        Text("Редактировать")
                            .font(.subheadline.weight(.medium))
                    }
                    .foregroundStyle(.blue)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.blue.opacity(0.1))
                    )
                }
                .buttonStyle(.plain)
                
                Button {
                    showDeleteAlert = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "trash")
                            .font(.caption)
                        Text("Удалить")
                            .font(.subheadline.weight(.medium))
                    }
                    .foregroundStyle(.red)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.red.opacity(0.1))
                    )
                }
                .buttonStyle(.plain)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }
    
    private var createScheduleButton: some View {
        Button {
            showScheduleSheet = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.body)
                Text("Создать расписание")
                    .font(.body.weight(.medium))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [.orange, .orange.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func toggleSchedule(_ assignment: ExerciseAssignment, isActive: Bool) {
        Task {
            let dataManager = DataManager(modelContext: modelContext)
            
            do {
                try dataManager.updateExerciseAssignment(assignment, isActive: isActive)
                
                if isActive {
                    try await NotificationManager.shared.scheduleNotification(for: assignment)
                } else {
                    await NotificationManager.shared.cancelNotification(for: assignment)
                }
                
                try modelContext.save()
                HapticFeedback.selection()
            } catch {
                HapticFeedback.error()
                print("Ошибка обновления расписания: \(error)")
            }
        }
    }
    
    private func deleteSchedule() {
        guard let assignment = assignment else { return }
        
        Task {
            let dataManager = DataManager(modelContext: modelContext)
            
            do {
                await NotificationManager.shared.cancelNotification(for: assignment)
                try dataManager.deleteExerciseAssignment(assignment)
                HapticFeedback.success()
            } catch {
                HapticFeedback.error()
                print("Ошибка удаления расписания: \(error)")
            }
        }
    }
}

#Preview {
    VStack {
        ExerciseScheduleSection(
            assignment: nil,
            exerciseType: .exposure,
            exposureId: UUID(),
            breathingPatternType: nil,
            relaxationType: nil,
            activityListId: nil
        )
        .padding()
    }
}


