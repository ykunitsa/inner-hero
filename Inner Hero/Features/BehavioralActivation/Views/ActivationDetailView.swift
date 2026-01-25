import SwiftUI
import SwiftData
import Combine

struct ActivationDetailView: View {
    let activation: ActivityList
    let assignment: ExerciseAssignment?
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingEditSheet = false
    @State private var showScheduleSheet = false
    @State private var isFavorite = false
    
    @Query(sort: \ExerciseAssignment.createdAt) private var allAssignments: [ExerciseAssignment]
    
    private var dataManager: DataManager {
        DataManager(modelContext: modelContext)
    }
    
    private var assignments: [ExerciseAssignment] {
        allAssignments.filter { assignment in
            assignment.exerciseType == .behavioralActivation && assignment.activityListId == activation.id
        }
    }
    
    init(activation: ActivityList, assignment: ExerciseAssignment? = nil) {
        self.activation = activation
        self.assignment = assignment
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 32) {
                heroHeaderSection
                quickStatsSection
                purposeCard
                startActivityButton
                activitiesSection
                scheduleSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 40)
        }
        .background(TopMeshGradientBackground(palette: .green))
        .navigationTitle("Детали")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack(spacing: 12) {
                    Button {
                        toggleFavorite()
                    } label: {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .font(.title3)
                            .foregroundStyle(
                                isFavorite ?
                                LinearGradient(
                                    colors: [.pink, .red],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ) :
                                LinearGradient(
                                    colors: [TextColors.tertiary, TextColors.tertiary],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .frame(minWidth: 44, minHeight: 44)
                    .accessibilityLabel(isFavorite ? "Удалить из избранного" : "Добавить в избранное")
                    
                    Button {
                        showScheduleSheet = true
                    } label: {
                        Image(systemName: "calendar.badge.plus")
                            .font(.title3)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.orange, .orange.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .frame(minWidth: 44, minHeight: 44)
                    .accessibilityLabel("Запланировать")
                    
                    if !activation.isPredefined {
                        Button {
                            showingEditSheet = true
                        } label: {
                            Image(systemName: "pencil.circle.fill")
                                .font(.title2)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.green, .mint],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        .frame(minWidth: 44, minHeight: 44)
                        .accessibilityLabel("Редактировать")
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditActivationView(activation: activation)
        }
        .sheet(isPresented: $showScheduleSheet) {
            ScheduleExerciseView(
                assignment: nil,
                preSelectedActivityListId: activation.id
            )
        }
        .onAppear {
            checkFavoriteStatus()
        }
    }
    
    private var heroHeaderSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.green.opacity(0.15), .mint.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                Image(systemName: "figure.walk")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.green, .mint],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: 8) {
                Text(activation.title)
                    .font(.title.weight(.semibold))
                    .foregroundStyle(TextColors.primary)
                    .multilineTextAlignment(.center)
                
                if activation.isPredefined {
                    Text("Предустановленный список")
                        .font(.subheadline)
                        .foregroundStyle(TextColors.tertiary)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
    
    private var quickStatsSection: some View {
        HStack(spacing: 16) {
            QuickStatCard(
                icon: "list.bullet",
                value: "\(activation.activities.count)",
                label: "Активности",
                color: .green
            )
            
            QuickStatCard(
                icon: activation.isPredefined ? "lock.fill" : "person.fill",
                value: activation.isPredefined ? "Предустановленный" : "Созданный",
                label: "Тип",
                color: .mint
            )
        }
    }
    
    private var purposeCard: some View {
        infoCard(
            title: "Для чего это",
            icon: "target",
            accent: LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing)
        ) {
            Text(
                """
                Поведенческая активация помогает мягко «включаться» в жизнь, когда нет сил, настроения или мотивации. \
                Вы заранее выбираете простые действия (приятные или значимые), делаете их маленькими шагами и замечаете, \
                как меняются состояние и уровень удовольствия.
                """
            )
        }
    }
    
    private func infoCard(
        title: String,
        icon: String,
        accent: LinearGradient,
        @ViewBuilder content: () -> some View
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(accent)
                
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(TextColors.primary)
            }
            
            content()
                .font(.body)
                .foregroundStyle(TextColors.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
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
    }
    
    private var activitiesSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "checklist")
                    .font(.body)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.green, .mint],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Text("Активности")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(TextColors.primary)
            }
            
            if activation.activities.isEmpty {
                Text("Пока нет активностей")
                    .font(.body)
                    .foregroundStyle(TextColors.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 32)
            } else {
                ActivityGroupCard(activities: activation.activities)
            }
        }
    }
    
    private var scheduleSection: some View {
        ExerciseScheduleSection(
            assignments: assignments,
            exerciseType: .behavioralActivation,
            exposureId: nil,
            groundingType: nil,
            breathingPatternType: nil,
            relaxationType: nil,
            activityListId: activation.id
        )
    }
    
    private var startActivityButton: some View {
        NavigationLink(destination: StartActivationView(activation: activation, assignment: assignment)) {
            HStack(spacing: 8) {
                Image(systemName: "play.fill")
                    .font(.body)
                Text("Начать сеанс")
                    .font(.system(size: 17, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [.green, .mint],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
            )
        }
        .buttonStyle(.plain)
        .disabled(activation.activities.isEmpty)
        .opacity(activation.activities.isEmpty ? 0.5 : 1.0)
        .accessibilityLabel("Начать сеанс поведенческой активации")
    }
    
    private func toggleFavorite() {
        do {
            let newFavoriteStatus = try dataManager.toggleFavorite(
                exerciseType: .behavioralActivation,
                exerciseId: activation.id
            )
            isFavorite = newFavoriteStatus
            HapticFeedback.selection()
        } catch {
            HapticFeedback.error()
        }
    }
    
    private func checkFavoriteStatus() {
        do {
            let favorite = try dataManager.isFavorite(
                exerciseType: .behavioralActivation,
                exerciseId: activation.id
            )
            isFavorite = favorite
        } catch {
            isFavorite = false
        }
    }
}

// MARK: - Supporting Views

struct ActivityRowCard: View {
    @Environment(\.colorScheme) private var colorScheme
    
    let activity: String
    let index: Int
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 36, height: 36)
                Text("\(index + 1)")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.green)
            }
            
            Text(activity)
                .font(.body)
                .foregroundStyle(TextColors.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.thinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(.primary.opacity(colorScheme == .dark ? 0.18 : 0.06), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Активность \(index + 1): \(activity)")
    }
}

struct ActivityGroupCard: View {
    @Environment(\.colorScheme) private var colorScheme
    
    let activities: [String]
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(activities.indices, id: \.self) { idx in
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 7, weight: .semibold))
                        .foregroundStyle(.green.opacity(0.8))
                        .padding(.top, 7)
                    
                    Text(activities[idx])
                        .font(.body)
                        .foregroundStyle(TextColors.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                
                if idx != activities.indices.last {
                    Divider()
                        .padding(.leading, 16)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.thinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(.primary.opacity(colorScheme == .dark ? 0.18 : 0.06), lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Список активностей")
    }
}

// MARK: - Start Activation View

struct StartActivationView: View {
    let activation: ActivityList
    let assignment: ExerciseAssignment?
    
    @State private var showingActivityList = false
    @State private var selectedActivity: String?
    @State private var navigateToSession = false

    @State private var isRouletteRunning = false
    @State private var rouletteActivity: String?
    @State private var rouletteTask: Task<Void, Never>?
    
    init(activation: ActivityList, assignment: ExerciseAssignment? = nil) {
        self.activation = activation
        self.assignment = assignment
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 32) {
                Spacer()
                
                // Header
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.green.opacity(0.15), .mint.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                        Image(systemName: "figure.walk")
                            .font(.system(size: 40))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.green, .mint],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    
                    VStack(spacing: 8) {
                        Text(activation.title)
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(TextColors.primary)
                            .multilineTextAlignment(.center)
                        
                        if isRouletteRunning {
                            Text("Выбираем активность…")
                                .font(.subheadline)
                                .foregroundStyle(TextColors.secondary)
                                .multilineTextAlignment(.center)

                            if let rouletteActivity {
                                Text(rouletteActivity)
                                    .font(.headline.weight(.semibold))
                                    .foregroundStyle(TextColors.primary)
                                    .multilineTextAlignment(.center)
                                    .id(rouletteActivity)
                                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
                            }
                        } else {
                            Text("Выберите способ выбора активности")
                                .font(.subheadline)
                                .foregroundStyle(TextColors.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()

                Spacer()
            }
        }
        .navigationTitle("Начать сеанс")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .tint(.green)
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                Button {
                    guard !isRouletteRunning else { return }
                    showingActivityList = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "list.bullet")
                            .font(.body)
                        Text("Список")
                    }
                    .foregroundStyle(.green)
                }
                .disabled(activation.activities.isEmpty || isRouletteRunning)
                .accessibilityLabel("Выбрать из списка")
                .accessibilityHint("Открывает список активностей для выбора")
                
                Spacer()
                
                Button {
                    runRouletteRandomPick()
                } label: {
                    HStack(spacing: 8) {
                        if isRouletteRunning {
                            ProgressView()
                                .tint(.green)
                            Text("Выбираем…")
                        } else {
                            Image(systemName: "shuffle")
                                .font(.body)
                            Text("Случайно")
                        }
                    }
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.green)
                }
                .disabled(activation.activities.isEmpty || isRouletteRunning)
                .accessibilityLabel("Случайная активность")
                .accessibilityHint("Выбирает случайную активность и начинает сеанс")
            }
        }
        .sheet(isPresented: $showingActivityList) {
            ActivitySelectionSheet(
                activities: activation.activities,
                onSelect: { activity in
                    selectedActivity = activity
                    showingActivityList = false
                    navigateToSession = true
                }
            )
        }
        .navigationDestination(isPresented: $navigateToSession) {
            if let activity = selectedActivity {
                ActivationSessionView(
                    activation: activation,
                    selectedActivity: activity,
                    assignment: self.assignment
                )
            }
        }
        .onDisappear {
            rouletteTask?.cancel()
            rouletteTask = nil
        }
    }

    private func runRouletteRandomPick() {
        guard !activation.activities.isEmpty else { return }
        guard !isRouletteRunning else { return }

        rouletteTask?.cancel()

        isRouletteRunning = true

        withAnimation(.easeInOut(duration: 0.12)) {
            rouletteActivity = activation.activities.randomElement()
        }

        rouletteTask = Task { @MainActor in
            let pool = activation.activities
            let totalSteps = min(max(12, pool.count * 2), 20)

            var delay: UInt64 = 60_000_000
            for _ in 0..<totalSteps {
                guard !Task.isCancelled else {
                    isRouletteRunning = false
                    return
                }

                let next = pool.randomElement() ?? rouletteActivity
                withAnimation(.easeInOut(duration: 0.12)) {
                    rouletteActivity = next
                }

                try? await Task.sleep(nanoseconds: delay)
                delay = min(delay + 18_000_000, 140_000_000)
            }

            guard !Task.isCancelled else {
                isRouletteRunning = false
                return
            }

            if let final = pool.randomElement() {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    rouletteActivity = final
                }

                HapticFeedback.selection()
                selectedActivity = final
                try? await Task.sleep(nanoseconds: 250_000_000)
                isRouletteRunning = false
                navigateToSession = true
            } else {
                isRouletteRunning = false
            }
        }
    }
}

// MARK: - Activity Selection Sheet

struct ActivitySelectionSheet: View {
    let activities: [String]
    let onSelect: (String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(activities.indices, id: \.self) { index in
                        let activity = activities[index]
                        Button {
                            HapticFeedback.selection()
                            onSelect(activity)
                        } label: {
                            HStack(alignment: .center, spacing: 16) {
                                Circle()
                                    .fill(Color.green.opacity(0.22))
                                    .frame(width: 10, height: 10)
                                
                                Text(activity)
                                    .font(.body)
                                    .foregroundStyle(TextColors.primary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .multilineTextAlignment(.leading)
                                
                                Image(systemName: "chevron.right")
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(TextColors.tertiary)
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(.thinMaterial)
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(activity)
                        .accessibilityHint("Выбрать активность")
                    }
                }
                .padding(20)
            }
            .navigationTitle("Выбор активности")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Activation Session View

struct ActivationSessionView: View {
    let activation: ActivityList
    let selectedActivity: String
    let assignment: ExerciseAssignment?
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var sessionStartTime = Date()
    @State private var showingCompletionView = false
    @State private var isCompleted = false
    @State private var currentTime = Date()
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    private var dataManager: DataManager {
        DataManager(modelContext: modelContext)
    }
    
    init(activation: ActivityList, selectedActivity: String, assignment: ExerciseAssignment? = nil) {
        self.activation = activation
        self.selectedActivity = selectedActivity
        self.assignment = assignment
    }
    
    private var formattedStartTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: sessionStartTime)
    }
    
    private var elapsedTime: String {
        let elapsed = currentTime.timeIntervalSince(sessionStartTime)
        let minutes = Int(elapsed) / 60
        let seconds = Int(elapsed) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var body: some View {
        ZStack {
            TopMeshGradientBackground(palette: .green)
            
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.green.opacity(0.15), .mint.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 100, height: 100)
                            Image(systemName: "figure.walk")
                                .font(.system(size: 50))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.green, .mint],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        
                        VStack(spacing: 8) {
                            Text("Ваша активность")
                                .font(.subheadline)
                                .foregroundStyle(TextColors.tertiary)
                            
                            Text(selectedActivity)
                                .font(.title2.weight(.semibold))
                                .foregroundStyle(TextColors.primary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.top, 20)
                    
                    // Time info card
                    HStack(spacing: 20) {
                        VStack(spacing: 4) {
                            Text("Начало")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(TextColors.tertiary)
                            Text(formattedStartTime)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(TextColors.primary)
                                .monospacedDigit()
                        }
                        .frame(maxWidth: .infinity)
                        
                        Divider()
                            .frame(height: 32)
                        
                        VStack(spacing: 4) {
                            Text("Длительность")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(TextColors.tertiary)
                            Text(elapsedTime)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.green)
                                .monospacedDigit()
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.thinMaterial)
                            .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(.primary.opacity(colorScheme == .dark ? 0.18 : 0.06), lineWidth: 1)
                    )
                    .padding(.horizontal, 20)
                    
                    // Instructions card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .font(.title3)
                                .foregroundStyle(.green)
                            Text("Инструкции")
                                .font(.headline)
                                .foregroundStyle(TextColors.primary)
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            InstructionRow(
                                number: 1,
                                text: "Выполняйте активность в комфортном темпе"
                            )
                            InstructionRow(
                                number: 2,
                                text: "Сконцентрируйтесь на ощущениях в настоящем моменте"
                            )
                            InstructionRow(
                                number: 3,
                                text: "Отмечайте, как вы себя чувствуете во время и после"
                            )
                            InstructionRow(
                                number: 4,
                                text: "После завершения оцените уровень удовольствия"
                            )
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.thinMaterial)
                            .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(.primary.opacity(colorScheme == .dark ? 0.18 : 0.06), lineWidth: 1)
                    )
                    .padding(.horizontal, 20)
                    
                    // Complete button
                    if !isCompleted {
                        Button {
                            showingCompletionView = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.body)
                                Text("Завершить")
                                    .font(.system(size: 17, weight: .semibold))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [.green, .mint],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .navigationTitle(activation.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .onReceive(timer) { _ in
            currentTime = Date()
        }
        .onAppear {
            sessionStartTime = Date()
            currentTime = Date()
        }
        .sheet(isPresented: $showingCompletionView) {
            ActivationCompletionView(
                activityName: selectedActivity,
                startedAt: sessionStartTime,
                onComplete: { rating in
                    completeSession(rating: rating)
                }
            )
        }
    }
    
    private func completeSession(rating: Int?) {
        let session = BehavioralActivationSession(
            startedAt: sessionStartTime,
            completedAt: Date(),
            selectedActivity: selectedActivity,
            pleasureRating: rating
        )
        
        modelContext.insert(session)
        
        do {
            try modelContext.save()
            
            if let assignment = self.assignment {
                try self.dataManager.markAssignmentCompletedIfNeeded(assignment: assignment)
            }
            HapticFeedback.success()
            isCompleted = true
            
            // Dismiss after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                dismiss()
            }
        } catch {
            print("Не удалось сохранить сеанс: \(error)")
        }
    }
}

// MARK: - Supporting Views

struct InstructionRow: View {
    let number: Int
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 24, height: 24)
                Text("\(number)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.green)
            }
            
            Text(text)
                .font(.body)
                .foregroundStyle(TextColors.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    NavigationStack {
        ActivationDetailView(
            activation: ActivityList(
                title: "Утренняя рутина",
                activities: ["Разминка 30 минут", "Медитация", "Полезный завтрак", "Чтение 15 минут"],
                isPredefined: false
            )
        )
    }
    .modelContainer(for: ActivityList.self, inMemory: true)
}

