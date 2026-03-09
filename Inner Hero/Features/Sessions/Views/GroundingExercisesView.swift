import SwiftUI
import SwiftData

// MARK: - GroundingExercisesView

struct GroundingExercisesView: View {
    @Query(sort: \ExerciseAssignment.createdAt) private var allAssignments: [ExerciseAssignment]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 24) {
                    header
                    
                    VStack(spacing: 16) {
                        ForEach(GroundingExercise.predefinedExercises) { exercise in
                            let assignment = allAssignments.first { assignment in
                                assignment.exerciseType == .grounding && assignment.grounding == exercise.type
                            }
                            
                            NavigationLink {
                                GroundingExerciseDetailView(exercise: exercise)
                            } label: {
                                GroundingExerciseCardView(
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
            .background(TopMeshGradientBackground(palette: .purple))
            .navigationTitle("Grounding")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private var header: some View {
        VStack(spacing: Spacing.xs) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 48))
                .foregroundStyle(.purple.gradient)
                .accessibilityHidden(true)
            
            Text("Grounding techniques help quickly reduce anxiety and bring attention to the present moment")
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

#Preview {
    NavigationStack {
        GroundingExercisesView()
    }
    .modelContainer(for: [ExerciseAssignment.self, FavoriteExercise.self], inMemory: true)
}


