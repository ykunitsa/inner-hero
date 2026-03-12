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
        ScrollView {
            LazyVStack(spacing: 24) {
                if activations.isEmpty {
                    emptyStateView
                } else {
                    if !pinnedActivations.isEmpty {
                        activationsSection(title: String(localized: "Pinned"), activations: pinnedActivations)
                    }
                    
                    if !userCreatedActivations.isEmpty {
                        activationsSection(title: String(localized: "Created by me"), activations: userCreatedActivations)
                    }
                    
                    if !predefinedActivations.isEmpty {
                        activationsSection(title: String(localized: "Predefined"), activations: predefinedActivations)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 40)
        }
        .background(TopMeshGradientBackground(palette: .green))
        .navigationTitle("Behavioral activation")
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
                .accessibilityLabel(String(localized: "Add activity list"))
            }
        }
        .sheet(isPresented: $showingCreateSheet) {
            CreateActivationView()
        }
        .alert(String(localized: "Delete activity list?"), isPresented: $showingDeleteAlert, presenting: activationToDelete) { activation in
            Button("Cancel", role: .cancel) {
                activationToDelete = nil
            }
            Button("Delete", role: .destructive) {
                deleteActivation(activation)
            }
        } message: { activation in
            Text(String(format: String(localized: "Are you sure you want to delete the list \"%@\"? This action cannot be undone."), activation.localizedTitle))
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeIn(duration: 0.3), value: appeared)
        .onAppear {
            appeared = true
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
                Text(String(localized: "Start taking action"))
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(TextColors.primary)
                
                Text(String(localized: "Create your first activity list for behavioral activation"))
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
        NavigationLink(value: AppRoute.activationView(activityListId: activation.id, assignmentId: nil)) {
            ActivationCardView(activation: activation)
        }
        .buttonStyle(.plain)
        .contextMenu {
            if !activation.isPredefined {
                Button(role: .destructive) {
                    activationToDelete = activation
                    showingDeleteAlert = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(activation.localizedTitle). \(activation.localizedActivities.count) \(String(localized: "activities"))\(activation.isPredefined ? ". \(String(localized: "Predefined list"))" : "")")
        .accessibilityHint(String(localized: "Double tap to view details"))
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
