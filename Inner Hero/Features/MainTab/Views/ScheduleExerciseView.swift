import SwiftUI
import SwiftData
#if canImport(UIKit)
import UIKit
#endif

struct ScheduleExerciseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var exerciseType: ExerciseType = .exposure
    @State private var selectedExposureId: UUID?
    @State private var selectedBreathingPattern: BreathingPatternType?
    @State private var selectedRelaxationType: RelaxationType?
    @State private var selectedActivityListId: UUID?
    @State private var selectedDays: [Int] = []
    @State private var selectedTime: Date = {
        var components = DateComponents()
        components.hour = 9
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }()
    @State private var isActive: Bool = true
    @State private var showingPermissionAlert = false
    @State private var permissionDenied = false
    
    @Query(sort: \Exposure.title) private var exposures: [Exposure]
    @Query(sort: \ActivityList.title) private var activityLists: [ActivityList]
    
    let assignmentToEdit: ExerciseAssignment?
    let preSelectedExposureId: UUID?
    let preSelectedBreathingPattern: BreathingPatternType?
    let preSelectedRelaxationType: RelaxationType?
    let preSelectedActivityListId: UUID?
    
    init(
        assignment: ExerciseAssignment? = nil,
        preSelectedExposureId: UUID? = nil,
        preSelectedBreathingPattern: BreathingPatternType? = nil,
        preSelectedRelaxationType: RelaxationType? = nil,
        preSelectedActivityListId: UUID? = nil
    ) {
        self.assignmentToEdit = assignment
        self.preSelectedExposureId = preSelectedExposureId
        self.preSelectedBreathingPattern = preSelectedBreathingPattern
        self.preSelectedRelaxationType = preSelectedRelaxationType
        self.preSelectedActivityListId = preSelectedActivityListId
        
        if let assignment = assignment {
            _exerciseType = State(initialValue: assignment.exerciseType)
            _selectedExposureId = State(initialValue: assignment.exposureId)
            _selectedBreathingPattern = State(initialValue: assignment.breathingPattern)
            _selectedRelaxationType = State(initialValue: assignment.relaxation)
            _selectedActivityListId = State(initialValue: assignment.activityListId)
            _selectedDays = State(initialValue: assignment.daysOfWeek)
            _selectedTime = State(initialValue: assignment.time)
            _isActive = State(initialValue: assignment.isActive)
        } else {
            // Pre-select values if provided
            if preSelectedExposureId != nil {
                _exerciseType = State(initialValue: .exposure)
                _selectedExposureId = State(initialValue: preSelectedExposureId)
            } else if preSelectedBreathingPattern != nil {
                _exerciseType = State(initialValue: .breathing)
                _selectedBreathingPattern = State(initialValue: preSelectedBreathingPattern)
            } else if preSelectedRelaxationType != nil {
                _exerciseType = State(initialValue: .relaxation)
                _selectedRelaxationType = State(initialValue: preSelectedRelaxationType)
            } else if preSelectedActivityListId != nil {
                _exerciseType = State(initialValue: .behavioralActivation)
                _selectedActivityListId = State(initialValue: preSelectedActivityListId)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                exerciseTypeSection
                specificExerciseSection
                timeSection
                daysSection
                activeToggleSection
            }
            .navigationTitle(assignmentToEdit == nil ? "Новое расписание" : "Редактировать расписание")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        saveSchedule()
                    }
                    .disabled(!canSave)
                }
            }
            .alert("Разрешения на уведомления", isPresented: $showingPermissionAlert) {
                if permissionDenied {
                    Button("Настройки") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    Button("Отмена", role: .cancel) { }
                } else {
                    Button("OK", role: .cancel) { }
                }
            } message: {
                if permissionDenied {
                    Text("Для напоминаний о расписании необходимо разрешение на уведомления. Пожалуйста, включите их в настройках.")
                } else {
                    Text("Для напоминаний о расписании необходимо разрешение на уведомления.")
                }
            }
        }
    }
    
    private var exerciseTypeSection: some View {
        Section {
            Picker("Тип упражнения", selection: $exerciseType) {
                Text("Экспозиция").tag(ExerciseType.exposure)
                Text("Дыхание").tag(ExerciseType.breathing)
                Text("Релаксация").tag(ExerciseType.relaxation)
                Text("Активация").tag(ExerciseType.behavioralActivation)
            }
            .onChange(of: exerciseType) {
                // Reset specific selections when type changes
                selectedExposureId = nil
                selectedBreathingPattern = nil
                selectedRelaxationType = nil
                selectedActivityListId = nil
            }
        } header: {
            Text("Тип упражнения")
        }
    }
    
    @ViewBuilder
    private var specificExerciseSection: some View {
        switch exerciseType {
        case .exposure:
            Section {
                if exposures.isEmpty {
                    Text("Нет доступных экспозиций")
                        .foregroundStyle(TextColors.secondary)
                } else {
                    Picker("Экспозиция", selection: $selectedExposureId) {
                        Text("Выберите экспозицию").tag(nil as UUID?)
                        ForEach(exposures) { exposure in
                            Text(exposure.title).tag(exposure.id as UUID?)
                        }
                    }
                }
            } header: {
                Text("Экспозиция")
            }
            
        case .breathing:
            Section {
                Picker("Дыхательная техника", selection: $selectedBreathingPattern) {
                    Text("Выберите технику").tag(nil as BreathingPatternType?)
                    ForEach(BreathingPattern.predefinedPatterns) { pattern in
                        Text(pattern.name).tag(pattern.type as BreathingPatternType?)
                    }
                }
            } header: {
                Text("Дыхательная техника")
            }
            
        case .relaxation:
            Section {
                Picker("Релаксация", selection: $selectedRelaxationType) {
                    Text("Выберите упражнение").tag(nil as RelaxationType?)
                    ForEach(RelaxationExercise.predefinedExercises) { exercise in
                        Text(exercise.name).tag(exercise.type as RelaxationType?)
                    }
                }
            } header: {
                Text("Релаксация")
            }
            
        case .behavioralActivation:
            Section {
                if activityLists.isEmpty {
                    Text("Нет доступных списков активностей")
                        .foregroundStyle(TextColors.secondary)
                } else {
                    Picker("Список активностей", selection: $selectedActivityListId) {
                        Text("Выберите список").tag(nil as UUID?)
                        ForEach(activityLists) { list in
                            Text(list.title).tag(list.id as UUID?)
                        }
                    }
                }
            } header: {
                Text("Список активностей")
            }
        }
    }
    
    private var timeSection: some View {
        Section {
            DatePicker("Время", selection: $selectedTime, displayedComponents: .hourAndMinute)
        } header: {
            Text("Время")
        }
    }
    
    private var daysSection: some View {
        Section {
            DayOfWeekSelector(selectedDays: $selectedDays)
        } header: {
            Text("Дни недели")
        } footer: {
            if selectedDays.isEmpty {
                Text("Выберите хотя бы один день")
                    .foregroundStyle(.red)
            }
        }
    }
    
    private var activeToggleSection: some View {
        Section {
            Toggle("Активно", isOn: $isActive)
        } footer: {
            Text("Когда активно, вы будете получать напоминания в выбранное время")
        }
    }
    
    private var canSave: Bool {
        guard !selectedDays.isEmpty else { return false }
        
        switch exerciseType {
        case .exposure:
            return selectedExposureId != nil
        case .breathing:
            return selectedBreathingPattern != nil
        case .relaxation:
            return selectedRelaxationType != nil
        case .behavioralActivation:
            return selectedActivityListId != nil
        }
    }
    
    private func saveSchedule() {
        Task { @MainActor in
            // Request notification permissions if needed
            let authStatus = await NotificationManager.shared.checkAuthorizationStatus()
            if authStatus != .authorized {
                let granted = await NotificationManager.shared.requestAuthorization()
                if !granted {
                    permissionDenied = authStatus == .denied
                    showingPermissionAlert = true
                    return
                }
            }
            
            let dataManager = DataManager(modelContext: modelContext)
            
            do {
                if let assignment = assignmentToEdit {
                    // Update existing assignment
                    try dataManager.updateExerciseAssignment(
                        assignment,
                        daysOfWeek: selectedDays,
                        time: selectedTime,
                        isActive: isActive
                    )
                    
                    // Update exercise-specific fields if type changed
                    assignment.exerciseType = exerciseType
                    assignment.exposureId = selectedExposureId
                    assignment.breathingPattern = selectedBreathingPattern
                    assignment.relaxation = selectedRelaxationType
                    assignment.activityListId = selectedActivityListId
                    
                    try modelContext.save()
                    
                    // Update notification
                    if isActive {
                        try await NotificationManager.shared.updateNotification(for: assignment)
                    } else {
                        await NotificationManager.shared.cancelNotification(for: assignment)
                    }
                } else {
                    // Create new assignment
                    let assignment = try dataManager.createExerciseAssignment(
                        exerciseType: exerciseType,
                        daysOfWeek: selectedDays,
                        time: selectedTime,
                        isActive: isActive,
                        exposureId: selectedExposureId,
                        breathingPatternType: selectedBreathingPattern,
                        relaxationType: selectedRelaxationType,
                        activityListId: selectedActivityListId
                    )
                    
                    // Schedule notification
                    if isActive {
                        try await NotificationManager.shared.scheduleNotification(for: assignment)
                        try modelContext.save()
                    }
                }
                
                HapticFeedback.success()
                dismiss()
            } catch {
                HapticFeedback.error()
                print("Ошибка сохранения расписания: \(error)")
            }
        }
    }
}

#Preview {
    ScheduleExerciseView()
        .modelContainer(for: [Exposure.self, ActivityList.self, ExerciseAssignment.self], inMemory: true)
}

