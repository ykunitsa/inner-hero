import SwiftUI
import SwiftData

struct ExerciseScheduleView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ExerciseAssignment.time) private var allAssignments: [ExerciseAssignment]
    @Query(sort: \Exposure.title) private var exposures: [Exposure]
    @Query(sort: \ActivityList.title) private var activityLists: [ActivityList]
    
    @State private var assignmentToEdit: ExerciseAssignment?
    @State private var showingEditSheet = false
    @State private var assignmentToDelete: ExerciseAssignment?
    @State private var showingDeleteAlert = false
    
    private var activeAssignments: [ExerciseAssignment] {
        allAssignments.filter { $0.isActive }
    }
    
    private var inactiveAssignments: [ExerciseAssignment] {
        allAssignments.filter { !$0.isActive }
    }
    
    var body: some View {
        NavigationStack {
            List {
                if allAssignments.isEmpty {
                    emptyStateView
                } else {
                    if !activeAssignments.isEmpty {
                        Section {
                            ForEach(activeAssignments) { assignment in
                                scheduleRow(assignment: assignment)
                            }
                        } header: {
                            Text("Активные расписания")
                        }
                    }
                    
                    if !inactiveAssignments.isEmpty {
                        Section {
                            ForEach(inactiveAssignments) { assignment in
                                scheduleRow(assignment: assignment)
                            }
                        } header: {
                            Text("Неактивные расписания")
                        }
                    }
                }
            }
            .navigationTitle("Расписание")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        assignmentToEdit = nil
                        showingEditSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.headline)
                            .foregroundStyle(TextColors.toolbar)
                    }
                    .accessibilityLabel("Добавить расписание")
                }
            }
            .sheet(isPresented: $showingEditSheet) {
                ScheduleExerciseView(assignment: assignmentToEdit)
            }
            .alert("Удалить расписание?", isPresented: $showingDeleteAlert, presenting: assignmentToDelete) { assignment in
                Button("Отмена", role: .cancel) {
                    assignmentToDelete = nil
                }
                Button("Удалить", role: .destructive) {
                    deleteAssignment(assignment)
                }
            } message: { assignment in
                Text("Вы уверены, что хотите удалить это расписание?")
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 72))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue.opacity(0.6), .cyan.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .accessibilityHidden(true)
            
            VStack(spacing: 12) {
                Text("Нет расписаний")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(TextColors.primary)
                
                Text("Создайте расписание для регулярных напоминаний о упражнениях")
                    .font(.body)
                    .foregroundStyle(TextColors.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
        .accessibilityElement(children: .combine)
    }
    
    private func scheduleRow(assignment: ExerciseAssignment) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(getExerciseName(for: assignment))
                    .font(.headline)
                    .foregroundStyle(TextColors.primary)
                
                HStack(spacing: 12) {
                    Label(timeString(from: assignment.time), systemImage: "clock")
                        .font(.subheadline)
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
                    toggleAssignment(assignment, isActive: newValue)
                }
            ))
            .labelsHidden()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            assignmentToEdit = assignment
            showingEditSheet = true
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                assignmentToDelete = assignment
                showingDeleteAlert = true
            } label: {
                Label("Удалить", systemImage: "trash")
            }
        }
    }
    
    private func getExerciseName(for assignment: ExerciseAssignment) -> String {
        switch assignment.exerciseType {
        case .exposure:
            if let exposureId = assignment.exposureId,
               let exposure = exposures.first(where: { $0.id == exposureId }) {
                return exposure.title
            }
            return "Экспозиция"
            
        case .breathing:
            if let patternType = assignment.breathingPattern {
                if let pattern = BreathingPattern.predefinedPatterns.first(where: { $0.type == patternType }) {
                    return pattern.name
                }
            }
            return "Дыхательное упражнение"
            
        case .relaxation:
            if let relaxationType = assignment.relaxation {
                if let exercise = RelaxationExercise.predefinedExercises.first(where: { $0.type == relaxationType }) {
                    return exercise.name
                }
            }
            return "Релаксация"
            
        case .behavioralActivation:
            if let activityListId = assignment.activityListId,
               let activityList = activityLists.first(where: { $0.id == activityListId }) {
                return activityList.title
            }
            return "Поведенческая активация"
        }
    }
    
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func toggleAssignment(_ assignment: ExerciseAssignment, isActive: Bool) {
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
    
    private func deleteAssignment(_ assignment: ExerciseAssignment) {
        Task {
            let dataManager = DataManager(modelContext: modelContext)
            
            do {
                // Cancel notification
                await NotificationManager.shared.cancelNotification(for: assignment)
                
                // Delete assignment
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
    ExerciseScheduleView()
        .modelContainer(for: [ExerciseAssignment.self, Exposure.self, ActivityList.self], inMemory: true)
}


