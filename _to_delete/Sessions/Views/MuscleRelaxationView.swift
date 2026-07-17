import SwiftUI
import SwiftData
import Foundation

struct MuscleRelaxationListView: View {
    @Query(sort: \ExerciseAssignment.createdAt) private var allAssignments: [ExerciseAssignment]

    @State private var appeared = false

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xs) {
                ForEach(Array(RelaxationExercise.predefinedExercises.enumerated()), id: \.element.id) { index, exercise in
                    let assignment = allAssignments.first {
                        $0.exerciseType == .relaxation && $0.relaxation == exercise.type
                    }

                    NavigationLink(value: AppRoute.relaxationDetail(relaxationType: exercise.type)) {
                        RelaxationExerciseCardView(exercise: exercise, assignment: assignment)
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
        .navigationTitle(String(localized: "Muscle relaxation"))
        .navigationBarTitleDisplayMode(.large)
        .onAppear { appeared = true }
    }
}

#Preview {
    NavigationStack {
        MuscleRelaxationListView()
    }
    .modelContainer(for: [RelaxationSessionResult.self])
}
