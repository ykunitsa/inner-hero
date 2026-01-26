import SwiftUI
import SwiftData

struct QuickStartWidget: View {
    let favorites: [FavoriteExercise]
    
    @Query(sort: \Exposure.title) private var exposures: [Exposure]
    
    var body: some View {
        WidgetCard(minHeight: 120) {
            VStack(alignment: .leading, spacing: 12) {
                Label("Быстрый старт", systemImage: "bolt.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.orange)
                
                if favorites.isEmpty {
                    Text("Добавьте упражнения в избранное")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(favorites.prefix(3)) { favorite in
                            NavigationLink {
                                quickDestination(for: favorite)
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: icon(for: favorite))
                                        .font(.subheadline)
                                        .foregroundStyle(color(for: favorite))
                                        .frame(width: 22)
                                    
                                    Text(title(for: favorite))
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(.primary)
                                        .lineLimit(1)
                                    
                                    Spacer(minLength: 0)
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.tertiary)
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
    }
    
    private func title(for favorite: FavoriteExercise) -> String {
        switch favorite.exerciseType {
        case .exposure:
            if let id = favorite.exerciseId,
               let exposure = exposures.first(where: { $0.id == id }) {
                return exposure.title
            }
            return String(localized: "Экспозиция")
            
        case .breathing:
            if let raw = favorite.exerciseIdentifier,
               let type = BreathingPatternType(rawValue: raw),
               let pattern = BreathingPattern.predefinedPatterns.first(where: { $0.type == type }) {
                return pattern.name
            }
            return String(localized: "Дыхание")
            
        case .relaxation:
            if let raw = favorite.exerciseIdentifier,
               let type = RelaxationType(rawValue: raw),
               let exercise = RelaxationExercise.predefinedExercises.first(where: { $0.type == type }) {
                return exercise.name
            }
            return String(localized: "Релаксация")
            
        case .grounding:
            if let raw = favorite.exerciseIdentifier,
               let type = GroundingType(rawValue: raw),
               let exercise = GroundingExercise.predefinedExercises.first(where: { $0.type == type }) {
                return exercise.name
            }
            return String(localized: "Заземление")
            
        case .behavioralActivation:
            return String(localized: "Поведенческая активация")
        }
    }
    
    private func icon(for favorite: FavoriteExercise) -> String {
        switch favorite.exerciseType {
        case .exposure: return "leaf"
        case .breathing: return "wind"
        case .relaxation: return "figure.mind.and.body"
        case .grounding: return "brain.head.profile"
        case .behavioralActivation: return "figure.walk"
        }
    }
    
    private func color(for favorite: FavoriteExercise) -> Color {
        switch favorite.exerciseType {
        case .exposure: return .blue
        case .breathing: return .teal
        case .relaxation: return .mint
        case .grounding: return .purple
        case .behavioralActivation: return .green
        }
    }
    
    @ViewBuilder
    private func quickDestination(for favorite: FavoriteExercise) -> some View {
        switch favorite.exerciseType {
        case .exposure:
            ExposureNavigationView(exerciseId: favorite.exerciseId)
            
        case .breathing:
            if let raw = favorite.exerciseIdentifier,
               let type = BreathingPatternType(rawValue: raw),
               let pattern = BreathingPattern.predefinedPatterns.first(where: { $0.type == type }) {
                BreathingSessionView(pattern: pattern)
            } else {
                Text("Упражнение не найдено")
            }
            
        case .relaxation:
            if let raw = favorite.exerciseIdentifier,
               let type = RelaxationType(rawValue: raw),
               let exercise = RelaxationExercise.predefinedExercises.first(where: { $0.type == type }) {
                RelaxationExerciseDetailView(exercise: exercise)
            } else {
                Text("Упражнение не найдено")
            }
            
        case .grounding:
            if let raw = favorite.exerciseIdentifier,
               let type = GroundingType(rawValue: raw),
               let exercise = GroundingExercise.predefinedExercises.first(where: { $0.type == type }) {
                GroundingSessionView(exercise: exercise)
            } else {
                Text("Упражнение не найдено")
            }
            
        case .behavioralActivation:
            BehavioralActivationView()
        }
    }
}

