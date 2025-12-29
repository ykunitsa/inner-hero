import SwiftUI
import SwiftData

// MARK: - GroundingExercisesView

struct GroundingExercisesView: View {
    @Query(sort: \ExerciseAssignment.createdAt) private var allAssignments: [ExerciseAssignment]
    @State private var selectedGroundingType: GroundingType?
    @State private var showScheduleSheet = false
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(GroundingExercise.predefinedExercises) { exercise in
                        let assignment = allAssignments.first { assignment in
                            assignment.exerciseType == .grounding && assignment.grounding == exercise.type
                        }
                        
                        NavigationLink {
                            GroundingSessionView(exercise: exercise)
                        } label: {
                            GroundingExerciseRow(
                                exercise: exercise,
                                assignment: assignment,
                                onSchedule: {
                                    selectedGroundingType = exercise.type
                                    showScheduleSheet = true
                                }
                            )
                        }
                    }
                } header: {
                    VStack(spacing: Spacing.xs) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 48))
                            .foregroundStyle(.purple.gradient)
                            .accessibilityHidden(true)
                        
                        Text("Техники заземления помогают быстро снизить тревогу и вернуть внимание в настоящий момент")
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
            .navigationTitle("Заземление")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showScheduleSheet) {
                if let groundingType = selectedGroundingType {
                    ScheduleExerciseView(preSelectedGroundingType: groundingType)
                }
            }
        }
    }
}

// MARK: - GroundingExerciseRow

struct GroundingExerciseRow: View {
    @Environment(\.modelContext) private var modelContext
    let exercise: GroundingExercise
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
                .foregroundStyle(.purple)
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
                            Text(formattedEstimatedDuration)
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
    
    private var formattedEstimatedDuration: String {
        let minutes = max(1, Int(exercise.estimatedDuration / 60))
        return "\(minutes) min"
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
}

#Preview {
    NavigationStack {
        GroundingExercisesView()
    }
    .modelContainer(for: [ExerciseAssignment.self, FavoriteExercise.self], inMemory: true)
}


