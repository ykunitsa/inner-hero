import SwiftUI
import SwiftData

struct GroundingExercisesView: View {
    @Query(sort: \ExerciseAssignment.createdAt) private var allAssignments: [ExerciseAssignment]

    @State private var appeared = false

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xs) {
                ForEach(Array(GroundingExercise.predefinedExercises.enumerated()), id: \.element.id) { index, exercise in
                    let assignment = allAssignments.first {
                        $0.exerciseType == .grounding && $0.grounding == exercise.type
                    }

                    NavigationLink(value: AppRoute.groundingDetail(groundingType: exercise.type)) {
                        GroundingExerciseCardView(exercise: exercise, assignment: assignment)
                    }
                    .buttonStyle(.plain)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 12)
                    .animation(AppAnimation.appear.delay(Double(index) * 0.07), value: appeared)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(exercise.name)
                    .accessibilityHint(String(localized: "Double-tap to open details"))
                }
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.xxl)
        }
        .homeBackground()
        .navigationTitle(String(localized: "Grounding"))
        .navigationBarTitleDisplayMode(.large)
        .onAppear { appeared = true }
    }
}

#Preview {
    NavigationStack {
        GroundingExercisesView()
    }
    .modelContainer(for: [ExerciseAssignment.self, FavoriteExercise.self], inMemory: true)
}
