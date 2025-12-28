import SwiftUI
import SwiftData

struct ActivationsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ActivityList.title) private var activations: [ActivityList]
    
    @State private var showingCreateSheet = false
    @State private var activationToDelete: ActivityList?
    @State private var showingDeleteAlert = false
    @State private var appeared = false
    
    private var predefinedActivations: [ActivityList] {
        activations.filter { $0.isPredefined }
    }
    
    private var userActivations: [ActivityList] {
        activations.filter { !$0.isPredefined }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 24) {
                    if activations.isEmpty {
                        emptyStateView
                    } else {
                        if !predefinedActivations.isEmpty {
                            activationsSection(
                                title: "Built-in Lists",
                                activations: predefinedActivations
                            )
                        }
                        
                        if !userActivations.isEmpty {
                            activationsSection(
                                title: "My Lists",
                                activations: userActivations
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 40)
            }
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.95, green: 0.97, blue: 1.0),
                        Color(red: 0.92, green: 0.95, blue: 0.98)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Activations")
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
                    .accessibilityLabel("Add activation list")
                }
            }
            .sheet(isPresented: $showingCreateSheet) {
                CreateActivationView()
            }
            .alert("Delete Activation List?", isPresented: $showingDeleteAlert, presenting: activationToDelete) { activation in
                Button("Cancel", role: .cancel) {
                    activationToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    deleteActivation(activation)
                }
            } message: { activation in
                Text("Are you sure you want to delete \"\(activation.title)\"? This action cannot be undone.")
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
                Text("Get Active")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(TextColors.primary)
                
                Text("Create your first activation list to engage in meaningful activities")
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
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(activation.title). \(activation.activities.count) activities\(activation.isPredefined ? ". Built-in list" : "")")
        .accessibilityHint("Double tap to view details")
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

