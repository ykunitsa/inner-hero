import SwiftUI
import SwiftData

// MARK: - MuscleRelaxationListView

struct MuscleRelaxationListView: View {
    @Query(sort: \ExerciseAssignment.createdAt) private var allAssignments: [ExerciseAssignment]
    @State private var exerciseToSchedule: RelaxationExercise?
    @State private var showScheduleSheet = false
    @State private var selectedRelaxationType: RelaxationType?
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(RelaxationExercise.predefinedExercises) { exercise in
                        let assignment = allAssignments.first { assignment in
                            assignment.exerciseType == .relaxation && assignment.relaxation == exercise.type
                        }
                        
                        NavigationLink {
                            MuscleRelaxationSessionView(exercise: exercise)
                        } label: {
                            RelaxationExerciseRow(
                                exercise: exercise,
                                assignment: assignment,
                                onSchedule: {
                                    selectedRelaxationType = exercise.type
                                    showScheduleSheet = true
                                }
                            )
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button {
                                exerciseToSchedule = exercise
                                showScheduleSheet = true
                            } label: {
                                Label("Запланировать", systemImage: "calendar.badge.plus")
                            }
                            .tint(.orange)
                        }
                    }
                } header: {
                    VStack(spacing: Spacing.xs) {
                        Image(systemName: "figure.mind.and.body")
                            .font(.system(size: 48))
                            .foregroundStyle(.mint.gradient)
                            .accessibilityHidden(true)
                        
                        Text("Progressive muscle relaxation techniques to release physical tension and promote calm")
                            .font(.subheadline)
                            .foregroundStyle(TextColors.secondary)
                            .multilineTextAlignment(.center)
                            .textCase(.none)
                            .padding(.top, Spacing.xxs)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                }
            }
            .navigationTitle("Muscle Relaxation")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showScheduleSheet) {
                if let relaxationType = selectedRelaxationType {
                    ScheduleExerciseView(preSelectedRelaxationType: relaxationType)
                }
            }
        }
    }
}

// MARK: - RelaxationExerciseRow

struct RelaxationExerciseRow: View {
    @Environment(\.modelContext) private var modelContext
    let exercise: RelaxationExercise
    let assignment: ExerciseAssignment?
    let onSchedule: (() -> Void)?
    @State private var isFavorite = false
    
    private var dataManager: DataManager {
        DataManager(modelContext: modelContext)
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Image(systemName: exercise.icon)
                .font(.title2)
                .foregroundStyle(.mint)
                .frame(width: 40)
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: Spacing.xxxs) {
                HStack {
                    Text(exercise.name)
                        .font(.headline)
                        .foregroundStyle(TextColors.primary)
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        Button {
                            toggleFavorite()
                        } label: {
                            Image(systemName: isFavorite ? "heart.fill" : "heart")
                                .font(.subheadline)
                                .foregroundStyle(isFavorite ? .pink : TextColors.tertiary)
                        }
                        .buttonStyle(.plain)
                        .frame(minWidth: 32, minHeight: 32)
                        .accessibilityLabel(isFavorite ? "Удалить из избранного" : "Добавить в избранное")
                        .onAppear {
                            checkFavoriteStatus()
                        }
                        
                        if let assignment = assignment, assignment.isActive {
                            ScheduleIndicatorView(assignment: assignment)
                        } else {
                            Text(formattedDuration)
                                .font(.caption)
                                .foregroundStyle(TextColors.tertiary)
                        }
                        
                        if let onSchedule = onSchedule {
                            Button(action: onSchedule) {
                                Image(systemName: assignment != nil ? "calendar.badge.checkmark" : "calendar.badge.plus")
                                    .font(.subheadline)
                                    .foregroundStyle(assignment != nil ? .orange : TextColors.tertiary)
                            }
                            .buttonStyle(.plain)
                            .frame(minWidth: 32, minHeight: 32)
                            .accessibilityLabel(assignment != nil ? "Редактировать расписание" : "Создать расписание")
                        }
                    }
                }
                
                Text(exercise.description)
                    .font(.subheadline)
                    .foregroundStyle(TextColors.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, Spacing.xxs)
    }
    
    private var formattedDuration: String {
        let minutes = Int(exercise.duration / 60)
        return "\(minutes) min"
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
}

// MARK: - Preview

#Preview {
    NavigationStack {
        MuscleRelaxationListView()
    }
    .modelContainer(for: [RelaxationSessionResult.self])
}
