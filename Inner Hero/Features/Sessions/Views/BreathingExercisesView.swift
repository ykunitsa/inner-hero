import SwiftUI
import SwiftData

// MARK: - BreathingExercisesView

struct BreathingExercisesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ExerciseAssignment.createdAt) private var allAssignments: [ExerciseAssignment]
    @State private var patternToSchedule: BreathingPattern?
    @State private var showScheduleSheet = false
    @State private var selectedPatternType: BreathingPatternType?
    
    private var dataManager: DataManager {
        DataManager(modelContext: modelContext)
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(BreathingPattern.predefinedPatterns) { pattern in
                        let assignment = allAssignments.first { assignment in
                            assignment.exerciseType == .breathing && assignment.breathingPattern == pattern.type
                        }
                        
                        NavigationLink {
                            BreathingSessionView(pattern: pattern)
                        } label: {
                            BreathingPatternRow(
                                pattern: pattern,
                                assignment: assignment,
                                onSchedule: {
                                    selectedPatternType = pattern.type
                                    showScheduleSheet = true
                                }
                            )
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button {
                                patternToSchedule = pattern
                                showScheduleSheet = true
                            } label: {
                                Label("Запланировать", systemImage: "calendar.badge.plus")
                            }
                            .tint(.orange)
                        }
                    }
                } header: {
                    VStack(spacing: Spacing.xs) {
                        Image(systemName: "wind")
                            .font(.system(size: 48))
                            .foregroundStyle(.teal.gradient)
                            .accessibilityHidden(true)
                        
                        Text("Controlled breathing techniques help regulate your nervous system and reduce anxiety")
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
            .navigationTitle("Breathing")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showScheduleSheet) {
                if let patternType = selectedPatternType {
                    ScheduleExerciseView(preSelectedBreathingPattern: patternType)
                }
            }
        }
    }
}

// MARK: - BreathingPatternRow

struct BreathingPatternRow: View {
    @Environment(\.modelContext) private var modelContext
    let pattern: BreathingPattern
    let assignment: ExerciseAssignment?
    let onSchedule: (() -> Void)?
    @State private var isFavorite = false
    
    private var dataManager: DataManager {
        DataManager(modelContext: modelContext)
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Image(systemName: pattern.icon)
                .font(.title2)
                .foregroundStyle(.teal)
                .frame(width: 40)
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: Spacing.xxxs) {
                HStack {
                    Text(pattern.name)
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
                
                Text(pattern.description)
                    .font(.subheadline)
                    .foregroundStyle(TextColors.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, Spacing.xxs)
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
}

// MARK: - Preview

#Preview {
    NavigationStack {
        BreathingExercisesView()
    }
}
