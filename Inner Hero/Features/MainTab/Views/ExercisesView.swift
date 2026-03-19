import SwiftUI
import SwiftData

// MARK: - ExerciseCategory
// Defined at file scope so both ExercisesView and ExerciseCategoryCard can access it.

private struct ExerciseCategory {
    let title: String
    let description: String
    let meta: String
    let icon: String
    let color: Color
    let route: ExerciseListRoute
}

// MARK: - ExercisesView

struct ExercisesView: View {
    @Binding var path: NavigationPath

    @State private var appeared = false

    // MARK: - Data

    private let categories: [ExerciseCategory] = [
        .init(
            title: String(localized: "Exposures"),
            description: String(localized: "Gradually facing fears and anxieties at your own pace"),
            meta: String(localized: "Personalized · Fear hierarchy"),
            icon: "leaf",
            color: AppColors.primary,
            route: .exposures
        ),
        .init(
            title: String(localized: "Breathing"),
            description: String(localized: "Controlled techniques to calm the nervous system"),
            meta: String(localized: "3 techniques · 3–10 min"),
            icon: "wind",
            color: AppColors.positive,
            route: .breathing
        ),
        .init(
            title: String(localized: "Relaxation"),
            description: String(localized: "Progressive muscle relaxation for tension relief"),
            meta: String(localized: "2 exercises · 5–15 min"),
            icon: "figure.mind.and.body",
            color: AppColors.positive,
            route: .relaxation
        ),
        .init(
            title: String(localized: "Grounding"),
            description: String(localized: "Sensory awareness techniques to reduce anxiety"),
            meta: String(localized: "5-4-3-2-1 · 2 min"),
            icon: "brain.head.profile",
            color: AppColors.accent,
            route: .grounding
        ),
        .init(
            title: String(localized: "Behavioral Activation"),
            description: String(localized: "Build momentum through meaningful daily actions"),
            meta: String(localized: "Personalized · Activity based"),
            icon: "figure.walk",
            color: AppColors.accent,
            route: .activation
        ),
    ]

    // MARK: - Body

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    // Page subtitle
                    Text("Choose a technique that fits how you're feeling right now.")
                        .appFont(.body)
                        .foregroundStyle(TextColors.secondary)
                        .padding(.top, Spacing.xxs)

                    // Category cards
                    VStack(spacing: Spacing.xs) {
                        ForEach(categories.indices, id: \.self) { index in
                            categoryRow(category: categories[index], index: index)
                        }
                    }
                }
                .padding(.horizontal, Spacing.sm)
                .padding(.top, Spacing.md)
                .padding(.bottom, Spacing.xxl)
            }
            .homeBackground()
            .navigationTitle(String(localized: "Exercises"))
            .navigationBarTitleDisplayMode(.large)
            .onAppear { appeared = true }
            .navigationDestination(for: AppRoute.self) { route in
                AppRouteView(route: route)
            }
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func categoryRow(category: ExerciseCategory, index: Int) -> some View {
        let delay = Double(index) * 0.07
        NavigationLink(value: AppRoute.exerciseList(category.route)) {
            ExerciseCategoryCard(category: category)
        }
        .buttonStyle(.plain)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 16)
        .animation(AppAnimation.appear.delay(delay), value: appeared)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(category.title). \(category.description)")
        .accessibilityHint(String(localized: "Double-tap to open"))
    }
}

// MARK: - ExerciseCategoryCard

private struct ExerciseCategoryCard: View {
    let category: ExerciseCategory

    @Environment(\.colorScheme) private var colorScheme

    private var iconBackgroundOpacity: Double {
        colorScheme == .dark ? Opacity.softBackground : Opacity.subtleBackground + 0.05
    }

    var body: some View {
        HStack(spacing: Spacing.sm) {
            // Icon container
            Image(systemName: category.icon)
                .font(.system(size: IconSize.glyph + 4, weight: .medium))
                .foregroundStyle(category.color)
                .frame(width: IconSize.hero, height: IconSize.hero)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                        .fill(category.color.opacity(iconBackgroundOpacity))
                )

            // Labels
            VStack(alignment: .leading, spacing: Spacing.xxxs) {
                Text(category.title)
                    .appFont(.h3)
                    .foregroundStyle(TextColors.primary)

                Text(category.description)
                    .appFont(.small)
                    .foregroundStyle(TextColors.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text(category.meta)
                    .appFont(.smallMedium)
                    .foregroundStyle(category.color.opacity(0.8))
                    .padding(.top, 2)
            }

            Spacer(minLength: 0)

            // Trailing arrow — NavigationLink owns the tap, this is purely visual
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppColors.gray400)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.sm)
        .cardStyle(cornerRadius: CornerRadius.lg, padding: 0)
    }
}

// MARK: - Preview

#Preview {
    ExercisesView(path: .constant(NavigationPath()))
}
