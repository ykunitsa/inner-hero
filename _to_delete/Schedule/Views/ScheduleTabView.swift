import SwiftUI
import SwiftData

struct ScheduleTabView: View {
    @Binding var path: NavigationPath

    @Environment(\.modelContext) private var modelContext
    @Environment(\.scheduleViewModel) private var scheduleViewModel
    @Environment(NotificationManager.self) private var notificationManager

    @Query(sort: \ExerciseAssignment.time) private var allAssignments: [ExerciseAssignment]
    @Query(sort: \Exposure.title) private var exposures: [Exposure]
    @Query(sort: \ActivationTask.title) private var activationTasks: [ActivationTask]

    @State private var selectedTab = 0
    @State private var showingNewScheduleSheet = false
    @State private var editingAssignment: ExerciseAssignment?
    @State private var assignmentToDelete: ExerciseAssignment?
    @State private var showingDeleteAlert = false
    @State private var appeared = false

    private var viewModel: ScheduleViewModel {
        guard let vm = scheduleViewModel else {
            fatalError("ScheduleViewModel must be injected via environment")
        }
        return vm
    }

    // MARK: - Body

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    if selectedTab == 0 {
                        todayView
                    } else {
                        allSchedulesView
                    }
                }
                .padding(.horizontal, Spacing.sm)
                .padding(.top, Spacing.md)
                .padding(.bottom, Spacing.xxl)
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                TopTabBar(
                    tabs: [
                        String(localized: "Today"),
                        String(localized: "All schedules")
                    ],
                    selection: $selectedTab
                )
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
            }
            .homeBackground()
            .navigationTitle(String(localized: "Schedule"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingNewScheduleSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.headline)
                            .foregroundStyle(TextColors.toolbar)
                    }
                    .accessibilityLabel(String(localized: "Add schedule"))
                }
            }
            .sheet(isPresented: $showingNewScheduleSheet) {
                ScheduleExerciseView(
                    viewModel: viewModel,
                    notificationManager: notificationManager
                )
            }
            .sheet(item: $editingAssignment) { assignment in
                ScheduleExerciseView(
                    assignment: assignment,
                    viewModel: viewModel,
                    notificationManager: notificationManager
                )
            }
            .alert(
                String(localized: "Delete schedule?"),
                isPresented: $showingDeleteAlert,
                presenting: assignmentToDelete
            ) { assignment in
                Button("Cancel", role: .cancel) { assignmentToDelete = nil }
                Button("Delete", role: .destructive) {
                    Task { await deleteAssignment(assignment) }
                }
            } message: { _ in
                Text(String(localized: "This action cannot be undone."))
            }
            .task(id: ScheduleRefreshId(
                date: viewModel.selectedDate,
                assignmentIds: allAssignments.map(\.id)
            )) {
                await viewModel.refresh(
                    context: modelContext,
                    allAssignments: allAssignments,
                    selectedDate: viewModel.selectedDate,
                    exposures: exposures,
                    activationTasks: activationTasks
                )
            }
            .navigationDestination(for: AppRoute.self) { route in
                AppRouteView(route: route)
            }
        }
    }

    // MARK: - Today Tab

    private var todayView: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // Date header
            todayHeader

            // Planned assignments
            if viewModel.plannedAssignments.isEmpty {
                todayEmptyState
            } else {
                plannedSection
            }

            // Completed entries (unscheduled sessions)
            if !viewModel.completedEntries.isEmpty {
                completedSection
            }
        }
        .opacity(appeared ? 1 : 0)
        .animation(AppAnimation.appear, value: appeared)
        .onAppear { appeared = true }
    }

    // MARK: - Today Header

    private var todayHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.selectedDate.formatted(.dateTime.weekday(.wide)))
                    .appFont(.h1)
                    .foregroundStyle(TextColors.primary)
                Text(viewModel.selectedDate.formatted(.dateTime.day().month(.wide).year()))
                    .appFont(.body)
                    .foregroundStyle(TextColors.secondary)
            }

            Spacer()

            // Done badge when all completed
            if !viewModel.plannedAssignments.isEmpty {
                let doneCount = viewModel.plannedAssignments.filter {
                    viewModel.manualCompletionByAssignmentId[$0.id] != nil
                }.count
                let total = viewModel.plannedAssignments.count

                HStack(spacing: Spacing.xxs) {
                    Text("\(doneCount)/\(total)")
                        .appFont(.bodyMedium)
                        .foregroundStyle(doneCount == total ? AppColors.positive : TextColors.secondary)
                        .monospacedDigit()
                    Image(systemName: doneCount == total ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 16))
                        .foregroundStyle(doneCount == total ? AppColors.positive : AppColors.gray300)
                }
            }
        }
    }

    // MARK: - Planned Section

    private var plannedSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            SectionLabel(text: String(localized: "Scheduled"))

            VStack(spacing: Spacing.xxs) {
                ForEach(viewModel.plannedAssignments) { assignment in
                    plannedRow(assignment)
                }
            }
        }
    }

    private func plannedRow(_ assignment: ExerciseAssignment) -> some View {
        let isDone = viewModel.manualCompletionByAssignmentId[assignment.id] != nil

        return HStack(spacing: Spacing.sm) {
            // Completion toggle
            Button {
                toggleManualCompletion(for: assignment)
            } label: {
                Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(isDone ? AppColors.positive : AppColors.gray300)
                    .animation(AppAnimation.fast, value: isDone)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isDone
                ? String(localized: "Remove completion mark")
                : String(localized: "Mark as completed"))

            // Icon
            Image(systemName: assignment.displayIcon)
                .font(.system(size: IconSize.glyph, weight: .medium))
                .foregroundStyle(isDone ? AppColors.positive : AppColors.primary)
                .iconContainer(
                    size: IconSize.card,
                    backgroundColor: (isDone ? AppColors.positive : AppColors.primary).opacity(Opacity.softBackground),
                    cornerRadius: CornerRadius.sm
                )
                .accessibilityHidden(true)

            // Labels
            VStack(alignment: .leading, spacing: 2) {
                Text(assignment.displayTitle(exposures: exposures, activationTasks: activationTasks))
                    .appFont(.bodyMedium)
                    .foregroundStyle(isDone ? TextColors.secondary : TextColors.primary)
                    .strikethrough(isDone, color: TextColors.secondary)
                    .lineLimit(1)

                HStack(spacing: Spacing.xxs) {
                    Text(ScheduleViewModel.timeFormatter.string(from: assignment.time))
                        .appFont(.small)
                        .foregroundStyle(TextColors.secondary)
                        .monospacedDigit()

                    if !assignment.isActive {
                        Text("·")
                            .appFont(.small)
                            .foregroundStyle(TextColors.tertiary)
                        Text(String(localized: "Inactive"))
                            .appFont(.smallMedium)
                            .foregroundStyle(AppColors.State.warning)
                    }
                }
            }

            Spacer(minLength: 0)

            // Actions menu
            Menu {
                Button {
                    editingAssignment = assignment
                } label: {
                    Label(String(localized: "Edit"), systemImage: "pencil")
                }
                Button(role: .destructive) {
                    assignmentToDelete = assignment
                    showingDeleteAlert = true
                } label: {
                    Label(String(localized: "Delete"), systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundStyle(TextColors.tertiary)
                    .touchTarget()
            }
            .accessibilityLabel(String(localized: "Actions"))
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .cardStyle(cornerRadius: CornerRadius.lg, padding: 0)
        .contentShape(Rectangle())
        .onTapGesture { editingAssignment = assignment }
    }

    // MARK: - Completed Section (unscheduled sessions)

    private var completedSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            SectionLabel(text: String(localized: "Also completed today"))

            VStack(spacing: Spacing.xxs) {
                ForEach(viewModel.completedEntries) { entry in
                    completedRow(entry)
                }
            }
        }
    }

    private func completedRow(_ entry: CompletedEntry) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: entry.systemImage)
                .font(.system(size: IconSize.glyph, weight: .medium))
                .foregroundStyle(AppColors.positive)
                .iconContainer(
                    size: IconSize.card,
                    backgroundColor: AppColors.positive.opacity(Opacity.softBackground),
                    cornerRadius: CornerRadius.sm
                )
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.title)
                    .appFont(.bodyMedium)
                    .foregroundStyle(TextColors.primary)
                    .lineLimit(1)

                HStack(spacing: Spacing.xxs) {
                    if let time = entry.timeString {
                        Text(time)
                            .appFont(.small)
                            .foregroundStyle(TextColors.secondary)
                            .monospacedDigit()
                    }
                    if let detail = entry.detail {
                        Text("·")
                            .appFont(.small)
                            .foregroundStyle(TextColors.tertiary)
                        Text(detail)
                            .appFont(.small)
                            .foregroundStyle(TextColors.secondary)
                    }
                }
            }

            Spacer(minLength: 0)

            Text(entry.sourceLabel)
                .appFont(.smallMedium)
                .foregroundStyle(TextColors.tertiary)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .cardStyle(cornerRadius: CornerRadius.lg, padding: 0)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(entry.title)
    }

    // MARK: - Today Empty State

    private var todayEmptyState: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(AppColors.gray300)
                .accessibilityHidden(true)

            VStack(spacing: Spacing.xxs) {
                Text(String(localized: "Nothing scheduled today"))
                    .appFont(.h2)
                    .foregroundStyle(TextColors.primary)
                Text(String(localized: "Add exercises to your schedule so they appear here with reminders"))
                    .appFont(.body)
                    .foregroundStyle(TextColors.secondary)
                    .multilineTextAlignment(.center)
            }

            PrimaryButton(
                title: String(localized: "Add schedule"),
                systemImage: "plus",
                color: AppColors.primary
            ) {
                showingNewScheduleSheet = true
            }
            .padding(.top, Spacing.xxs)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.xl)
        .accessibilityElement(children: .combine)
    }

    // MARK: - All Schedules Tab

    private var allSchedulesView: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            let active = allAssignments.filter { $0.isActive }
            let inactive = allAssignments.filter { !$0.isActive }

            if allAssignments.isEmpty {
                allSchedulesEmptyState
            } else {
                if !active.isEmpty {
                    SectionLabel(text: String(localized: "Active"))
                    VStack(spacing: Spacing.xxs) {
                        ForEach(active) { assignment in
                            scheduleManageRow(assignment)
                        }
                    }
                }

                if !inactive.isEmpty {
                    SectionLabel(text: String(localized: "Inactive"))
                        .padding(.top, Spacing.xs)
                    VStack(spacing: Spacing.xxs) {
                        ForEach(inactive) { assignment in
                            scheduleManageRow(assignment)
                        }
                    }
                }
            }
        }
    }

    private func scheduleManageRow(_ assignment: ExerciseAssignment) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: assignment.displayIcon)
                .font(.system(size: IconSize.glyph, weight: .medium))
                .foregroundStyle(assignment.isActive ? AppColors.primary : AppColors.gray400)
                .iconContainer(
                    size: IconSize.card,
                    backgroundColor: (assignment.isActive ? AppColors.primary : AppColors.gray400).opacity(Opacity.softBackground),
                    cornerRadius: CornerRadius.sm
                )
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(assignment.displayTitle(exposures: exposures, activationTasks: activationTasks))
                    .appFont(.bodyMedium)
                    .foregroundStyle(TextColors.primary)
                    .lineLimit(1)

                HStack(spacing: Spacing.xxs) {
                    Text(ScheduleViewModel.timeFormatter.string(from: assignment.time))
                        .appFont(.small)
                        .foregroundStyle(TextColors.secondary)
                        .monospacedDigit()
                    Text("·")
                        .appFont(.small)
                        .foregroundStyle(TextColors.tertiary)
                    Text(assignment.getDayNamesString())
                        .appFont(.small)
                        .foregroundStyle(TextColors.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)

            // Active toggle
            Toggle("", isOn: Binding(
                get: { assignment.isActive },
                set: { newValue in
                    Task { await toggleScheduleActive(assignment, isActive: newValue) }
                }
            ))
            .labelsHidden()
            .tint(AppColors.primary)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .cardStyle(cornerRadius: CornerRadius.lg, padding: 0)
        .contentShape(Rectangle())
        .onTapGesture { editingAssignment = assignment }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                assignmentToDelete = assignment
                showingDeleteAlert = true
            } label: {
                Label(String(localized: "Delete"), systemImage: "trash")
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(assignment.displayTitle(exposures: exposures, activationTasks: activationTasks))
    }

    // MARK: - All Schedules Empty State

    private var allSchedulesEmptyState: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "bell.badge.slash")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(AppColors.gray300)
                .accessibilityHidden(true)

            VStack(spacing: Spacing.xxs) {
                Text(String(localized: "No schedules yet"))
                    .appFont(.h2)
                    .foregroundStyle(TextColors.primary)
                Text(String(localized: "Create a schedule to get reminders and track your exercise routine"))
                    .appFont(.body)
                    .foregroundStyle(TextColors.secondary)
                    .multilineTextAlignment(.center)
            }

            PrimaryButton(
                title: String(localized: "Create schedule"),
                systemImage: "plus",
                color: AppColors.primary
            ) {
                showingNewScheduleSheet = true
            }
            .padding(.top, Spacing.xxs)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.xl)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Actions

    private func toggleManualCompletion(for assignment: ExerciseAssignment) {
        let wasDone = viewModel.manualCompletionByAssignmentId[assignment.id] != nil
        do {
            try viewModel.markCompleted(
                assignment: assignment,
                context: modelContext,
                selectedDate: viewModel.selectedDate
            )
            wasDone ? HapticFeedback.selection() : HapticFeedback.success()
        } catch {
            HapticFeedback.error()
        }
        Task {
            await viewModel.refresh(
                context: modelContext,
                allAssignments: allAssignments,
                selectedDate: viewModel.selectedDate,
                exposures: exposures,
                activationTasks: activationTasks
            )
        }
    }

    private func toggleScheduleActive(_ assignment: ExerciseAssignment, isActive: Bool) async {
        do {
            try await viewModel.updateAssignment(
                assignment,
                context: modelContext,
                isActive: isActive,
                notificationManager: notificationManager
            )
            HapticFeedback.selection()
        } catch {
            HapticFeedback.error()
        }
    }

    private func deleteAssignment(_ assignment: ExerciseAssignment) async {
        do {
            try await viewModel.deleteAssignment(
                assignment,
                context: modelContext,
                notificationManager: notificationManager
            )
            assignmentToDelete = nil
            HapticFeedback.success()
        } catch {
            HapticFeedback.error()
        }
        await viewModel.refresh(
            context: modelContext,
            allAssignments: allAssignments,
            selectedDate: viewModel.selectedDate,
            exposures: exposures,
            activationTasks: activationTasks
        )
    }
}

// MARK: - Helpers

private struct ScheduleRefreshId: Equatable {
    let date: Date
    let assignmentIds: [UUID]
}

// MARK: - Preview

#Preview {
    ScheduleTabView(path: .constant(NavigationPath()))
        .environment(\.scheduleViewModel, ScheduleViewModel())
        .environment(NotificationManager())
        .modelContainer(
            for: [
                ExerciseAssignment.self,
                ExerciseCompletion.self,
                Exposure.self,
                ActivationTask.self
            ],
            inMemory: true
        )
}
