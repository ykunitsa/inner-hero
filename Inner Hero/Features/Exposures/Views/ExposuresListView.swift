import SwiftUI
import SwiftData

struct ExposuresListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scheduleViewModel) private var scheduleViewModel
    @Environment(NotificationManager.self) private var notificationManager

    @Query(sort: \Exposure.createdAt, order: .reverse) private var exposures: [Exposure]
    @Query(sort: \ExposureSessionResult.startAt, order: .reverse) private var allSessions: [ExposureSessionResult]
    @Query(sort: \ExerciseAssignment.createdAt) private var allAssignments: [ExerciseAssignment]
    @Query(sort: \FavoriteExercise.createdAt, order: .reverse) private var favorites: [FavoriteExercise]

    @State private var showingCreateSheet = false
    @State private var exposureToDelete: Exposure?
    @State private var showingDeleteAlert = false
    @State private var exposureToStart: Exposure?
    @State private var currentSession: ExposureSessionResult?
    @State private var exposureToSchedule: Exposure?
    @State private var appeared = false

    // MARK: - Computed

    private var activeSessions: [ExposureSessionResult] {
        allSessions.filter { $0.endAt == nil }
    }

    private var primaryActiveSession: ExposureSessionResult? {
        activeSessions.first
    }

    private var extraActiveSessionsCount: Int {
        max(0, activeSessions.count - 1)
    }

    private var pinnedExposures: [Exposure] {
        let exposureById = Dictionary(uniqueKeysWithValues: exposures.map { ($0.id, $0) })
        var seen = Set<UUID>()
        return favorites
            .filter { $0.exerciseType == .exposure }
            .compactMap { $0.exerciseId }
            .compactMap { id in
                guard seen.insert(id).inserted else { return nil }
                return exposureById[id]
            }
    }

    private var pinnedExposureIDs: Set<UUID> {
        Set(pinnedExposures.map(\.id))
    }

    private var userCreatedExposures: [Exposure] {
        exposures.filter { !pinnedExposureIDs.contains($0.id) && !$0.isPredefined }
    }

    private var predefinedExposures: [Exposure] {
        exposures.filter { !pinnedExposureIDs.contains($0.id) && $0.isPredefined }
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Spacing.lg) {

                // ── Active session banner (first item, scrolls with content) ──
                if let session = primaryActiveSession,
                   let exposure = session.exposure {
                    ActiveSessionBanner(
                        session: session,
                        exposure: exposure,
                        extraCount: extraActiveSessionsCount
                    ) {
                        currentSession = session
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                if exposures.isEmpty {
                    emptyStateView
                        .padding(.top, Spacing.xxl)
                } else {
                    exposuresSections
                }
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.xxl)
        }
        .homeBackground()
        .navigationTitle(String(localized: "Exposures"))
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
                .accessibilityLabel(String(localized: "Add exposure"))
            }
        }
        .sheet(isPresented: $showingCreateSheet) {
            CreateExposureView()
        }
        .sheet(item: $exposureToStart) { exposure in
            StartSessionSheet(exposure: exposure) { session in
                currentSession = session
            }
        }
        .sheet(item: $exposureToSchedule) { exposure in
            if let viewModel = scheduleViewModel {
                ScheduleExerciseView(
                    assignment: nil,
                    viewModel: viewModel,
                    notificationManager: notificationManager,
                    preSelectedExposureId: exposure.id
                )
            }
        }
        .navigationDestination(item: $currentSession) { session in
            if let exposure = session.exposure {
                ActiveSessionView(session: session, exposure: exposure)
            }
        }
        .alert(String(localized: "Delete exposure?"),
               isPresented: $showingDeleteAlert,
               presenting: exposureToDelete) { exposure in
            Button("Cancel", role: .cancel) { exposureToDelete = nil }
            Button("Delete", role: .destructive) { deleteExposure(exposure) }
        } message: { exposure in
            Text(String(format: String(localized: "Are you sure you want to delete \"%@\"? This action cannot be undone."),
                        exposure.localizedTitle))
        }
        .opacity(appeared ? 1 : 0)
        .animation(AppAnimation.appear, value: appeared)
        .onAppear { appeared = true }
    }

    // MARK: - Sections

    @ViewBuilder
    private var exposuresSections: some View {
        if !pinnedExposures.isEmpty {
            exposuresSection(
                title: String(localized: "Pinned"),
                exposures: pinnedExposures,
                startIndex: 0
            )
        }
        if !userCreatedExposures.isEmpty {
            exposuresSection(
                title: String(localized: "Created by me"),
                exposures: userCreatedExposures,
                startIndex: pinnedExposures.count
            )
        }
        if !predefinedExposures.isEmpty {
            exposuresSection(
                title: String(localized: "Predefined"),
                exposures: predefinedExposures,
                startIndex: pinnedExposures.count + userCreatedExposures.count
            )
        }
    }

    private func exposuresSection(title: String, exposures: [Exposure], startIndex: Int) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            SectionHeader(title: title)
            VStack(spacing: Spacing.xxs) {
                ForEach(Array(exposures.enumerated()), id: \.element.id) { index, exposure in
                    exposureRow(exposure: exposure)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 12)
                        .animation(
                            AppAnimation.appear.delay(Double(startIndex + index) * 0.05),
                            value: appeared
                        )
                }
            }
        }
    }

    private func exposureRow(exposure: Exposure) -> some View {
        let assignment = allAssignments.first {
            $0.exerciseType == .exposure && $0.exposureId == exposure.id
        }
        return NavigationLink(destination: ExposureDetailView(
            exposure: exposure,
            onStartSession: { startSession(for: exposure) }
        )) {
            ExposureCardView(exposure: exposure, assignment: assignment)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                startSession(for: exposure)
            } label: {
                Label(String(localized: "Start session"), systemImage: "play.fill")
            }
            Button {
                exposureToSchedule = exposure
            } label: {
                Label(
                    assignment?.isActive == true
                        ? String(localized: "Edit schedule")
                        : String(localized: "Create schedule"),
                    systemImage: "calendar"
                )
            }
            Divider()
            Button(role: .destructive) {
                exposureToDelete = exposure
                showingDeleteAlert = true
            } label: {
                Label(String(localized: "Delete"), systemImage: "trash")
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(
            format: String(localized: "%@. %d steps, %d sessions"),
            exposure.localizedTitle,
            exposure.localizedStepTexts.count,
            exposure.sessionResults.count
        ))
        .accessibilityHint(String(localized: "Double tap to view details"))
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "leaf.circle")
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(AppColors.primary.opacity(0.7))
                .accessibilityHidden(true)

            VStack(spacing: Spacing.xxs) {
                Text(String(localized: "Start your journey"))
                    .appFont(.h2)
                    .foregroundStyle(TextColors.primary)
                Text(String(localized: "Create your first exposure to work with anxiety"))
                    .appFont(.body)
                    .foregroundStyle(TextColors.secondary)
                    .multilineTextAlignment(.center)
            }

            PrimaryButton(title: String(localized: "Create exposure")) {
                showingCreateSheet = true
            }
            .padding(.top, Spacing.xxs)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, Spacing.lg)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Actions

    private func startSession(for exposure: Exposure) {
        exposureToStart = exposure
    }

    private func deleteExposure(_ exposure: Exposure) {
        withAnimation(AppAnimation.standard) {
            modelContext.delete(exposure)
            exposureToDelete = nil
        }
    }
}

#Preview {
    NavigationStack {
        ExposuresListView()
    }
}
