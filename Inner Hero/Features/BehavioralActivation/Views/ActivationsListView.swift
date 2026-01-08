import SwiftUI
import SwiftData

struct ActivationsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ActivityList.title) private var activations: [ActivityList]
    @Query(sort: \FavoriteExercise.createdAt, order: .reverse) private var favorites: [FavoriteExercise]
    
    @State private var showingCreateSheet = false
    @State private var activationToDelete: ActivityList?
    @State private var showingDeleteAlert = false
    @State private var appeared = false
    
    private var activationsById: [UUID: ActivityList] {
        Dictionary(uniqueKeysWithValues: activations.map { ($0.id, $0) })
    }
    
    private var pinnedActivations: [ActivityList] {
        var seen = Set<UUID>()
        
        return favorites
            .filter { $0.exerciseType == .behavioralActivation }
            .compactMap { $0.exerciseId }
            .compactMap { id in
                guard seen.insert(id).inserted else { return nil }
                return activationsById[id]
            }
    }
    
    private var pinnedActivationIDs: Set<UUID> {
        Set(pinnedActivations.map(\.id))
    }
    
    private var userCreatedActivations: [ActivityList] {
        activations.filter { !pinnedActivationIDs.contains($0.id) && $0.isPredefined == false }
    }
    
    private var predefinedActivations: [ActivityList] {
        activations.filter { !pinnedActivationIDs.contains($0.id) && $0.isPredefined == true }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 24) {
                    if activations.isEmpty {
                        emptyStateView
                    } else {
                        if !pinnedActivations.isEmpty {
                            activationsSection(title: "Закреплённые", activations: pinnedActivations)
                        }
                        
                        if !userCreatedActivations.isEmpty {
                            activationsSection(title: "Созданные мной", activations: userCreatedActivations)
                        }
                        
                        if !predefinedActivations.isEmpty {
                            activationsSection(title: "Предустановленные", activations: predefinedActivations)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 40)
            }
            .background(TopMeshGradientBackground(palette: .green))
            .navigationTitle("Поведенческая активация")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingCreateSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.headline)
                            .foregroundStyle(TextColors.toolbar)
                    }
                    .accessibilityLabel("Добавить список активностей")
                }
            }
            .sheet(isPresented: $showingCreateSheet) {
                CreateActivationView()
            }
            .alert("Удалить список активностей?", isPresented: $showingDeleteAlert, presenting: activationToDelete) { activation in
                Button("Отмена", role: .cancel) {
                    activationToDelete = nil
                }
                Button("Удалить", role: .destructive) {
                    deleteActivation(activation)
                }
            } message: { activation in
                Text("Вы уверены, что хотите удалить список \"\(activation.title)\"? Это действие нельзя отменить.")
            }
            .opacity(appeared ? 1 : 0)
            .animation(.easeIn(duration: 0.3), value: appeared)
            .onAppear {
                appeared = true
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "figure.walk.circle")
                .font(.system(size: 72))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.green.opacity(0.6), .mint.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .accessibilityHidden(true)
            
            VStack(spacing: 12) {
                Text("Начните действовать")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(TextColors.primary)
                
                Text("Создайте первый список активностей для поведенческой активации")
                    .font(.body)
                    .foregroundStyle(TextColors.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 80)
        .accessibilityElement(children: .combine)
    }
    
    private func activationsSection(title: String, activations: [ActivityList]) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(TextColors.secondary)
                .padding(.leading, 4)
            
            VStack(spacing: 16) {
                ForEach(Array(activations.enumerated()), id: \.element.id) { index, activation in
                    activationCard(activation: activation)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                        .animation(.easeOut(duration: 0.3).delay(Double(index) * 0.05), value: appeared)
                }
            }
        }
    }
    
    private func activationCard(activation: ActivityList) -> some View {
        NavigationLink(destination: ActivationDetailView(activation: activation)) {
            ActivationCardView(activation: activation)
        }
        .buttonStyle(.plain)
        .contextMenu {
            if !activation.isPredefined {
                Button(role: .destructive) {
                    activationToDelete = activation
                    showingDeleteAlert = true
                } label: {
                    Label("Удалить", systemImage: "trash")
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(activation.title). \(activation.activities.count) активностей\(activation.isPredefined ? ". Предустановленный список" : "")")
        .accessibilityHint("Дважды нажмите для просмотра деталей")
    }
    
    private func deleteActivation(_ activation: ActivityList) {
        withAnimation(.easeInOut(duration: 0.3)) {
            modelContext.delete(activation)
            activationToDelete = nil
        }
    }
}

#Preview {
    ActivationsListView()
        .modelContainer(for: ActivityList.self, inMemory: true)
}
