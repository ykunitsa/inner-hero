import SwiftUI
import SwiftData

struct ExposureDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    let exposure: Exposure
    let onStartSession: () -> Void
    
    @Query(sort: \ExerciseAssignment.createdAt) private var allAssignments: [ExerciseAssignment]
    @State private var showScheduleSheet = false
    @State private var isFavorite = false
    
    private var dataManager: DataManager {
        DataManager(modelContext: modelContext)
    }
    
    private var totalSteps: Int { exposure.steps.count }
    private var stepsWithTimer: Int { exposure.steps.filter { $0.hasTimer }.count }
    
    private var assignment: ExerciseAssignment? {
        allAssignments.first { assignment in
            assignment.exerciseType == .exposure && assignment.exposureId == exposure.id
        }
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 32) {
                heroHeaderSection
                quickStatsSection
                descriptionCard
                if !exposure.steps.isEmpty {
                    stepsSection
                }
                sessionsHistoryCard
                scheduleSection
                startSessionButton
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 40)
        }
        .background(TopMeshGradientBackground())
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
                    
                    NavigationLink(destination: EditExposureView(exposure: exposure)) {
                        Image(systemName: "pencil.circle.fill")
                            .font(.title2)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .cyan],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .frame(minWidth: 44, minHeight: 44)
                }
            }
        }
        .sheet(isPresented: $showScheduleSheet) {
            ScheduleExerciseView(preSelectedExposureId: exposure.id)
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
                            colors: [.blue.opacity(0.15), .cyan.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                Image(systemName: "figure.mind.and.body")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            Text(exposure.title)
                .font(.title.weight(.semibold))
                .foregroundStyle(TextColors.primary)
                .multilineTextAlignment(.center)
        }
        .accessibilityElement(children: .combine)
    }
    
    private var quickStatsSection: some View {
        HStack(spacing: 16) {
            QuickStatCard(icon: "list.number", value: "\(totalSteps)", label: "Шагов", color: .blue)
            QuickStatCard(icon: "timer", value: "\(stepsWithTimer)", label: "С таймером", color: .orange)
            QuickStatCard(icon: "chart.bar.fill", value: "\(exposure.sessionResults.count)", label: "Сеансов", color: .blue)
        }
    }
    
    private var descriptionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "doc.text")
                    .font(.body)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Text("Описание")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(TextColors.primary)
            }
            
            Text(exposure.exposureDescription)
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
    
    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "checklist")
                    .font(.body)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Text("Шаги выполнения")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(TextColors.primary)
            }
            
            VStack(spacing: 12) {
                ForEach(Array(exposure.steps.enumerated()), id: \.offset) { index, step in
                    StepDetailCard(step: step, index: index)
                }
            }
        }
    }
    
    private var sessionsHistoryCard: some View {
        NavigationLink(destination: SessionHistoryView(exposure: exposure)) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "clock")
                        .font(.body)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Text("История сеансов")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(TextColors.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(TextColors.secondary)
                }
                
                if exposure.sessionResults.count > 0 {
                    HStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Всего")
                                .font(.caption)
                                .foregroundStyle(TextColors.secondary)
                            Text("\(exposure.sessionResults.count)")
                                .font(.title2.weight(.semibold))
                                .foregroundStyle(TextColors.primary)
                        }
                        
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Последний")
                                .font(.caption)
                                .foregroundStyle(TextColors.secondary)
                            if let lastSession = exposure.sessionResults.sorted(by: { $0.startAt > $1.startAt }).first {
                                Text(lastSession.startAt, style: .relative)
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.blue, .cyan],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            }
                        }
                    }
                } else {
                    Text("Нет завершенных сеансов")
                        .font(.body)
                        .foregroundStyle(TextColors.secondary)
                }
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
        .buttonStyle(.plain)
    }
    
    private var scheduleSection: some View {
        ExerciseScheduleSection(
            assignment: assignment,
            exerciseType: .exposure,
            exposureId: exposure.id,
            breathingPatternType: nil,
            relaxationType: nil,
            activityListId: nil
        )
    }
    
    private var startSessionButton: some View {
        Button(action: onStartSession) {
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
                            colors: [.blue, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
            )
        }
        .accessibilityLabel("Начать сеанс")
    }
    
    private func toggleFavorite() {
        Task {
            do {
                let newFavoriteStatus = try dataManager.toggleFavorite(
                    exerciseType: .exposure,
                    exerciseId: exposure.id
                )
                await MainActor.run {
                    isFavorite = newFavoriteStatus
                    HapticFeedback.selection()
                }
            } catch {
                print("Ошибка переключения избранного: \(error)")
                HapticFeedback.error()
            }
        }
    }
    
    private func checkFavoriteStatus() {
        Task {
            do {
                let favorite = try dataManager.isFavorite(
                    exerciseType: .exposure,
                    exerciseId: exposure.id
                )
                await MainActor.run {
                    isFavorite = favorite
                }
            } catch {
                print("Ошибка проверки избранного: \(error)")
            }
        }
    }
}

// MARK: - Supporting Views

struct QuickStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(
                    LinearGradient(
                        colors: color == .blue ? [.blue, .cyan] : [color, color.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Text(value)
                .font(.title3.weight(.semibold))
                .foregroundStyle(TextColors.primary)
            Text(label)
                .font(.caption)
                .foregroundStyle(TextColors.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.thinMaterial)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(value) \(label)")
    }
}

struct StepDetailCard: View {
    let step: ExposureStep
    let index: Int
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 36, height: 36)
                Text("\(index + 1)")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.blue)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(step.text)
                    .font(.body)
                    .foregroundStyle(TextColors.primary)
                    .fixedSize(horizontal: false, vertical: true)
                
                if step.hasTimer {
                    HStack(spacing: 6) {
                        Image(systemName: "timer")
                            .font(.caption)
                        Text("\(step.timerDuration / 60):\(String(format: "%02d", step.timerDuration % 60))")
                            .font(.caption.weight(.medium))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [.orange, .orange.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.thinMaterial)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Шаг \(index + 1): \(step.text)")
    }
}
