import SwiftUI
import SwiftData
import Foundation

// MARK: - MuscleRelaxationListView

struct MuscleRelaxationListView: View {
    @Query(sort: \ExerciseAssignment.createdAt) private var allAssignments: [ExerciseAssignment]
    
    var body: some View {
        ScrollView {
                LazyVStack(spacing: 24) {
                    header
                    
                    VStack(spacing: 16) {
                        ForEach(RelaxationExercise.predefinedExercises) { exercise in
                            let assignment = allAssignments.first { assignment in
                                assignment.exerciseType == .relaxation && assignment.relaxation == exercise.type
                            }
                            
                            NavigationLink(value: AppRoute.relaxationDetail(relaxationType: exercise.type)) {
                                RelaxationExerciseCardView(
                                    exercise: exercise,
                                    assignment: assignment
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 40)
            }
            .background(TopMeshGradientBackground(palette: .mint))
            .navigationTitle("Muscle relaxation")
            .navigationBarTitleDisplayMode(.large)
    }
    
    private var header: some View {
        VStack(spacing: Spacing.xs) {
            Image(systemName: "figure.mind.and.body")
                .font(.system(size: 48))
                .foregroundStyle(.mint.gradient)
                .accessibilityHidden(true)
            
            Text("Progressive muscle relaxation techniques help release bodily tension and restore calm")
                .font(.subheadline)
                .foregroundStyle(TextColors.secondary)
                .multilineTextAlignment(.center)
                .textCase(.none)
                .padding(.top, Spacing.xxs)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        MuscleRelaxationListView()
    }
    .modelContainer(for: [RelaxationSessionResult.self])
}
