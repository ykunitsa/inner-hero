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

    // MARK: - Computed

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

    private var pinnedIDs: Set<UUID> { Set(pinnedActivations.map(\.id)) }

    private var userCreated: [ActivityList] {
        activations.filter { !pinnedIDs.contains($0.id) && !$0.isPredefined }
    }

    private var predefined: [ActivityList] {
        activations.filter { !pinnedIDs.contains($0.id) && $0.isPredefined }
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                if activations.isEmpty {
                    emptyState
                        .padding(.top, Spacing.xxxl)
                } else {
                    sectionsContent
                }
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.xxl)
        }
        .homeBackground()
        .navigationTitle(String(localized: "Behavioral activation"))
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingCreateSheet = true } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(TextColors.toolbar)
                }
                .touchTarget()
                .accessibilityLabel(String(localized: "Add activity list"))
            }
        }
        .sheet(isPresented: $showingCreateSheet) {
            CreateActivationView()
        }
        .alert(
            String(localized: "Delete activity list?"),
            isPresented: $showingDeleteAlert,
            presenting: activationToDelete
        ) { item in
            Button("Cancel", role: .cancel) { activationToDelete = nil }
            Button("Delete", role: .destructive) { delete(item) }
        } message: { item in
            Text(String(
                format: String(localized: "Are you sure you want to delete the list \"%@\"? This action cannot be undone."),
                item.localizedTitle
            ))
        }
        .opacity(appeared ? 1 : 0)
        .animation(AppAnimation.appear, value: appeared)
        .onAppear { appeared = true }
    }

    // MARK: - Sections

    @ViewBuilder
    private var sectionsContent: some View {
        if !pinnedActivations.isEmpty {
            listSection(
                title: String(localized: "Pinned"),
                items: pinnedActivations,
                baseDelay: 0
            )
        }
        if !userCreated.isEmpty {
            listSection(
                title: String(localized: "Created by me"),
                items: userCreated,
                baseDelay: pinnedActivations.count
            )
        }
        if !predefined.isEmpty {
            listSection(
                title: String(localized: "Predefined"),
                items: predefined,
                baseDelay: pinnedActivations.count + userCreated.count
            )
        }
    }

    private func listSection(title: String, items: [ActivityList], baseDelay: Int) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            SectionHeader(title: title)

            VStack(spacing: Spacing.xxs) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    activationRow(item)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 10)
                        .animation(
                            AppAnimation.appear.delay(Double(baseDelay + index) * 0.05),
                            value: appeared
                        )
                }
            }
        }
    }

    private func activationRow(_ item: ActivityList) -> some View {
        NavigationLink(value: AppRoute.activationView(activityListId: item.id, assignmentId: nil)) {
            ActivationCardView(activation: item)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            if !item.isPredefined {
                Button(role: .destructive) {
                    activationToDelete = item
                    showingDeleteAlert = true
                } label: {
                    Label(String(localized: "Delete"), systemImage: "trash")
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(item.localizedTitle). \(item.localizedActivities.count) \(String(localized: "activities"))"
            + (item.isPredefined ? ". \(String(localized: "Predefined list"))" : "")
        )
        .accessibilityHint(String(localized: "Double tap to view details"))
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "figure.walk.circle")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(AppColors.positive.opacity(0.6))
                .accessibilityHidden(true)

            VStack(spacing: Spacing.xxs) {
                Text(String(localized: "Start taking action"))
                    .appFont(.h2)
                    .foregroundStyle(TextColors.primary)

                Text(String(localized: "Create your first activity list for behavioral activation"))
                    .appFont(.body)
                    .foregroundStyle(TextColors.secondary)
                    .multilineTextAlignment(.center)
            }

            PrimaryButton(
                title: String(localized: "Create activity list"),
                color: AppColors.positive
            ) {
                showingCreateSheet = true
            }
            .padding(.top, Spacing.xxs)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, Spacing.md)
    }

    // MARK: - Actions

    private func delete(_ item: ActivityList) {
        withAnimation(AppAnimation.standard) {
            modelContext.delete(item)
            activationToDelete = nil
        }
    }
}

#Preview {
    NavigationStack {
        ActivationsListView()
    }
    .modelContainer(for: ActivityList.self, inMemory: true)
}
