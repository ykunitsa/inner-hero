import SwiftUI
import SwiftData

struct GroundingExerciseDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    
    let exercise: GroundingExercise
    
    @Query(sort: \ExerciseAssignment.createdAt) private var allAssignments: [ExerciseAssignment]
    @Query(sort: \GroundingSessionResult.performedAt, order: .reverse) private var allSessions: [GroundingSessionResult]
    
    @State private var showScheduleSheet = false
    @State private var isFavorite = false
    
    private var dataManager: DataManager {
        DataManager(modelContext: modelContext)
    }
    
    private var assignments: [ExerciseAssignment] {
        allAssignments.filter { assignment in
            assignment.exerciseType == .grounding && assignment.grounding == exercise.type
        }
    }
    
    private var sessions: [GroundingSessionResult] {
        allSessions.filter { $0.type == exercise.type }
    }
    
    private var averageDurationText: String {
        guard !sessions.isEmpty else { return "—" }
        let total = sessions.reduce(0) { $0 + $1.duration }
        return formatDuration(total / Double(sessions.count))
    }
    
    private var lastSessionDate: Date? {
        sessions.first?.performedAt
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 32) {
                heroHeaderSection
                quickStatsSection
                descriptionCard
                startSessionButton
                sessionsHistoryCard
                scheduleSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 40)
        }
        .background(TopMeshGradientBackground(palette: .purple))
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
                                isFavorite
                                ? LinearGradient(colors: [.pink, .red], startPoint: .topLeading, endPoint: .bottomTrailing)
                                : LinearGradient(colors: [TextColors.tertiary, TextColors.tertiary], startPoint: .topLeading, endPoint: .bottomTrailing)
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
                }
            }
        }
        .sheet(isPresented: $showScheduleSheet) {
            ScheduleExerciseView(
                assignment: nil,
                preSelectedGroundingType: exercise.type
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
                            colors: [.purple.opacity(0.16), .indigo.opacity(0.10)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Image(systemName: exercise.icon)
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .indigo],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            Text(exercise.name)
                .font(.title.weight(.semibold))
                .foregroundStyle(TextColors.primary)
                .multilineTextAlignment(.center)
        }
        .accessibilityElement(children: .combine)
    }
    
    private var quickStatsSection: some View {
        HStack(spacing: 16) {
            QuickStatCard(icon: "list.number", value: "\(exercise.instructionSteps.count)", label: "Шагов", color: .purple)
            QuickStatCard(icon: "clock.fill", value: "\(sessions.count)", label: "Сеансов", color: .purple)
            QuickStatCard(icon: "timer", value: averageDurationText, label: "Средняя", color: .purple)
        }
    }
    
    private var descriptionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "doc.text")
                    .font(.body)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .indigo],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Text("Описание")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(TextColors.primary)
            }
            
            Text(exercise.description)
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
    
    private var startSessionButton: some View {
        NavigationLink(destination: GroundingSessionView(exercise: exercise)) {
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
                            colors: [.purple, .indigo],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .purple.opacity(0.3), radius: 8, x: 0, y: 4)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Начать сеанс")
    }
    
    private var sessionsHistoryCard: some View {
        NavigationLink(destination: GroundingSessionHistoryView(type: exercise.type, title: exercise.name)) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "clock")
                        .font(.body)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .indigo],
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
                
                if sessions.count > 0 {
                    HStack(spacing: 20) {
                        VStack(alignment: .center, spacing: 4) {
                            Text("Всего")
                                .font(.caption)
                                .foregroundStyle(TextColors.secondary)
                            Text("\(sessions.count)")
                                .font(.title2.weight(.semibold))
                                .foregroundStyle(TextColors.primary)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Последний")
                                .font(.caption)
                                .foregroundStyle(TextColors.secondary)
                            
                            if let date = lastSessionDate {
                                Text(date, style: .relative)
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.purple, .indigo],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                } else {
                    Text("Нет завершённых сеансов")
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
            assignments: assignments,
            exerciseType: .grounding,
            exposureId: nil,
            groundingType: exercise.type,
            breathingPatternType: nil,
            relaxationType: nil,
            activityListId: nil
        )
    }
    
    private func toggleFavorite() {
        Task {
            do {
                let newFavoriteStatus = try dataManager.toggleFavorite(
                    exerciseType: .grounding,
                    exerciseIdentifier: exercise.type.rawValue
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
                    exerciseType: .grounding,
                    exerciseIdentifier: exercise.type.rawValue
                )
                await MainActor.run {
                    isFavorite = favorite
                }
            } catch {
                print("Ошибка проверки избранного: \(error)")
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let totalSeconds = Int(duration.rounded())
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return "\(minutes):\(String(format: "%02d", seconds))"
    }
}

#Preview {
    NavigationStack {
        GroundingExerciseDetailView(exercise: GroundingExercise.predefinedExercises[0])
    }
    .modelContainer(for: [ExerciseAssignment.self, FavoriteExercise.self, GroundingSessionResult.self], inMemory: true)
}


