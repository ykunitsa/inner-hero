import SwiftUI
import SwiftData

struct ExercisesView: View {
    @State private var appeared = false
    
    enum ExerciseType {
        case exposures
        case breathing
        case relaxation
        case grounding
        case activation
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 20) {
                    exerciseCard(
                        title: String(localized: "Exposures"),
                        description: String(localized: "Gradually facing fears and anxieties"),
                        icon: "leaf",
                        color: .blue,
                        type: .exposures
                    )
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .animation(.easeOut(duration: 0.3).delay(0.0), value: appeared)
                    
                    exerciseCard(
                        title: String(localized: "Breathing"),
                        description: String(localized: "Controlled breathing techniques to regulate the nervous system"),
                        icon: "wind",
                        color: .teal,
                        type: .breathing
                    )
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .animation(.easeOut(duration: 0.3).delay(0.1), value: appeared)
                    
                    exerciseCard(
                        title: String(localized: "Relaxation"),
                        description: String(localized: "Progressive muscle relaxation for tension relief"),
                        icon: "figure.mind.and.body",
                        color: .mint,
                        type: .relaxation
                    )
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .animation(.easeOut(duration: 0.3).delay(0.2), value: appeared)
                    
                    exerciseCard(
                        title: String(localized: "Grounding"),
                        description: String(localized: "Grounding and awareness techniques to reduce anxiety"),
                        icon: "brain.head.profile",
                        color: .purple,
                        type: .grounding
                    )
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .animation(.easeOut(duration: 0.3).delay(0.3), value: appeared)
                    
                    exerciseCard(
                        title: String(localized: "Behavioral activation"),
                        description: String(localized: "Increasing activity through meaningful actions"),
                        icon: "figure.walk",
                        color: .green,
                        type: .activation
                    )
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .animation(.easeOut(duration: 0.3).delay(0.4), value: appeared)
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 40)
            }
            .background(TopMeshGradientBackground())
            .navigationTitle("Exercises")
            .navigationBarTitleDisplayMode(.large)
            .opacity(appeared ? 1 : 0)
            .animation(.easeIn(duration: 0.3), value: appeared)
            .onAppear {
                appeared = true
            }
        }
    }
    
    @ViewBuilder
    private func destinationView(for type: ExerciseType) -> some View {
        switch type {
        case .exposures:
            ExposuresListView()
        case .breathing:
            BreathingExercisesView()
        case .relaxation:
            MuscleRelaxationListView()
        case .grounding:
            GroundingExercisesView()
        case .activation:
            BehavioralActivationView()
        }
    }
    
    private func exerciseCard(
        title: String,
        description: String,
        icon: String,
        color: Color,
        type: ExerciseType
    ) -> some View {
        NavigationLink {
            destinationView(for: type)
        } label: {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 40))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color.opacity(0.8), color.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .background(
                        Circle()
                            .fill(color.opacity(0.1))
                    )
                    .accessibilityHidden(true)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color.primary)
                    
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(Color.secondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.body)
                    .foregroundStyle(Color.secondary)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(description)")
        .accessibilityHint(String(localized: "Double-tap to open"))
    }
}

#Preview {
    ExercisesView()
}

