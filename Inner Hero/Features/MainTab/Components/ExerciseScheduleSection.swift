import SwiftUI
import SwiftData

struct ExerciseScheduleSection: View {
    @Environment(\.modelContext) private var modelContext
    
    let assignments: [ExerciseAssignment]
    let exerciseType: ExerciseType
    let exposureId: UUID?
    let groundingType: GroundingType?
    let breathingPatternType: BreathingPatternType?
    let relaxationType: RelaxationType?
    let activityListId: UUID?
    
    @State private var showScheduleSheet = false
    @State private var assignmentToEdit: ExerciseAssignment?
    @State private var assignmentToDelete: ExerciseAssignment?
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
            
            if assignments.isEmpty {
                createScheduleButton
            } else {
                schedulesList
                addAnotherScheduleButton
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
                assignment: assignmentToEdit,
                preSelectedExposureId: exposureId,
                preSelectedBreathingPattern: breathingPatternType,
                preSelectedRelaxationType: relaxationType,
                preSelectedGroundingType: groundingType,
                preSelectedActivityListId: activityListId
            )
        }
        .alert("Удалить расписание?", isPresented: $showDeleteAlert, presenting: assignmentToDelete) { assignment in
            Button("Отмена", role: .cancel) { }
            Button("Удалить", role: .destructive) {
                deleteSchedule(assignment)
            }
        } message: { _ in
            Text("Вы уверены, что хотите удалить это расписание?")
        }
    }
    
    private var schedulesList: some View {
        let sorted = assignments.sorted {
            if $0.time != $1.time { return $0.time < $1.time }
            return $0.createdAt < $1.createdAt
        }
        
        return VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(sorted.enumerated()), id: \.element.id) { index, assignment in
                scheduleRow(assignment: assignment)
                
                if index != (sorted.count - 1) {
                    Divider()
                }
            }
        }
    }
    
    private var createScheduleButton: some View {
        Button {
            assignmentToEdit = nil
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
    
    private var addAnotherScheduleButton: some View {
        Button {
            assignmentToEdit = nil
            showScheduleSheet = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle")
                    .font(.body)
                Text("Добавить расписание")
                    .font(.body.weight(.medium))
            }
            .foregroundStyle(.orange)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.orange.opacity(0.10))
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Добавить расписание")
    }
    
    private func scheduleRow(assignment: ExerciseAssignment) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
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
            
            HStack(spacing: 12) {
                Button {
                    assignmentToEdit = assignment
                    showScheduleSheet = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "pencil")
                            .font(.caption)
                        Text("Редактировать")
                            .font(.subheadline.weight(.medium))
                    }
                    .foregroundStyle(.blue)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.blue.opacity(0.10))
                    )
                }
                .buttonStyle(.plain)
                
                Button {
                    assignmentToDelete = assignment
                    showDeleteAlert = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "trash")
                            .font(.caption)
                        Text("Удалить")
                            .font(.subheadline.weight(.medium))
                    }
                    .foregroundStyle(.red)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.red.opacity(0.10))
                    )
                }
                .buttonStyle(.plain)
                
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
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
    
    private func deleteSchedule(_ assignment: ExerciseAssignment) {
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
            assignments: [],
            exerciseType: .exposure,
            exposureId: UUID(),
            groundingType: nil,
            breathingPatternType: nil,
            relaxationType: nil,
            activityListId: nil
        )
        .padding()
    }
}


