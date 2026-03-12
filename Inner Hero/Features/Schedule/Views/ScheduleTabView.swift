import SwiftUI
import SwiftData

struct ScheduleTabView: View {
    @Binding var path: NavigationPath

    @Environment(\.modelContext) private var modelContext
    @Environment(\.scheduleViewModel) private var scheduleViewModel
    @Environment(NotificationManager.self) private var notificationManager

    @Query(sort: \ExerciseAssignment.time) private var allAssignments: [ExerciseAssignment]
    @Query(sort: \Exposure.title) private var exposures: [Exposure]
    @Query(sort: \ActivityList.title) private var activityLists: [ActivityList]

    @State private var showingNewScheduleSheet = false
    @State private var editingAssignment: ExerciseAssignment?
    @State private var assignmentToDelete: ExerciseAssignment?
    @State private var showingDeleteAlert = false

    private var viewModel: ScheduleViewModel {
        guard let vm = scheduleViewModel else { fatalError("ScheduleViewModel must be injected via environment") }
        return vm
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                LazyVStack(spacing: 16) {
                    WeekStripView(selectedDate: Binding(
                        get: { viewModel.selectedDate },
                        set: { viewModel.selectedDate = $0 }
                    ))
                    .padding(.top, 8)

                    progressCard

                    plannedSection

                    completedSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .background(TopMeshGradientBackground())
            .navigationTitle("Schedule")
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
                    .accessibilityLabel("Add schedule")
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
            .alert("Delete schedule?", isPresented: $showingDeleteAlert, presenting: assignmentToDelete) { assignment in
                Button("Cancel", role: .cancel) {
                    assignmentToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    Task {
                        await deleteAssignment(assignment)
                    }
                }
            } message: { _ in
                Text("This action cannot be undone.")
            }
            .task(id: ScheduleRefreshId(date: viewModel.selectedDate, assignmentIds: allAssignments.map(\.id))) {
                await viewModel.refresh(
                    context: modelContext,
                    allAssignments: allAssignments,
                    selectedDate: viewModel.selectedDate,
                    exposures: exposures,
                    activityLists: activityLists
                )
            }
            .navigationDestination(for: AppRoute.self) { route in
                AppRouteView(route: route)
            }
        }
    }

    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(
                        LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                Text("Progress")
                    .font(.headline)
                    .foregroundStyle(TextColors.primary)
                Spacer()
            }

            HStack(spacing: 16) {
                stat(title: "Completed (wk.)", value: "\(viewModel.weekProgress.completedThisWeek)")
                Divider()
                stat(title: "On schedule (wk.)", value: "\(viewModel.weekProgress.plannedDoneThisWeek)")
                Divider()
                stat(
                    title: "Streak",
                    value: String(format: NSLocalizedString("%d d", comment: ""), viewModel.weekProgress.streakDays)
                )
            }
        }
        .accentCardStyle(accentColor: .blue, cornerRadius: 16, padding: 16)
    }

    private func stat(title: LocalizedStringKey, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(TextColors.secondary)
            Text(value)
                .font(.title3.monospacedDigit().weight(.semibold))
                .foregroundStyle(TextColors.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var plannedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Scheduled")
                    .font(.headline)
                    .foregroundStyle(TextColors.primary)
                Spacer()

                Button {
                    showingNewScheduleSheet = true
                } label: {
                    Label("Add", systemImage: "plus")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.borderless)
            }

            if viewModel.plannedAssignments.isEmpty {
                ContentUnavailableView(
                    "No schedules for the day",
                    systemImage: "calendar.badge.exclamationmark",
                    description: Text("Add an exercise to the schedule—it will appear here")
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            } else {
                VStack(spacing: 0) {
                    ForEach(viewModel.plannedAssignments) { assignment in
                        plannedRow(assignment)
                            .padding(.vertical, 10)

                        if assignment.id != viewModel.plannedAssignments.last?.id {
                            Divider()
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
                )
            }
        }
    }

    private func plannedRow(_ assignment: ExerciseAssignment) -> some View {
        let isDone = viewModel.manualCompletionByAssignmentId[assignment.id] != nil

        return HStack(spacing: 12) {
            Button {
                toggleManualCompletion(for: assignment)
            } label: {
                Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isDone ? .green : TextColors.tertiary)
                    .accessibilityLabel(Text(isDone ? "Remove completion mark" : "Mark as completed"))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(assignment.displayTitle(exposures: exposures, activityLists: activityLists))
                    .font(.body.weight(.medium))
                    .foregroundStyle(TextColors.primary)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Text(timeOnlyString(from: assignment.time))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(TextColors.secondary)

                    if !assignment.isActive {
                        Text("Inactive")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.orange)
                    }
                }
            }

            Spacer()

            Menu {
                Button {
                    editingAssignment = assignment
                } label: {
                    Label("Edit", systemImage: "pencil")
                }

                Button(role: .destructive) {
                    assignmentToDelete = assignment
                    showingDeleteAlert = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundStyle(TextColors.tertiary)
                    .touchTarget()
                    .accessibilityLabel("Actions")
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            editingAssignment = assignment
        }
    }

    private var completedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Completed")
                .font(.headline)
                .foregroundStyle(TextColors.primary)

            if viewModel.completedEntries.isEmpty {
                ContentUnavailableView(
                    "Nothing completed yet",
                    systemImage: "checkmark.seal",
                    description: Text("Completed sessions and manual entries for the selected day will appear here")
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            } else {
                VStack(spacing: 0) {
                    ForEach(viewModel.completedEntries) { entry in
                        completedRow(entry)
                            .padding(.vertical, 10)

                        if entry.id != viewModel.completedEntries.last?.id {
                            Divider()
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
                )
            }
        }
    }

    private func completedRow(_ entry: CompletedEntry) -> some View {
        HStack(spacing: 12) {
            Image(systemName: entry.systemImage)
                .font(.title3)
                .foregroundStyle(entry.tint)
                .frame(width: 28)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(TextColors.primary)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    if let time = entry.timeString {
                        Text(time)
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(TextColors.secondary)
                    }
                    if let detail = entry.detail {
                        Text(detail)
                            .font(.caption)
                            .foregroundStyle(TextColors.secondary)
                    }
                    Spacer(minLength: 0)
                    Text(entry.sourceLabel)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(TextColors.tertiary)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            String(
                format: NSLocalizedString("%@. %@", comment: ""),
                entry.title,
                entry.sourceLabel
            )
        )
    }

    private func toggleManualCompletion(for assignment: ExerciseAssignment) {
        let wasDone = viewModel.manualCompletionByAssignmentId[assignment.id] != nil
        do {
            try viewModel.markCompleted(assignment: assignment, context: modelContext, selectedDate: viewModel.selectedDate)
            if wasDone { HapticFeedback.selection() } else { HapticFeedback.success() }
        } catch {
            HapticFeedback.error()
        }
        Task {
            await viewModel.refresh(
                context: modelContext,
                allAssignments: allAssignments,
                selectedDate: viewModel.selectedDate,
                exposures: exposures,
                activityLists: activityLists
            )
        }
    }

    private func deleteAssignment(_ assignment: ExerciseAssignment) async {
        do {
            try await viewModel.deleteAssignment(assignment, context: modelContext, notificationManager: notificationManager)
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
            activityLists: activityLists
        )
    }

    private func timeOnlyString(from date: Date) -> String {
        ScheduleViewModel.timeFormatter.string(from: date)
    }
}

private struct ScheduleRefreshId: Equatable {
    let date: Date
    let assignmentIds: [UUID]
}

#Preview {
    ScheduleTabView(path: .constant(NavigationPath()))
        .environment(\.scheduleViewModel, ScheduleViewModel())
        .environment(NotificationManager())
        .modelContainer(
            for: [
                ExerciseAssignment.self,
                ExerciseCompletion.self,
                Exposure.self,
                ActivityList.self
            ],
            inMemory: true
        )
}
