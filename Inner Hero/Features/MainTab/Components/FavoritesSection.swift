import SwiftUI
import SwiftData

struct FavoritesSection: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FavoriteExercise.createdAt, order: .reverse) private var favorites: [FavoriteExercise]
    @Query(sort: \Exposure.title) private var exposures: [Exposure]
    @Query(sort: \ActivityList.title) private var activityLists: [ActivityList]
    
    private var favoriteExercises: [FavoriteExerciseItem] {
        favorites.compactMap { favorite in
            resolveFavorite(favorite)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            let accent = LinearGradient(
                colors: [.pink, .red],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            HStack {
                Image(systemName: "heart.fill")
                    .font(.body)
                    .foregroundStyle(accent)
                Text("Favorite exercises")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(accent)
            }
            
            if favoriteExercises.isEmpty {
                emptyStateView
            } else {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ],
                    spacing: 12
                ) {
                    ForEach(favoriteExercises) { item in
                        FavoriteExerciseCard(item: item)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Text("No favorite exercises")
                .font(.subheadline)
                .foregroundStyle(TextColors.secondary)
            
            Text("Add exercises to favorites for quick access")
                .font(.caption)
                .foregroundStyle(TextColors.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
    
    private func resolveFavorite(_ favorite: FavoriteExercise) -> FavoriteExerciseItem? {
        switch favorite.exerciseType {
        case .exposure:
            if let exerciseId = favorite.exerciseId,
               let exposure = exposures.first(where: { $0.id == exerciseId }) {
                return FavoriteExerciseItem(
                    id: favorite.id,
                    name: exposure.localizedTitle,
                    description: exposure.localizedDescription,
                    icon: "leaf",
                    color: .blue,
                    exerciseType: .exposure,
                    exerciseId: exerciseId,
                    exerciseIdentifier: nil
                )
            }
            
        case .breathing:
            if let identifier = favorite.exerciseIdentifier,
               let patternType = BreathingPatternType(rawValue: identifier),
               let pattern = BreathingPattern.predefinedPatterns.first(where: { $0.type == patternType }) {
                return FavoriteExerciseItem(
                    id: favorite.id,
                    name: pattern.name,
                    description: pattern.description,
                    icon: pattern.icon,
                    color: .teal,
                    exerciseType: .breathing,
                    exerciseId: nil,
                    exerciseIdentifier: identifier
                )
            }
            
        case .relaxation:
            if let identifier = favorite.exerciseIdentifier,
               let relaxationType = RelaxationType(rawValue: identifier),
               let exercise = RelaxationExercise.predefinedExercises.first(where: { $0.type == relaxationType }) {
                return FavoriteExerciseItem(
                    id: favorite.id,
                    name: exercise.name,
                    description: exercise.description,
                    icon: exercise.icon,
                    color: .mint,
                    exerciseType: .relaxation,
                    exerciseId: nil,
                    exerciseIdentifier: identifier
                )
            }
            
        case .grounding:
            if let identifier = favorite.exerciseIdentifier,
               let groundingType = GroundingType(rawValue: identifier),
               let exercise = GroundingExercise.predefinedExercises.first(where: { $0.type == groundingType }) {
                return FavoriteExerciseItem(
                    id: favorite.id,
                    name: exercise.name,
                    description: exercise.description,
                    icon: exercise.icon,
                    color: .purple,
                    exerciseType: .grounding,
                    exerciseId: nil,
                    exerciseIdentifier: identifier
                )
            }
            
        case .behavioralActivation:
            if let exerciseId = favorite.exerciseId,
               let activityList = activityLists.first(where: { $0.id == exerciseId }) {
                return FavoriteExerciseItem(
                    id: favorite.id,
                    name: activityList.localizedTitle,
                    description: String(localized: "Activity list for behavioral activation"),
                    icon: "figure.walk",
                    color: .green,
                    exerciseType: .behavioralActivation,
                    exerciseId: exerciseId,
                    exerciseIdentifier: nil
                )
            }
        }
        
        return nil
    }
}

// MARK: - Favorite Exercise Item

struct FavoriteExerciseItem: Identifiable {
    let id: UUID
    let name: String
    let description: String
    let icon: String
    let color: Color
    let exerciseType: ExerciseType
    let exerciseId: UUID?
    let exerciseIdentifier: String?
}

// MARK: - Favorite Exercise Card

struct FavoriteExerciseCard: View {
    let item: FavoriteExerciseItem
    @Environment(\.colorScheme) var colorScheme
    
    private static let cardHeight: CGFloat = 160

    private var route: AppRoute? {
        appRoute(for: item)
    }
    
    var body: some View {
        Group {
            if let route {
                NavigationLink(value: route) {
                    cardContent
                }
                .buttonStyle(.plain)
            } else {
                cardContent
            }
        }
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: item.icon)
                        .font(.title3)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [item.color, item.color.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(item.color.opacity(0.1))
                        )
                    
                    Spacer()
                }
                
                Text(item.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(TextColors.primary)
                    .lineLimit(2)
                
                Text(item.description)
                    .font(.caption)
                    .foregroundStyle(TextColors.secondary)
                    .lineLimit(2)
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: Self.cardHeight, maxHeight: Self.cardHeight, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        colorScheme == .dark
                        ? LinearGradient(
                            colors: [
                                Color(uiColor: .secondarySystemGroupedBackground),
                                Color(uiColor: .tertiarySystemGroupedBackground)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        : LinearGradient(
                            colors: [
                                Color(red: 0.98, green: 0.99, blue: 1.0),
                                Color(red: 0.96, green: 0.97, blue: 0.99)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(item.color.opacity(colorScheme == .dark ? 0.3 : 0.2), lineWidth: 1)
            )
    }

    private func appRoute(for item: FavoriteExerciseItem) -> AppRoute? {
        switch item.exerciseType {
        case .exposure:
            guard let id = item.exerciseId else { return nil }
            return .exposureDetail(exposureId: id)
        case .breathing:
            guard let raw = item.exerciseIdentifier,
                  let type = BreathingPatternType(rawValue: raw) else { return nil }
            return .breathingDetail(patternType: type)
        case .relaxation:
            guard let raw = item.exerciseIdentifier,
                  let type = RelaxationType(rawValue: raw) else { return nil }
            return .relaxationDetail(relaxationType: type)
        case .grounding:
            guard let raw = item.exerciseIdentifier,
                  let type = GroundingType(rawValue: raw) else { return nil }
            return .groundingDetail(groundingType: type)
        case .behavioralActivation:
            guard let id = item.exerciseId else { return nil }
            return .baMain
        }
    }
}
