import SwiftData
import SwiftUI

/// The activity store (spec §6) — the door opened on a good day.
///
/// This is the one screen in BA that is allowed to be a list, because it is the
/// one screen never reached on an empty tank: it lives behind a quiet line, and
/// nothing in the "Одно дело" path leads here by default.
///
/// It is also the only place in the exercise with a keyboard, and that is the
/// trade the spec makes on purpose: the store is worth having in the user's own
/// words, and this is the moment they have the energy to type them.
struct BAActivitiesView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \BAActivity.createdAt) private var activities: [BAActivity]

    @State private var viewModel = BAActivitiesViewModel()
    @State private var showAdd = false
    @State private var showSaveError = false

    var body: some View {
        NavigationStack {
            Group {
                if activities.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
            .navigationTitle(String(localized: "Activities"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(String(localized: "Close")) { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel(String(localized: "Add an activity"))
                }
            }
            .sheet(isPresented: $showAdd) {
                BAAddActivityView(viewModel: viewModel)
            }
            .alert(
                String(localized: "Couldn't save"),
                isPresented: $showSaveError
            ) {
                Button(String(localized: "OK"), role: .cancel) {}
            } message: {
                Text(String(localized: "Try again in a moment."))
            }
        }
    }

    private var list: some View {
        List {
            ForEach(viewModel.grouped(activities), id: \.basket) { group in
                Section {
                    ForEach(group.items) { activity in
                        Text(activity.title)
                            .appFont(.body)
                            .foregroundStyle(TextColors.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    // The system list supplies the swipe *and* the VoiceOver
                    // "Delete" action from this one modifier — a hand-rolled
                    // swipe would have shipped only the first of the two.
                    .onDelete { offsets in
                        delete(offsets.map { group.items[$0] })
                    }
                    .listRowBackground(AppColors.cardBackground)
                } header: {
                    SectionLabel(text: group.basket.title)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .formBackground()
    }

    /// Only reachable by deleting everything, which is a decision — so this is a
    /// quiet line and a way back, not a poster asking to be filled in.
    private var emptyState: some View {
        VStack(spacing: Spacing.xs) {
            Text(String(localized: "Nothing here yet."))
                .appFont(.body)
                .foregroundStyle(TextColors.secondary)

            Button {
                showAdd = true
            } label: {
                Text(String(localized: "Add an activity"))
                    .appFont(.body)
                    .foregroundStyle(AppColors.accent)
                    .frame(minHeight: TouchTarget.minimum)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .formBackground()
    }

    private func delete(_ items: [BAActivity]) {
        do {
            for item in items {
                try viewModel.delete(item, in: modelContext)
            }
        } catch {
            HapticFeedback.error()
            showSaveError = true
        }
    }
}

#Preview {
    BAActivitiesView()
        .modelContainer(for: [BAActivity.self, BALogEntry.self], inMemory: true)
}
