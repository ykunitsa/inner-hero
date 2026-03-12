import SwiftUI
import SwiftData

struct BreathingPatternDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.scheduleViewModel) private var scheduleViewModel
    @Environment(NotificationManager.self) private var notificationManager

    let pattern: BreathingPattern
    
    @Query(sort: \ExerciseAssignment.createdAt) private var allAssignments: [ExerciseAssignment]
    @Query(sort: \BreathingSessionResult.performedAt, order: .reverse) private var allSessions: [BreathingSessionResult]
    @Query(sort: \FavoriteExercise.createdAt, order: .reverse) private var favorites: [FavoriteExercise]
    
    @State private var showScheduleSheet = false
    
    private var isFavorite: Bool {
        FavoritesService.isFavorite(type: .breathing, exerciseId: nil, identifier: pattern.type.rawValue, in: favorites)
    }
    
    private var assignments: [ExerciseAssignment] {
        allAssignments.filter { assignment in
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
        .navigationTitle("Details")
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
                    .accessibilityLabel(isFavorite ? "Remove from favorites" : "Add to favorites")
                    
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
                    .accessibilityLabel("Schedule")
                }
            }
        }
        .sheet(isPresented: $showScheduleSheet) {
            if let viewModel = scheduleViewModel {
                ScheduleExerciseView(
                    assignment: nil,
                    viewModel: viewModel,
                    notificationManager: notificationManager,
                    preSelectedBreathingPattern: pattern.type
                )
            }
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
                label: "Sessions",
                color: .teal
            )
            
            QuickStatCard(
                icon: "timer",
                value: averageDuration.map(formatDurationShort) ?? "—",
                label: "Average",
                color: .orange
            )
            
            QuickStatCard(
                icon: "clock.fill",
                value: lastSessionDate.map(formatRelativeShort) ?? "—",
                label: "Last",
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
                Text("Description")
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
        NavigationLink(value: AppRoute.breathingSession(patternType: pattern.type)) {
            HStack(spacing: 8) {
                Image(systemName: "play.fill")
                    .font(.body)
                Text("Start session")
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
        .accessibilityLabel("Start session")
    }
    
    private var sessionsHistoryCard: some View {
        NavigationLink(value: AppRoute.sessionHistoryBreathing(patternType: pattern.type)) {
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
                    Text("Session history")
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
                            Text("Total")
                                .font(.caption)
                                .foregroundStyle(TextColors.secondary)
                            Text("\(sessions.count)")
                                .font(.title2.weight(.semibold))
                                .foregroundStyle(TextColors.primary)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Last")
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
                    Text("No completed sessions")
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
                _ = try FavoritesService.toggle(
                    type: .breathing,
                    exerciseId: nil,
                    identifier: pattern.type.rawValue,
                    context: modelContext
                )
                await MainActor.run {
                    HapticFeedback.selection()
                }
            } catch {
                print("Error toggling favorite: \(error)")
                HapticFeedback.error()
            }
        }
    }
    
    private func formatDurationShort(_ duration: TimeInterval) -> String {
        let totalSeconds = Int(duration.rounded())
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        if minutes == 0 {
            return String(format: String(localized: "%d s"), seconds)
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


