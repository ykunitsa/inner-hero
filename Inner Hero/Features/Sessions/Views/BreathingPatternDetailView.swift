import SwiftUI
import SwiftData

struct BreathingPatternDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    
    let pattern: BreathingPattern
    
    @Query(sort: \ExerciseAssignment.createdAt) private var allAssignments: [ExerciseAssignment]
    @Query(sort: \BreathingSessionResult.performedAt, order: .reverse) private var allSessions: [BreathingSessionResult]
    
    @State private var showScheduleSheet = false
    @State private var isFavorite = false
    
    private var dataManager: DataManager {
        DataManager(modelContext: modelContext)
    }
    
    private var assignment: ExerciseAssignment? {
        allAssignments.first { assignment in
            assignment.exerciseType == .breathing && assignment.breathingPattern == pattern.type
        }
    }
    
    private var sessions: [BreathingSessionResult] {
        allSessions.filter { $0.patternType == pattern.type }
    }
    
    private var averageDuration: TimeInterval? {
        guard !sessions.isEmpty else { return nil }
        let total = sessions.reduce(0) { $0 + $1.duration }
        return total / Double(sessions.count)
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
        .background(TopMeshGradientBackground(palette: .teal))
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
                assignment: assignment,
                preSelectedBreathingPattern: pattern.type
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
                            colors: [.teal.opacity(0.15), .mint.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Image(systemName: pattern.icon)
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.teal, .mint],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            Text(pattern.localizedName)
                .font(.title.weight(.semibold))
                .foregroundStyle(TextColors.primary)
                .multilineTextAlignment(.center)
        }
        .accessibilityElement(children: .combine)
    }
    
    private var quickStatsSection: some View {
        HStack(spacing: 16) {
            QuickStatCard(
                icon: "chart.bar.fill",
                value: "\(sessions.count)",
                label: "Сеансов",
                color: .teal
            )
            
            QuickStatCard(
                icon: "timer",
                value: averageDuration.map(formatDurationShort) ?? "—",
                label: "Среднее",
                color: .orange
            )
            
            QuickStatCard(
                icon: "clock.fill",
                value: lastSessionDate.map(formatRelativeShort) ?? "—",
                label: "Последний",
                color: .teal
            )
        }
    }
    
    private var descriptionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "doc.text")
                    .font(.body)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.teal, .mint],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Text("Описание")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(TextColors.primary)
            }
            
            Text(pattern.localizedDescription)
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
        NavigationLink(destination: BreathingSessionView(pattern: pattern)) {
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
                            colors: [.teal, .mint],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .teal.opacity(0.3), radius: 8, x: 0, y: 4)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Начать сеанс")
    }
    
    private var sessionsHistoryCard: some View {
        NavigationLink(destination: BreathingSessionHistoryView(patternType: pattern.type, title: pattern.localizedName)) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "clock")
                        .font(.body)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.teal, .mint],
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
                                            colors: [.teal, .mint],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            } else {
                                Text("—")
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(TextColors.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
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
            exerciseType: .breathing,
            exposureId: nil,
            groundingType: nil,
            breathingPatternType: pattern.type,
            relaxationType: nil,
            activityListId: nil
        )
    }
    
    private func toggleFavorite() {
        Task {
            do {
                let newFavoriteStatus = try dataManager.toggleFavorite(
                    exerciseType: .breathing,
                    exerciseIdentifier: pattern.type.rawValue
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
                    exerciseType: .breathing,
                    exerciseIdentifier: pattern.type.rawValue
                )
                await MainActor.run {
                    isFavorite = favorite
                }
            } catch {
                print("Ошибка проверки избранного: \(error)")
            }
        }
    }
    
    private func formatDurationShort(_ duration: TimeInterval) -> String {
        let totalSeconds = Int(duration.rounded())
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        if minutes == 0 {
            return "\(seconds)с"
        }
        return "\(minutes):\(String(format: "%02d", seconds))"
    }
    
    private func formatRelativeShort(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    NavigationStack {
        BreathingPatternDetailView(pattern: BreathingPattern.predefinedPatterns[0])
    }
    .modelContainer(for: [ExerciseAssignment.self, BreathingSessionResult.self, FavoriteExercise.self], inMemory: true)
}


