import SwiftUI
import SwiftData

// MARK: - BreathingExercisesView

struct BreathingExercisesView: View {
    @Query(sort: \ExerciseAssignment.createdAt) private var allAssignments: [ExerciseAssignment]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(BreathingPattern.predefinedPatterns) { pattern in
                        let assignment = allAssignments.first { assignment in
                            assignment.exerciseType == .breathing && assignment.breathingPattern == pattern.type
                        }
                        
                        NavigationLink {
                            BreathingPatternDetailView(pattern: pattern)
                        } label: {
                            BreathingPatternCardView(
                                pattern: pattern,
                                assignment: assignment
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 40)
            }
            .background(TopMeshGradientBackground(palette: .teal))
            .navigationTitle("Дыхание")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - BreathingPatternCardView

private struct BreathingPatternCardView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    let pattern: BreathingPattern
    let assignment: ExerciseAssignment?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            description
            
            metadataRow
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
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
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(.primary.opacity(colorScheme == .dark ? 0.18 : 0.06), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(pattern.localizedName)
        .accessibilityHint("Нажмите дважды, чтобы открыть детали. Запуск сеанса доступен внутри.")
    }
    
    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: pattern.icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.teal)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(.teal.opacity(colorScheme == .dark ? 0.20 : 0.12))
                )
                .accessibilityHidden(true)
            
            Text(pattern.localizedName)
                .font(.title3.weight(.semibold))
                .foregroundStyle(TextColors.primary)
                .multilineTextAlignment(.leading)
            
            Spacer(minLength: 0)
        }
    }
    
    private var description: some View {
        Text(pattern.localizedDescription)
            .font(.body)
            .foregroundStyle(TextColors.secondary)
            .lineLimit(2)
            .multilineTextAlignment(.leading)
    }
    
    private var metadataRow: some View {
        HStack(spacing: 12) {
            if let assignment = assignment, assignment.isActive {
                ScheduleIndicatorView(assignment: assignment)
            }
            
            Spacer(minLength: 0)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        BreathingExercisesView()
    }
    .modelContainer(for: [ExerciseAssignment.self], inMemory: true)
}
