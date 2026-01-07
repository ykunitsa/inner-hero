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
    
    private var assignment: ExerciseAssignment? {
        allAssignments.first { assignment in
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
                label: "Сеансов",
                color: .mint
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
                            colors: [.mint, .teal],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .mint.opacity(0.28), radius: 8, x: 0, y: 4)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Начать сеанс")
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
                Text("Шаги выполнения")
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
            assignment: assignment,
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
        return "\(seconds)с"
    }
    
    private func localizedStepName(_ step: MuscleGroup) -> String {
        switch step.name {
        case "Hands & Forearms":
            return "Кисти и предплечья"
        case "Upper Arms":
            return "Плечи и бицепсы"
        case "Shoulders":
            return "Плечи"
        case "Face & Jaw":
            return "Лицо и челюсть"
        case "Chest & Back":
            return "Грудь и спина"
        case "Stomach":
            return "Живот"
        case "Legs & Thighs":
            return "Ноги и бёдра"
        case "Feet & Calves":
            return "Стопы и икры"
        case "Upper Body":
            return "Верхняя часть тела"
        case "Face":
            return "Лицо"
        case "Core":
            return "Кор"
        case "Lower Body":
            return "Нижняя часть тела"
        default:
            return step.name
        }
    }
    
    private func localizedStepInstruction(_ step: MuscleGroup) -> String {
        switch (step.name, step.phase) {
        case ("Hands & Forearms", .tension):
            return "Сожмите обе кисти в кулаки. Почувствуйте напряжение в кистях и предплечьях."
        case ("Hands & Forearms", .relaxation):
            return "Разожмите кулаки. Полностью расслабьте руки и отметьте разницу между напряжением и расслаблением."
            
        case ("Upper Arms", .tension):
            return "Согните руки и напрягите бицепсы. Сожмите мышцы настолько, насколько комфортно."
        case ("Upper Arms", .relaxation):
            return "Опустите руки и расслабьте их. Почувствуйте, как напряжение уходит из верхней части рук."
            
        case ("Shoulders", .tension):
            return "Поднимите плечи к ушам. Удерживайте и ощущайте напряжение."
        case ("Shoulders", .relaxation):
            return "Опустите плечи в естественное положение. Дайте им стать тяжёлыми и расслабленными."
            
        case ("Face & Jaw", .tension):
            return "Сильно наморщите лицо: зажмурьте глаза и сожмите челюсть."
        case ("Face & Jaw", .relaxation):
            return "Отпустите напряжение в лице. Челюсть слегка разожмите, глаза расслабьте."
            
        case ("Chest & Back", .tension):
            return "Сделайте глубокий вдох и отведите плечи назад. Слегка прогните спину."
        case ("Chest & Back", .relaxation):
            return "Выдохните и расслабьте грудь и спину. Дышите спокойно и естественно."
            
        case ("Stomach", .tension):
            return "Напрягите мышцы живота. Сделайте живот твёрдым."
        case ("Stomach", .relaxation):
            return "Расслабьте мышцы живота. Пусть живот станет мягким."
            
        case ("Legs & Thighs", .tension):
            return "Напрягите мышцы бёдер. Выпрямите ноги и сделайте их более жёсткими."
        case ("Legs & Thighs", .relaxation):
            return "Полностью расслабьте ноги. Почувствуйте, как они становятся тяжёлыми и свободными."
            
        case ("Feet & Calves", .tension):
            return "Опустите носки вниз и напрягите икры и стопы."
        case ("Feet & Calves", .relaxation):
            return "Отпустите напряжение в стопах и икрах. Дайте им расслабиться естественно."
            
        case ("Upper Body", .tension):
            return "Сожмите кулаки, напрягите руки и поднимите плечи. Удерживайте общее напряжение."
        case ("Upper Body", .relaxation):
            return "Отпустите всё. Пусть руки опустятся, а плечи расслабятся. Почувствуйте облегчение."
            
        case ("Face", .tension):
            return "Наморщите лицо: зажмурьте глаза и сожмите челюсть."
        case ("Face", .relaxation):
            return "Пусть напряжение уйдёт из лица. Расслабьте челюсть и глаза."
            
        case ("Core", .tension):
            return "Сделайте глубокий вдох. Слегка прогните спину и напрягите живот."
        case ("Core", .relaxation):
            return "Выдохните и отпустите напряжение. Пусть спина и живот расслабятся."
            
        case ("Lower Body", .tension):
            return "Выпрямите ноги и направьте носки вниз. Напрягите бёдра, икры и стопы."
        case ("Lower Body", .relaxation):
            return "Полностью расслабьте ноги. Почувствуйте, как они становятся тяжёлыми и спокойными."
            
        default:
            return step.instruction
        }
    }
    
    private func phaseTitle(for phase: MuscleGroup.Phase) -> String {
        switch phase {
        case .tension:
            return "Напрячь"
        case .relaxation:
            return "Расслабить"
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
        RelaxationExerciseDetailView(exercise: RelaxationExercise.predefinedExercises[0])
    }
    .modelContainer(for: [ExerciseAssignment.self, RelaxationSessionResult.self, FavoriteExercise.self], inMemory: true)
}


