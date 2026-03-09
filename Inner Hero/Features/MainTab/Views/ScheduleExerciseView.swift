import SwiftUI
import SwiftData

struct ScheduleExerciseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    
    @State private var exerciseType: ExerciseType = .exposure
    @State private var selectedExposureId: UUID?
    @State private var selectedBreathingPattern: BreathingPatternType?
    @State private var selectedRelaxationType: RelaxationType?
    @State private var selectedGroundingType: GroundingType?
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
    let preSelectedGroundingType: GroundingType?
    let preSelectedActivityListId: UUID?
    
    init(
        assignment: ExerciseAssignment? = nil,
        preSelectedExposureId: UUID? = nil,
        preSelectedBreathingPattern: BreathingPatternType? = nil,
        preSelectedRelaxationType: RelaxationType? = nil,
        preSelectedGroundingType: GroundingType? = nil,
        preSelectedActivityListId: UUID? = nil
    ) {
        self.assignmentToEdit = assignment
        self.preSelectedExposureId = preSelectedExposureId
        self.preSelectedBreathingPattern = preSelectedBreathingPattern
        self.preSelectedRelaxationType = preSelectedRelaxationType
        self.preSelectedGroundingType = preSelectedGroundingType
        self.preSelectedActivityListId = preSelectedActivityListId
        
        if let assignment = assignment {
            _exerciseType = State(initialValue: assignment.exerciseType)
            _selectedExposureId = State(initialValue: assignment.exposureId)
            _selectedBreathingPattern = State(initialValue: assignment.breathingPattern)
            _selectedRelaxationType = State(initialValue: assignment.relaxation)
            _selectedGroundingType = State(initialValue: assignment.grounding)
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
            } else if preSelectedGroundingType != nil {
                _exerciseType = State(initialValue: .grounding)
                _selectedGroundingType = State(initialValue: preSelectedGroundingType)
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
            .navigationTitle(assignmentToEdit == nil ? "New schedule" : "Edit schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveSchedule()
                    }
                    .disabled(!canSave)
                }
            }
            .alert("Notification permissions", isPresented: $showingPermissionAlert) {
                if permissionDenied {
                    Button("Settings") {
                        if let url = URL(string: "app-settings:") {
                            openURL(url)
                        }
                    }
                    Button("Cancel", role: .cancel) { }
                } else {
                    Button("OK", role: .cancel) { }
                }
            } message: {
                if permissionDenied {
                    Text("Notification permission is required for schedule reminders. Please enable them in settings.")
                } else {
                    Text("Notification permission is required for schedule reminders.")
                }
            }
        }
    }
    
    private var exerciseTypeSection: some View {
        Section {
            Picker("Exercise type", selection: $exerciseType) {
                Text("Exposure").tag(ExerciseType.exposure)
                Text("Breathing").tag(ExerciseType.breathing)
                Text("Relaxation").tag(ExerciseType.relaxation)
                Text("Grounding").tag(ExerciseType.grounding)
                Text("Behavioral activation").tag(ExerciseType.behavioralActivation)
            }
            .onChange(of: exerciseType) {
                // Reset specific selections when type changes
                selectedExposureId = nil
                selectedBreathingPattern = nil
                selectedRelaxationType = nil
                selectedGroundingType = nil
                selectedActivityListId = nil
            }
        } header: {
            Text("Exercise type")
        }
    }
    
    @ViewBuilder
    private var specificExerciseSection: some View {
        switch exerciseType {
        case .exposure:
            Section {
                if exposures.isEmpty {
                    Text("No exposures available")
                        .foregroundStyle(TextColors.secondary)
                } else {
                    Picker("Exposure", selection: $selectedExposureId) {
                        Text("Choose exposure").tag(nil as UUID?)
                        ForEach(exposures) { exposure in
                            Text(exposure.localizedTitle).tag(exposure.id as UUID?)
                        }
                    }
                }
            } header: {
                Text("Exposure")
            }
            
        case .breathing:
            Section {
                Picker("Breathing technique", selection: $selectedBreathingPattern) {
                    Text("Choose technique").tag(nil as BreathingPatternType?)
                    ForEach(BreathingPattern.predefinedPatterns) { pattern in
                        Text(pattern.name).tag(pattern.type as BreathingPatternType?)
                    }
                }
            } header: {
                Text("Breathing technique")
            }
            
        case .relaxation:
            Section {
                Picker("Relaxation", selection: $selectedRelaxationType) {
                    Text("Choose exercise").tag(nil as RelaxationType?)
                    ForEach(RelaxationExercise.predefinedExercises) { exercise in
                        Text(exercise.name).tag(exercise.type as RelaxationType?)
                    }
                }
            } header: {
                Text("Relaxation")
            }
            
        case .grounding:
            Section {
                Picker("Grounding", selection: $selectedGroundingType) {
                    Text("Choose exercise").tag(nil as GroundingType?)
                    ForEach(GroundingExercise.predefinedExercises) { exercise in
                        Text(exercise.name).tag(exercise.type as GroundingType?)
                    }
                }
            } header: {
                Text("Grounding")
            }
            
        case .behavioralActivation:
            Section {
                if activityLists.isEmpty {
                    Text("No activity lists available")
                        .foregroundStyle(TextColors.secondary)
                } else {
                    Picker("Activity list", selection: $selectedActivityListId) {
                        Text("Choose list").tag(nil as UUID?)
                        ForEach(activityLists) { list in
                            Text(list.localizedTitle).tag(list.id as UUID?)
                        }
                    }
                }
            } header: {
                Text("Activity list")
            }
        }
    }
    
    private var timeSection: some View {
        Section {
            DatePicker("Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
        } header: {
            Text("Time")
        }
    }
    
    private var daysSection: some View {
        Section {
            DayOfWeekSelector(selectedDays: $selectedDays)
        } header: {
            Text("Days of week")
        } footer: {
            if selectedDays.isEmpty {
                Text("Select at least one day")
                    .foregroundStyle(.red)
            }
        }
    }
    
    private var activeToggleSection: some View {
        Section {
            Toggle("Active", isOn: $isActive)
        } footer: {
            Text("When active, you will receive reminders at the selected time")
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
        case .grounding:
            return selectedGroundingType != nil
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
                    assignment.grounding = selectedGroundingType
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
                        groundingType: selectedGroundingType,
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

