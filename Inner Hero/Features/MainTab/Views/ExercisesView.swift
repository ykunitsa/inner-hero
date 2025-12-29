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
                    scheduleCard
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                        .animation(.easeOut(duration: 0.3).delay(0.0), value: appeared)
                    
                    exerciseCard(
                        title: "Экспозиции",
                        description: "Постепенное преодоление страхов и тревог",
                        icon: "leaf.circle.fill",
                        color: .blue,
                        type: .exposures
                    )
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .animation(.easeOut(duration: 0.3).delay(0.1), value: appeared)
                    
                    exerciseCard(
                        title: "Дыхание",
                        description: "Техники контролируемого дыхания для регуляции нервной системы",
                        icon: "wind",
                        color: .teal,
                        type: .breathing
                    )
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .animation(.easeOut(duration: 0.3).delay(0.2), value: appeared)
                    
                    exerciseCard(
                        title: "Релаксация",
                        description: "Прогрессивная мышечная релаксация для снятия напряжения",
                        icon: "figure.mind.and.body",
                        color: .mint,
                        type: .relaxation
                    )
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .animation(.easeOut(duration: 0.3).delay(0.3), value: appeared)
                    
                    exerciseCard(
                        title: "Заземление",
                        description: "Заземление и техники внимания для снижения тревоги",
                        icon: "brain.head.profile",
                        color: .purple,
                        type: .grounding
                    )
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .animation(.easeOut(duration: 0.3).delay(0.4), value: appeared)
                    
                    exerciseCard(
                        title: "Активация",
                        description: "Повышение активности через осмысленные действия",
                        icon: "figure.walk",
                        color: .green,
                        type: .activation
                    )
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .animation(.easeOut(duration: 0.3).delay(0.5), value: appeared)
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 40)
            }
            .navigationTitle("Упражнения")
            .navigationBarTitleDisplayMode(.large)
            .opacity(appeared ? 1 : 0)
            .animation(.easeIn(duration: 0.3), value: appeared)
            .onAppear {
                appeared = true
            }
        }
    }
    
    private var scheduleCard: some View {
        NavigationLink {
            ExerciseScheduleView()
        } label: {
            HStack(spacing: 16) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 40))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.orange.opacity(0.8), .orange.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .background(
                        Circle()
                            .fill(Color.orange.opacity(0.1))
                    )
                    .accessibilityHidden(true)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Расписание")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(TextColors.primary)
                    
                    Text("Планируйте упражнения по расписанию")
                        .font(.subheadline)
                        .foregroundStyle(TextColors.secondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.body)
                    .foregroundStyle(TextColors.tertiary)
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
        .accessibilityLabel("Расписание. Планируйте упражнения по расписанию")
        .accessibilityHint("Дважды нажмите для открытия")
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
                        .foregroundStyle(TextColors.primary)
                    
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(TextColors.secondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.body)
                    .foregroundStyle(TextColors.tertiary)
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
        .accessibilityHint("Дважды нажмите для открытия")
    }
}

#Preview {
    ExercisesView()
}

