import SwiftUI
import SwiftData

struct ScheduleTabView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \ExerciseAssignment.time) private var allAssignments: [ExerciseAssignment]
    @Query(sort: \Exposure.title) private var exposures: [Exposure]
    @Query(sort: \ActivityList.title) private var activityLists: [ActivityList]
    
    @State private var selectedDate: Date = Date()
    
    @State private var showingNewScheduleSheet = false
    @State private var editingAssignment: ExerciseAssignment?
    
    @State private var assignmentToDelete: ExerciseAssignment?
    @State private var showingDeleteAlert = false
    
    @State private var manualCompletions: [ExerciseCompletion] = []
    @State private var manualCompletionByAssignmentId: [UUID: ExerciseCompletion] = [:]
    
    @State private var completedEntries: [CompletedEntry] = []
    @State private var weekProgress: WeekProgress = .empty
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    WeekStripView(selectedDate: $selectedDate)
                        .padding(.top, 8)
                    
                    progressCard
                    
                    plannedSection
                    
                    completedSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .background(TopMeshGradientBackground())
            .navigationTitle("Расписание")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingNewScheduleSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.headline)
                            .foregroundStyle(TextColors.toolbar)
                    }
                    .accessibilityLabel("Добавить расписание")
                }
            }
            .sheet(isPresented: $showingNewScheduleSheet) {
                ScheduleExerciseView()
            }
            .sheet(item: $editingAssignment) { assignment in
                ScheduleExerciseView(assignment: assignment)
            }
            .alert("Удалить расписание?", isPresented: $showingDeleteAlert, presenting: assignmentToDelete) { assignment in
                Button("Отмена", role: .cancel) {
                    assignmentToDelete = nil
                }
                Button("Удалить", role: .destructive) {
                    deleteAssignment(assignment)
                }
            } message: { _ in
                Text("Это действие нельзя отменить.")
            }
            .onAppear {
                refreshDayData()
            }
            .onChange(of: selectedDate) {
                refreshDayData()
            }
        }
    }
    
    private var plannedAssignmentsForSelectedDay: [ExerciseAssignment] {
        let weekday = Calendar.current.component(.weekday, from: selectedDate)
        return allAssignments.filter { $0.hasDay(weekday) }
    }
    
    private var progressCard: some View {
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(
                        LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                Text("Прогресс")
                    .font(.headline)
                    .foregroundStyle(TextColors.primary)
                Spacer()
            }
            
            HStack(spacing: 16) {
                stat(title: "Выполнено (нед.)", value: "\(weekProgress.completedThisWeek)")
                Divider()
                stat(title: "По плану (нед.)", value: "\(weekProgress.plannedDoneThisWeek)")
                Divider()
                stat(title: "Серия", value: "\(weekProgress.streakDays)d")
            }
        }
        .accentCardStyle(accentColor: .blue, cornerRadius: 16, padding: 16)
    }
    
    private func stat(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(TextColors.secondary)
            Text(value)
                .font(.title3.monospacedDigit().weight(.semibold))
                .foregroundStyle(TextColors.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var plannedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Запланировано")
                    .font(.headline)
                    .foregroundStyle(TextColors.primary)
                Spacer()
                
                Button {
                    showingNewScheduleSheet = true
                } label: {
                    Label("Добавить", systemImage: "plus")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.borderless)
            }
            
            if plannedAssignmentsForSelectedDay.isEmpty {
                ContentUnavailableView(
                    "Нет расписаний на день",
                    systemImage: "calendar.badge.exclamationmark",
                    description: Text("Добавьте упражнение в расписание — оно появится здесь")
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            } else {
                VStack(spacing: 0) {
                    ForEach(plannedAssignmentsForSelectedDay) { assignment in
                        plannedRow(assignment)
                            .padding(.vertical, 10)
                        
                        if assignment.id != plannedAssignmentsForSelectedDay.last?.id {
                            Divider()
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
                )
            }
        }
    }
    
    private func plannedRow(_ assignment: ExerciseAssignment) -> some View {
        let isDone = manualCompletionByAssignmentId[assignment.id] != nil
        
        return HStack(spacing: 12) {
            Button {
                toggleManualCompletion(for: assignment)
            } label: {
                Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isDone ? .green : TextColors.tertiary)
                    .accessibilityLabel(isDone ? "Снять отметку выполнения" : "Отметить выполненным")
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(assignmentTitle(assignment))
                    .font(.body.weight(.medium))
                    .foregroundStyle(TextColors.primary)
                    .lineLimit(2)
                
                HStack(spacing: 8) {
                    Text(timeOnlyString(from: assignment.time))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(TextColors.secondary)
                    
                    if !assignment.isActive {
                        Text("Неактивно")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.orange)
                    }
                }
            }
            
            Spacer()
            
            Menu {
                Button {
                    editingAssignment = assignment
                } label: {
                    Label("Редактировать", systemImage: "pencil")
                }
                
                Button(role: .destructive) {
                    assignmentToDelete = assignment
                    showingDeleteAlert = true
                } label: {
                    Label("Удалить", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundStyle(TextColors.tertiary)
                    .touchTarget()
                    .accessibilityLabel("Действия")
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            editingAssignment = assignment
        }
    }
    
    private var completedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Выполнено")
                .font(.headline)
                .foregroundStyle(TextColors.primary)
            
            if completedEntries.isEmpty {
                ContentUnavailableView(
                    "Пока нет выполненного",
                    systemImage: "checkmark.seal",
                    description: Text("Здесь появятся завершённые сессии и ручные отметки за выбранный день")
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            } else {
                VStack(spacing: 0) {
                    ForEach(completedEntries) { entry in
                        completedRow(entry)
                            .padding(.vertical, 10)
                        
                        if entry.id != completedEntries.last?.id {
                            Divider()
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
                )
            }
        }
    }
    
    private func completedRow(_ entry: CompletedEntry) -> some View {
        HStack(spacing: 12) {
            Image(systemName: entry.systemImage)
                .font(.title3)
                .foregroundStyle(entry.tint)
                .frame(width: 28)
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(TextColors.primary)
                    .lineLimit(2)
                
                HStack(spacing: 8) {
                    if let time = entry.timeString {
                        Text(time)
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(TextColors.secondary)
                    }
                    if let detail = entry.detail {
                        Text(detail)
                            .font(.caption)
                            .foregroundStyle(TextColors.secondary)
                    }
                    Spacer(minLength: 0)
                    Text(entry.sourceLabel)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(TextColors.tertiary)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(entry.title). \(entry.sourceLabel)")
    }
    
    // MARK: - Manual completion
    
    private func refreshDayData() {
        refreshManualCompletions()
        refreshCompletedEntries()
        refreshWeekProgress()
    }
    
    private func refreshManualCompletions() {
        let dayStart = Calendar.current.startOfDay(for: selectedDate)
        let descriptor = FetchDescriptor<ExerciseCompletion>(
            predicate: #Predicate { $0.day == dayStart },
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        
        do {
            let results = try modelContext.fetch(descriptor)
            manualCompletions = results
            manualCompletionByAssignmentId = Dictionary(uniqueKeysWithValues: results.map { ($0.assignmentId, $0) })
        } catch {
            manualCompletions = []
            manualCompletionByAssignmentId = [:]
            print("Ошибка загрузки отметок выполнения: \(error)")
        }
    }
    
    private func toggleManualCompletion(for assignment: ExerciseAssignment) {
        let dayStart = Calendar.current.startOfDay(for: selectedDate)
        
        if let existing = manualCompletionByAssignmentId[assignment.id] {
            modelContext.delete(existing)
            HapticFeedback.selection()
        } else {
            let completion = ExerciseCompletion(day: dayStart, assignment: assignment)
            modelContext.insert(completion)
            HapticFeedback.success()
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Ошибка сохранения отметки выполнения: \(error)")
        }
        
        refreshDayData()
    }
    
    private func deleteAssignment(_ assignment: ExerciseAssignment) {
        modelContext.delete(assignment)
        do {
            try modelContext.save()
        } catch {
            print("Ошибка удаления расписания: \(error)")
        }
        assignmentToDelete = nil
        
        // If user had a manual completion for this assignment today, it will remain as snapshot.
        // That's OK; it's stored independently and will still render in the completed section later.
        refreshDayData()
    }
    
    // MARK: - Completed entries aggregation
    
    private func refreshCompletedEntries() {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: selectedDate)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart.addingTimeInterval(24 * 60 * 60)
        
        var entries: [CompletedEntry] = []
        
        // Manual completions (already fetched, but we keep it consistent via a fetch for safety).
        let manualDescriptor = FetchDescriptor<ExerciseCompletion>(
            predicate: #Predicate { $0.day == dayStart },
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        
        do {
            let manual = try modelContext.fetch(manualDescriptor)
            entries.append(contentsOf: manual.map { completion in
                CompletedEntry(
                    id: "manual|\(completion.id.uuidString)",
                    title: completionTitle(completion),
                    time: completion.createdAt,
                    detail: "по плану",
                    sourceLabel: "Отметка",
                    systemImage: "checkmark.circle.fill",
                    tint: .green
                )
            })
        } catch {
            // no-op
        }
        
        // Breathing
        do {
            let descriptor = FetchDescriptor<BreathingSessionResult>(
                predicate: #Predicate { $0.performedAt >= dayStart && $0.performedAt < dayEnd },
                sortBy: [SortDescriptor(\.performedAt, order: .forward)]
            )
            let results = try modelContext.fetch(descriptor)
            entries.append(contentsOf: results.map { result in
                let name = BreathingPattern.predefinedPatterns.first(where: { $0.type == result.patternType })?.localizedName
                    ?? result.patternType.rawValue
                return CompletedEntry(
                    id: "breathing|\(result.id.uuidString)",
                    title: "Дыхание: \(name)",
                    time: result.performedAt,
                    detail: formatDuration(result.duration),
                    sourceLabel: "Сессия",
                    systemImage: "wind",
                    tint: .cyan
                )
            })
        } catch {
            // no-op
        }
        
        // Relaxation
        do {
            let descriptor = FetchDescriptor<RelaxationSessionResult>(
                predicate: #Predicate { $0.performedAt >= dayStart && $0.performedAt < dayEnd },
                sortBy: [SortDescriptor(\.performedAt, order: .forward)]
            )
            let results = try modelContext.fetch(descriptor)
            entries.append(contentsOf: results.map { result in
                let name = RelaxationExercise.predefinedExercises.first(where: { $0.type == result.type })?.name ?? result.type.rawValue
                return CompletedEntry(
                    id: "relaxation|\(result.id.uuidString)",
                    title: "Релаксация: \(name)",
                    time: result.performedAt,
                    detail: formatDuration(result.duration),
                    sourceLabel: "Сессия",
                    systemImage: "figure.mind.and.body",
                    tint: .blue
                )
            })
        } catch {
            // no-op
        }
        
        // Grounding
        do {
            let descriptor = FetchDescriptor<GroundingSessionResult>(
                predicate: #Predicate { $0.performedAt >= dayStart && $0.performedAt < dayEnd },
                sortBy: [SortDescriptor(\.performedAt, order: .forward)]
            )
            let results = try modelContext.fetch(descriptor)
            entries.append(contentsOf: results.map { result in
                let name = GroundingExercise.predefinedExercises.first(where: { $0.type == result.type })?.name ?? result.type.rawValue
                return CompletedEntry(
                    id: "grounding|\(result.id.uuidString)",
                    title: "Заземление: \(name)",
                    time: result.performedAt,
                    detail: formatDuration(result.duration),
                    sourceLabel: "Сессия",
                    systemImage: "brain.head.profile",
                    tint: .indigo
                )
            })
        } catch {
            // no-op
        }
        
        // Exposure (only completed)
        do {
            let descriptor = FetchDescriptor<ExposureSessionResult>(
                predicate: #Predicate { $0.startAt >= dayStart && $0.startAt < dayEnd && $0.endAt != nil },
                sortBy: [SortDescriptor(\.startAt, order: .forward)]
            )
            let results = try modelContext.fetch(descriptor)
            entries.append(contentsOf: results.map { result in
                let title = result.exposure?.title ?? "Экспозиция"
                let duration: TimeInterval = {
                    guard let endAt = result.endAt else { return 0 }
                    return max(0, endAt.timeIntervalSince(result.startAt))
                }()
                return CompletedEntry(
                    id: "exposure|\(result.id.uuidString)",
                    title: "Экспозиция: \(title)",
                    time: result.startAt,
                    detail: duration > 0 ? formatDuration(duration) : nil,
                    sourceLabel: "Сессия",
                    systemImage: "shield.lefthalf.filled",
                    tint: .orange
                )
            })
        } catch {
            // no-op
        }
        
        // Behavioral activation (only completed)
        do {
            let descriptor = FetchDescriptor<BehavioralActivationSession>(
                predicate: #Predicate { $0.startedAt >= dayStart && $0.startedAt < dayEnd && $0.completedAt != nil },
                sortBy: [SortDescriptor(\.startedAt, order: .forward)]
            )
            let results = try modelContext.fetch(descriptor)
            entries.append(contentsOf: results.map { result in
                let duration: TimeInterval = {
                    guard let endAt = result.completedAt else { return 0 }
                    return max(0, endAt.timeIntervalSince(result.startedAt))
                }()
                return CompletedEntry(
                    id: "ba|\(result.id.uuidString)",
                    title: "Активация: \(result.selectedActivity)",
                    time: result.startedAt,
                    detail: duration > 0 ? formatDuration(duration) : nil,
                    sourceLabel: "Сессия",
                    systemImage: "sparkles",
                    tint: .mint
                )
            })
        } catch {
            // no-op
        }
        
        entries.sort { ($0.time ?? .distantPast) < ($1.time ?? .distantPast) }
        completedEntries = entries
    }
    
    private func refreshWeekProgress() {
        let calendar = Calendar.current
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: selectedDate) else {
            weekProgress = .empty
            return
        }
        
        let completedThisWeek = countAllCompletedSessions(from: weekInterval.start, to: weekInterval.end)
        let plannedDoneThisWeek = countManualCompletions(from: weekInterval.start, to: weekInterval.end)
        let streakDays = computeStreakDays(lookbackDays: 60)
        
        weekProgress = WeekProgress(
            completedThisWeek: completedThisWeek + plannedDoneThisWeek,
            plannedDoneThisWeek: plannedDoneThisWeek,
            streakDays: streakDays
        )
    }
    
    private func countManualCompletions(from start: Date, to end: Date) -> Int {
        let startDay = Calendar.current.startOfDay(for: start)
        let endDay = Calendar.current.startOfDay(for: end)
        let descriptor = FetchDescriptor<ExerciseCompletion>(
            predicate: #Predicate { $0.day >= startDay && $0.day < endDay }
        )
        do {
            return try modelContext.fetchCount(descriptor)
        } catch {
            return 0
        }
    }
    
    private func countAllCompletedSessions(from start: Date, to end: Date) -> Int {
        var total = 0
        
        do {
            total += try modelContext.fetchCount(
                FetchDescriptor<BreathingSessionResult>(
                    predicate: #Predicate { $0.performedAt >= start && $0.performedAt < end }
                )
            )
        } catch { }
        
        do {
            total += try modelContext.fetchCount(
                FetchDescriptor<RelaxationSessionResult>(
                    predicate: #Predicate { $0.performedAt >= start && $0.performedAt < end }
                )
            )
        } catch { }
        
        do {
            total += try modelContext.fetchCount(
                FetchDescriptor<GroundingSessionResult>(
                    predicate: #Predicate { $0.performedAt >= start && $0.performedAt < end }
                )
            )
        } catch { }
        
        do {
            total += try modelContext.fetchCount(
                FetchDescriptor<ExposureSessionResult>(
                    predicate: #Predicate { $0.startAt >= start && $0.startAt < end && $0.endAt != nil }
                )
            )
        } catch { }
        
        do {
            total += try modelContext.fetchCount(
                FetchDescriptor<BehavioralActivationSession>(
                    predicate: #Predicate { $0.startedAt >= start && $0.startedAt < end && $0.completedAt != nil }
                )
            )
        } catch { }
        
        return total
    }
    
    private func computeStreakDays(lookbackDays: Int) -> Int {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        guard let lookbackStart = calendar.date(byAdding: .day, value: -(max(1, lookbackDays) - 1), to: todayStart) else {
            return 0
        }
        let end = calendar.date(byAdding: .day, value: 1, to: todayStart) ?? Date()
        
        var daysWithCompletion = Set<Date>()
        
        func insertDay(_ date: Date) {
            daysWithCompletion.insert(calendar.startOfDay(for: date))
        }
        
        // Manual completions
        do {
            let descriptor = FetchDescriptor<ExerciseCompletion>(
                predicate: #Predicate { $0.day >= lookbackStart && $0.day < end }
            )
            let results = try modelContext.fetch(descriptor)
            results.forEach { insertDay($0.day) }
        } catch { }
        
        // Breathing
        do {
            let descriptor = FetchDescriptor<BreathingSessionResult>(
                predicate: #Predicate { $0.performedAt >= lookbackStart && $0.performedAt < end }
            )
            let results = try modelContext.fetch(descriptor)
            results.forEach { insertDay($0.performedAt) }
        } catch { }
        
        // Relaxation
        do {
            let descriptor = FetchDescriptor<RelaxationSessionResult>(
                predicate: #Predicate { $0.performedAt >= lookbackStart && $0.performedAt < end }
            )
            let results = try modelContext.fetch(descriptor)
            results.forEach { insertDay($0.performedAt) }
        } catch { }
        
        // Grounding
        do {
            let descriptor = FetchDescriptor<GroundingSessionResult>(
                predicate: #Predicate { $0.performedAt >= lookbackStart && $0.performedAt < end }
            )
            let results = try modelContext.fetch(descriptor)
            results.forEach { insertDay($0.performedAt) }
        } catch { }
        
        // Exposure (completed)
        do {
            let descriptor = FetchDescriptor<ExposureSessionResult>(
                predicate: #Predicate { $0.startAt >= lookbackStart && $0.startAt < end && $0.endAt != nil }
            )
            let results = try modelContext.fetch(descriptor)
            results.forEach { insertDay($0.startAt) }
        } catch { }
        
        // Behavioral activation (completed)
        do {
            let descriptor = FetchDescriptor<BehavioralActivationSession>(
                predicate: #Predicate { $0.startedAt >= lookbackStart && $0.startedAt < end && $0.completedAt != nil }
            )
            let results = try modelContext.fetch(descriptor)
            results.forEach { insertDay($0.startedAt) }
        } catch { }
        
        // Count consecutive days ending today.
        var streak = 0
        for offset in 0..<lookbackDays {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: todayStart) else { break }
            if daysWithCompletion.contains(day) {
                streak += 1
            } else {
                break
            }
        }
        return streak
    }
    
    private func completionTitle(_ completion: ExerciseCompletion) -> String {
        switch completion.exerciseType {
        case .exposure:
            if let id = completion.exposureId,
               let exposure = exposures.first(where: { $0.id == id }) {
                return "Экспозиция: \(exposure.title)"
            }
            return "Экспозиция"
            
        case .breathing:
            if let raw = completion.breathingPatternType,
               let type = BreathingPatternType(rawValue: raw) {
                let name = BreathingPattern.predefinedPatterns.first(where: { $0.type == type })?.localizedName ?? type.rawValue
                return "Дыхание: \(name)"
            }
            return "Дыхание"
            
        case .relaxation:
            if let raw = completion.relaxationType,
               let type = RelaxationType(rawValue: raw) {
                let name = RelaxationExercise.predefinedExercises.first(where: { $0.type == type })?.name ?? type.rawValue
                return "Релаксация: \(name)"
            }
            return "Релаксация"
            
        case .grounding:
            if let raw = completion.groundingType,
               let type = GroundingType(rawValue: raw) {
                let name = GroundingExercise.predefinedExercises.first(where: { $0.type == type })?.name ?? type.rawValue
                return "Заземление: \(name)"
            }
            return "Заземление"
            
        case .behavioralActivation:
            if let id = completion.activityListId,
               let list = activityLists.first(where: { $0.id == id }) {
                return "Активация: \(list.title)"
            }
            return "Поведенческая активация"
        }
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        Self.durationFormatter.string(from: seconds) ?? ""
    }
    
    // MARK: - Titles
    
    private func assignmentTitle(_ assignment: ExerciseAssignment) -> String {
        switch assignment.exerciseType {
        case .exposure:
            if let id = assignment.exposureId,
               let exposure = exposures.first(where: { $0.id == id }) {
                return "Экспозиция: \(exposure.title)"
            }
            return "Экспозиция"
            
        case .breathing:
            if let type = assignment.breathingPattern {
                return "Дыхание: \(breathingName(type))"
            }
            return "Дыхание"
            
        case .relaxation:
            if let type = assignment.relaxation {
                return "Релаксация: \(relaxationName(type))"
            }
            return "Релаксация"
            
        case .grounding:
            if let type = assignment.grounding {
                return "Заземление: \(groundingName(type))"
            }
            return "Заземление"
            
        case .behavioralActivation:
            if let id = assignment.activityListId,
               let list = activityLists.first(where: { $0.id == id }) {
                return "Активация: \(list.title)"
            }
            return "Поведенческая активация"
        }
    }
    
    private func breathingName(_ type: BreathingPatternType) -> String {
        BreathingPattern.predefinedPatterns.first(where: { $0.type == type })?.name ?? type.rawValue
    }
    
    private func relaxationName(_ type: RelaxationType) -> String {
        RelaxationExercise.predefinedExercises.first(where: { $0.type == type })?.name ?? type.rawValue
    }
    
    private func groundingName(_ type: GroundingType) -> String {
        GroundingExercise.predefinedExercises.first(where: { $0.type == type })?.name ?? String(describing: type)
    }
    
    private func timeOnlyString(from date: Date) -> String {
        Self.timeFormatter.string(from: date)
    }
    
    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = .current
        f.timeStyle = .short
        f.dateStyle = .none
        return f
    }()
    
    private static let durationFormatter: DateComponentsFormatter = {
        let f = DateComponentsFormatter()
        f.allowedUnits = [.minute, .second]
        f.unitsStyle = .abbreviated
        f.zeroFormattingBehavior = .dropAll
        return f
    }()
    
    private struct WeekProgress: Equatable {
        let completedThisWeek: Int
        let plannedDoneThisWeek: Int
        let streakDays: Int
        
        static let empty = WeekProgress(completedThisWeek: 0, plannedDoneThisWeek: 0, streakDays: 0)
    }
    
    private struct CompletedEntry: Identifiable {
        let id: String
        let title: String
        let time: Date?
        let detail: String?
        let sourceLabel: String
        let systemImage: String
        let tint: Color
        
        var timeString: String? {
            guard let time else { return nil }
            return ScheduleTabView.timeFormatter.string(from: time)
        }
    }
}

#Preview {
    ScheduleTabView()
        .modelContainer(
            for: [
                ExerciseAssignment.self,
                ExerciseCompletion.self,
                Exposure.self,
                ActivityList.self
            ],
            inMemory: true
        )
}


