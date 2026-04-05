import SwiftUI
import SwiftData

struct BALibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var activities: [BAActivity]

    @State private var showingAddSheet = false
    @State private var activityToDelete: BAActivity?
    @State private var showingDeleteConfirmation = false

    // Activities used at least once or custom-created, sorted by usage
    private var myActivities: [BAActivity] {
        activities
            .filter { $0.isCustom || $0.timesUsed > 0 }
            .sorted { $0.timesUsed > $1.timesUsed }
    }

    private var predefinedActivities: [BAActivity] {
        activities.filter { !$0.isCustom }
    }

    private func catalogActivities(for lifeValue: LifeValue) -> [BAActivity] {
        predefinedActivities
            .filter { $0.lifeValue == lifeValue }
            .sorted { $0.localizedTitle < $1.localizedTitle }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Spacing.lg) {
                myActivitiesSection
                catalogSection
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.sm)
        }
        .homeBackground()
        .navigationTitle(String(localized: "Activity Library"))
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddBAActivitySheet()
        }
        .confirmationDialog(
            String(localized: "Delete Activity?"),
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(String(localized: "Delete"), role: .destructive) {
                if let activity = activityToDelete {
                    modelContext.delete(activity)
                    activityToDelete = nil
                }
            }
            Button(String(localized: "Cancel"), role: .cancel) {
                activityToDelete = nil
            }
        } message: {
            Text(String(localized: "This activity will be permanently removed."))
        }
    }

    // MARK: - My Activities Section

    private var myActivitiesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            SectionHeader(title: String(localized: "My Activities"))

            if myActivities.isEmpty {
                emptyMyActivitiesState
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(myActivities.enumerated()), id: \.element.id) { index, activity in
                        if index > 0 {
                            Divider()
                                .padding(.leading, IconSize.inline + Spacing.sm + Spacing.lg)
                        }
                        myActivityRow(activity)
                            .contextMenu {
                                if activity.isCustom {
                                    Button(role: .destructive) {
                                        activityToDelete = activity
                                        showingDeleteConfirmation = true
                                    } label: {
                                        Label(
                                            String(localized: "Delete"),
                                            systemImage: "trash"
                                        )
                                    }
                                }
                            }
                    }
                }
                .cardStyle()
            }
        }
    }

    @ViewBuilder
    private func myActivityRow(_ activity: BAActivity) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: activity.lifeValue.systemIconName)
                .font(.system(size: IconSize.glyph))
                .foregroundStyle(AppColors.accent)
                .frame(width: IconSize.inline, height: IconSize.inline)

            VStack(alignment: .leading, spacing: 2) {
                Text(activity.localizedTitle)
                    .appFont(.bodyMedium)
                    .foregroundStyle(TextColors.primary)

                if activity.timesUsed > 0 {
                    Text(
                        String(
                            format: String(localized: "Used %d times"),
                            activity.timesUsed
                        )
                    )
                    .appFont(.small)
                    .foregroundStyle(TextColors.secondary)
                }
            }

            Spacer()
        }
        .frame(minHeight: TouchTarget.standard)
    }

    private var emptyMyActivitiesState: some View {
        Text(String(localized: "Activities you use appear here"))
            .appFont(.body)
            .foregroundStyle(TextColors.tertiary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.xl)
            .cardStyle()
    }

    // MARK: - Catalog Section

    private var catalogSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            SectionHeader(title: String(localized: "Catalog"))

            VStack(spacing: 0) {
                ForEach(Array(LifeValue.allCases.enumerated()), id: \.element.id) { index, lifeValue in
                    let items = catalogActivities(for: lifeValue)
                    if !items.isEmpty {
                        if index > 0 {
                            Divider()
                                .padding(.leading, Spacing.lg)
                        }
                        CatalogDisclosureGroup(lifeValue: lifeValue, activities: items)
                    }
                }
            }
            .cardStyle()
        }
    }
}

// MARK: - CatalogDisclosureGroup

private struct CatalogDisclosureGroup: View {
    let lifeValue: LifeValue
    let activities: [BAActivity]

    @State private var isExpanded = false

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(spacing: 0) {
                ForEach(activities) { activity in
                    Divider()
                        .padding(.leading, Spacing.lg)

                    Text(activity.localizedTitle)
                        .appFont(.body)
                        .foregroundStyle(TextColors.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(minHeight: TouchTarget.standard)
                        .padding(.horizontal, Spacing.sm)
                }
            }
        } label: {
            HStack(spacing: Spacing.sm) {
                Image(systemName: lifeValue.systemIconName)
                    .font(.system(size: IconSize.glyph))
                    .foregroundStyle(AppColors.accent)
                    .frame(width: IconSize.inline, height: IconSize.inline)

                Text(lifeValue.localizedName)
                    .appFont(.bodyMedium)
                    .foregroundStyle(TextColors.primary)

                Spacer()

                Text("\(activities.count)")
                    .appFont(.small)
                    .foregroundStyle(TextColors.tertiary)
            }
            .frame(minHeight: TouchTarget.standard)
        }
        .padding(.horizontal, Spacing.sm)
        .animation(AppAnimation.spring, value: isExpanded)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        BALibraryView()
    }
    .modelContainer(for: [BAActivity.self, BASession.self], inMemory: true)
}
