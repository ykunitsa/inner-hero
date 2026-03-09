import SwiftUI
import SwiftData

struct RelaxationExerciseDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    
    let exercise: RelaxationExercise
    
    @Query(sort: \ExerciseAssignment.createdAt) private var allAssignments: [ExerciseAssignment]
    @Query(sort: \RelaxationSessionResult.performedAt, order: .reverse) private var allSessions: [RelaxationSessionResult]
    
    @State private var showScheduleSheet = false
    @State private var isFavorite = false
    
    private var dataManager: DataManager {
        DataManager(modelContext: modelContext)
    }
    
    private var assignments: [ExerciseAssignment] {
        allAssignments.filter { assignment in
            assignment.exerciseType == .relaxation && assignment.relaxation == exercise.type
        }
    }
    
    private var sessions: [RelaxationSessionResult] {
        allSessions.filter { $0.type == exercise.type }
    }
    
    private var lastSessionDate: Date? {
        sessions.first?.performedAt
    }
    
    private var averageDuration: TimeInterval? {
        guard !sessions.isEmpty else { return nil }
        let total = sessions.reduce(0) { $0 + $1.duration }
        return total / Double(sessions.count)
    }
    
    private var steps: [MuscleGroup] {
        MuscleGroup.groups(for: exercise.type)
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 32) {
                heroHeaderSection
                quickStatsSection
                purposeCard
                howToCard
                startSessionButton
                stepsSection
                scheduleSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 40)
        }
        .background(TopMeshGradientBackground(palette: .mint))
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
            ScheduleExerciseView(
                assignment: nil,
                preSelectedRelaxationType: exercise.type
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
                            colors: [.mint.opacity(0.16), .teal.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Image(systemName: exercise.icon)
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.mint, .teal],
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
            QuickStatCard(
                icon: "chart.bar.fill",
                value: "\(sessions.count)",
                label: "Sessions",
                color: .mint
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
                color: .mint
            )
        }
    }
    
    private var purposeCard: some View {
        infoCard(
            title: "Для чего это",
            icon: "target",
            accent: LinearGradient(colors: [.mint, .teal], startPoint: .topLeading, endPoint: .bottomTrailing)
        ) {
            Text(
                """
                Прогрессивная мышечная релаксация помогает снизить тревогу и телесное напряжение через осознанное чередование «напрячь» → «расслабить». \
                Вы учитесь быстрее замечать, где в теле накапливается стресс, и мягко отпускать его.
                """
            )
        }
    }
    
    private var howToCard: some View {
        infoCard(
            title: "Как выполнять",
            icon: "list.bullet.rectangle",
            accent: LinearGradient(colors: [.mint, .teal], startPoint: .topLeading, endPoint: .bottomTrailing)
        ) {
            Text(
                """
                Устройтесь удобно. На этапе «Напрячь» напрягайте указанную группу мышц умеренно (без боли) и удерживайте напряжение. \
                На этапе «Расслабить» полностью отпустите мышцы и обратите внимание на ощущения. Дышите ровно и спокойно.\n\n\
                Совет: если вам сложно напрягать мышцу, делайте это мягче или пропускайте шаг — важно оставаться в комфорте.
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
    
    private var startSessionButton: some View {
        NavigationLink(destination: MuscleRelaxationSessionView(exercise: exercise)) {
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
                            colors: [.mint, .teal],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .mint.opacity(0.28), radius: 8, x: 0, y: 4)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Start session")
    }
    
    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "checklist")
                    .font(.body)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.mint, .teal],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Text("Steps")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(TextColors.primary)
            }
            
            VStack(spacing: 12) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    stepCard(step: step, index: index)
                }
            }
        }
    }
    
    private func stepCard(step: MuscleGroup, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(step.phase == .tension ? Color.orange.opacity(0.12) : Color.mint.opacity(0.12))
                        .frame(width: 36, height: 36)
                    Text("\(index + 1)")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(step.phase == .tension ? .orange : .mint)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(localizedStepName(step))
                        .font(.body.weight(.semibold))
                        .foregroundStyle(TextColors.primary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    HStack(spacing: 8) {
                        Label(phaseTitle(for: step.phase), systemImage: step.phase == .tension ? "bolt.fill" : "leaf.fill")
                            .labelStyle(.titleAndIcon)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(step.phase == .tension ? .orange : .mint)
                        
                        Text("•")
                            .font(.caption)
                            .foregroundStyle(TextColors.tertiary)
                        
                        Text(durationString(step.duration))
                            .font(.caption.weight(.medium))
                            .foregroundStyle(TextColors.secondary)
                    }
                }
                
                Spacer(minLength: 0)
            }
            
            Text(localizedStepInstruction(step))
                .font(.subheadline)
                .foregroundStyle(TextColors.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.thinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(.primary.opacity(colorScheme == .dark ? 0.18 : 0.06), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }
    
    private var scheduleSection: some View {
        ExerciseScheduleSection(
            assignments: assignments,
            exerciseType: .relaxation,
            exposureId: nil,
            groundingType: nil,
            breathingPatternType: nil,
            relaxationType: exercise.type,
            activityListId: nil
        )
    }
    
    private func toggleFavorite() {
        Task {
            do {
                let newFavoriteStatus = try dataManager.toggleFavorite(
                    exerciseType: .relaxation,
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
                    exerciseType: .relaxation,
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
    
    private func durationString(_ duration: TimeInterval) -> String {
        let seconds = Int(duration.rounded())
        return String(format: String(localized: "%d s"), seconds)
    }
    
    private func localizedStepName(_ step: MuscleGroup) -> String {
        switch step.name {
        case "Hands & Forearms":
            return String(localized: "Hands & Forearms")
        case "Upper Arms":
            return String(localized: "Upper Arms")
        case "Shoulders":
            return String(localized: "Shoulders")
        case "Face & Jaw":
            return String(localized: "Face & Jaw")
        case "Chest & Back":
            return String(localized: "Chest & Back")
        case "Stomach":
            return String(localized: "Stomach")
        case "Legs & Thighs":
            return String(localized: "Legs & Thighs")
        case "Feet & Calves":
            return String(localized: "Feet & Calves")
        case "Upper Body":
            return String(localized: "Upper Body")
        case "Face":
            return String(localized: "Face")
        case "Core":
            return String(localized: "Core")
        case "Lower Body":
            return String(localized: "Lower Body")
        default:
            return step.name
        }
    }
    
    private func localizedStepInstruction(_ step: MuscleGroup) -> String {
        switch (step.name, step.phase) {
        case ("Hands & Forearms", .tension):
            return String(localized: "Clench both hands into fists. Feel the tension in your hands and forearms.")
        case ("Hands & Forearms", .relaxation):
            return String(localized: "Unclench your fists. Fully relax your arms and notice the difference between tension and relaxation.")
            
        case ("Upper Arms", .tension):
            return String(localized: "Bend your arms and tense your biceps. Squeeze as much as is comfortable.")
        case ("Upper Arms", .relaxation):
            return String(localized: "Lower your arms and relax them. Feel the tension leave your upper arms.")
            
        case ("Shoulders", .tension):
            return String(localized: "Raise your shoulders toward your ears. Hold and feel the tension.")
        case ("Shoulders", .relaxation):
            return String(localized: "Lower your shoulders to a natural position. Let them feel heavy and relaxed.")
            
        case ("Face & Jaw", .tension):
            return String(localized: "Scrunch your face: squeeze your eyes shut and clench your jaw.")
        case ("Face & Jaw", .relaxation):
            return String(localized: "Release the tension in your face. Relax your jaw and eyes.")
            
        case ("Chest & Back", .tension):
            return String(localized: "Take a deep breath and pull your shoulders back. Slightly arch your back.")
        case ("Chest & Back", .relaxation):
            return String(localized: "Exhale and relax your chest and back. Breathe calmly and naturally.")
            
        case ("Stomach", .tension):
            return String(localized: "Tense your stomach muscles. Make your belly firm.")
        case ("Stomach", .relaxation):
            return String(localized: "Relax your stomach muscles. Let your belly go soft.")
            
        case ("Legs & Thighs", .tension):
            return String(localized: "Tense your thigh muscles. Straighten your legs and make them stiff.")
        case ("Legs & Thighs", .relaxation):
            return String(localized: "Fully relax your legs. Feel them become heavy and loose.")
            
        case ("Feet & Calves", .tension):
            return String(localized: "Point your toes down and tense your calves and feet.")
        case ("Feet & Calves", .relaxation):
            return String(localized: "Release the tension in your feet and calves. Let them relax naturally.")
            
        case ("Upper Body", .tension):
            return String(localized: "Clench your fists, tense your arms, and raise your shoulders. Hold the overall tension.")
        case ("Upper Body", .relaxation):
            return String(localized: "Let everything go. Let your arms drop and shoulders relax. Feel the relief.")
            
        case ("Face", .tension):
            return String(localized: "Scrunch your face: squeeze your eyes shut and clench your jaw.")
        case ("Face", .relaxation):
            return String(localized: "Let the tension leave your face. Relax your jaw and eyes.")
            
        case ("Core", .tension):
            return String(localized: "Take a deep breath. Slightly arch your back and tense your stomach.")
        case ("Core", .relaxation):
            return String(localized: "Exhale and release the tension. Let your back and stomach relax.")
            
        case ("Lower Body", .tension):
            return String(localized: "Straighten your legs and point your toes down. Tense your thighs, calves, and feet.")
        case ("Lower Body", .relaxation):
            return String(localized: "Fully relax your legs. Feel them become heavy and calm.")
            
        default:
            return step.instruction
        }
    }
    
    private func phaseTitle(for phase: MuscleGroup.Phase) -> String {
        switch phase {
        case .tension:
            return String(localized: "Tense")
        case .relaxation:
            return String(localized: "Relax")
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
        RelaxationExerciseDetailView(exercise: RelaxationExercise.predefinedExercises[0])
    }
    .modelContainer(for: [ExerciseAssignment.self, RelaxationSessionResult.self, FavoriteExercise.self], inMemory: true)
}


