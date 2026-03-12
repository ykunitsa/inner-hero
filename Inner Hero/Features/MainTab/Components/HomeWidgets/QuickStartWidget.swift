import SwiftUI
import SwiftData

struct QuickStartWidget: View {
    let favorites: [FavoriteExercise]
    
    @Query(sort: \Exposure.title) private var exposures: [Exposure]
    
    var body: some View {
        WidgetCard(minHeight: 120) {
            VStack(alignment: .leading, spacing: 12) {
                Label("Quick start", systemImage: "bolt.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.orange)
                
                if favorites.isEmpty {
                    Text("Add exercises to favorites")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(favorites.prefix(3)) { favorite in
                            if let route = appRoute(for: favorite) {
                                NavigationLink(value: route) {
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
        }
        .accessibilityElement(children: .contain)
    }

    private func appRoute(for favorite: FavoriteExercise) -> AppRoute? {
        switch favorite.exerciseType {
        case .exposure:
            guard let id = favorite.exerciseId else { return nil }
            return .exposureDetail(exposureId: id)
        case .breathing:
            guard let raw = favorite.exerciseIdentifier,
                  let type = BreathingPatternType(rawValue: raw) else { return nil }
            return .breathingDetail(patternType: type)
        case .relaxation:
            guard let raw = favorite.exerciseIdentifier,
                  let type = RelaxationType(rawValue: raw) else { return nil }
            return .relaxationDetail(relaxationType: type)
        case .grounding:
            guard let raw = favorite.exerciseIdentifier,
                  let type = GroundingType(rawValue: raw) else { return nil }
            return .groundingDetail(groundingType: type)
        case .behavioralActivation:
            return .exerciseList(.activation)
        }
    }
    
    private func title(for favorite: FavoriteExercise) -> String {
        switch favorite.exerciseType {
        case .exposure:
            if let id = favorite.exerciseId,
               let exposure = exposures.first(where: { $0.id == id }) {
                return exposure.localizedTitle
            }
            return String(localized: "Exposure")
            
        case .breathing:
            if let raw = favorite.exerciseIdentifier,
               let type = BreathingPatternType(rawValue: raw),
               let pattern = BreathingPattern.predefinedPatterns.first(where: { $0.type == type }) {
                return pattern.name
            }
            return String(localized: "Breathing")
            
        case .relaxation:
            if let raw = favorite.exerciseIdentifier,
               let type = RelaxationType(rawValue: raw),
               let exercise = RelaxationExercise.predefinedExercises.first(where: { $0.type == type }) {
                return exercise.name
            }
            return String(localized: "Relaxation")
            
        case .grounding:
            if let raw = favorite.exerciseIdentifier,
               let type = GroundingType(rawValue: raw),
               let exercise = GroundingExercise.predefinedExercises.first(where: { $0.type == type }) {
                return exercise.name
            }
            return String(localized: "Grounding")
            
        case .behavioralActivation:
            return String(localized: "Behavioral activation")
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
        if let route = appRoute(for: favorite) {
            AppRouteView(route: route)
        } else {
            Text("Exercise not found")
        }
    }
}

