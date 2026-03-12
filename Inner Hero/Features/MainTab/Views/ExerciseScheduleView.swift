import SwiftUI
import SwiftData

struct ExerciseScheduleView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scheduleViewModel) private var scheduleViewModel
    @Environment(NotificationManager.self) private var notificationManager

    @Query(sort: \ExerciseAssignment.time) private var allAssignments: [ExerciseAssignment]
    @Query(sort: \Exposure.title) private var exposures: [Exposure]
    @Query(sort: \ActivityList.title) private var activityLists: [ActivityList]

    @State private var assignmentToEdit: ExerciseAssignment?
    @State private var showingEditSheet = false
    @State private var assignmentToDelete: ExerciseAssignment?
    @State private var showingDeleteAlert = false

    private var activeAssignments: [ExerciseAssignment] {
        allAssignments.filter { $0.isActive }
    }

    private var inactiveAssignments: [ExerciseAssignment] {
        allAssignments.filter { !$0.isActive }
    }

    var body: some View {
        Group {
            if let viewModel = scheduleViewModel {
                content(viewModel: viewModel, notificationManager: notificationManager)
            } else {
                ContentUnavailableView(
                    "Schedule",
                    systemImage: "calendar.badge.exclamationmark",
                    description: Text("Schedule is not available in this context.")
                )
            }
        }
    }

    private func content(viewModel: ScheduleViewModel, notificationManager: NotificationManager) -> some View {
        NavigationStack {
            List {
                if allAssignments.isEmpty {
                    emptyStateView(viewModel: viewModel, notificationManager: notificationManager)
                } else {
                    if !activeAssignments.isEmpty {
                        Section {
                            ForEach(activeAssignments) { assignment in
                                scheduleRow(
                                    assignment: assignment,
                                    viewModel: viewModel,
                                    notificationManager: notificationManager
                                )
                            }
                        } header: {
                            Text("Active schedules")
                        }
                    }

                    if !inactiveAssignments.isEmpty {
                        Section {
                            ForEach(inactiveAssignments) { assignment in
                                scheduleRow(
                                    assignment: assignment,
                                    viewModel: viewModel,
                                    notificationManager: notificationManager
                                )
                            }
                        } header: {
                            Text("Inactive schedules")
                        }
                    }
                }
            }
            .navigationTitle("Schedule")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        assignmentToEdit = nil
                        showingEditSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.headline)
                            .foregroundStyle(TextColors.toolbar)
                    }
                    .accessibilityLabel("Add schedule")
                }
            }
            .sheet(isPresented: $showingEditSheet) {
                ScheduleExerciseView(
                    assignment: assignmentToEdit,
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
                        await deleteAssignment(assignment, viewModel: viewModel, notificationManager: notificationManager)
                    }
                }
            } message: { _ in
                Text("Are you sure you want to delete this schedule?")
            }
        }
    }

    private func emptyStateView(viewModel: ScheduleViewModel, notificationManager: NotificationManager) -> some View {
        VStack(spacing: 24) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 72))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue.opacity(0.6), .cyan.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .accessibilityHidden(true)

            VStack(spacing: 12) {
                Text("No schedules")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(TextColors.primary)

                Text("Create a schedule for regular exercise reminders")
                    .font(.body)
                    .foregroundStyle(TextColors.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
        .accessibilityElement(children: .combine)
    }

    private func scheduleRow(
        assignment: ExerciseAssignment,
        viewModel: ScheduleViewModel,
        notificationManager: NotificationManager
    ) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(assignment.displayTitle(exposures: exposures, activityLists: activityLists))
                    .font(.headline)
                    .foregroundStyle(TextColors.primary)

                HStack(spacing: 12) {
                    Label(timeString(from: assignment.time), systemImage: "clock")
                        .font(.subheadline)
                        .foregroundStyle(TextColors.secondary)

                    Text(assignment.getDayNamesString())
                        .font(.subheadline)
                        .foregroundStyle(TextColors.secondary)
                }
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { assignment.isActive },
                set: { newValue in
                    Task {
                        await toggleAssignment(assignment, isActive: newValue, viewModel: viewModel, notificationManager: notificationManager)
                    }
                }
            ))
            .labelsHidden()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            assignmentToEdit = assignment
            showingEditSheet = true
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                assignmentToDelete = assignment
                showingDeleteAlert = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func toggleAssignment(
        _ assignment: ExerciseAssignment,
        isActive: Bool,
        viewModel: ScheduleViewModel,
        notificationManager: NotificationManager
    ) async {
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
            print("Error updating schedule: \(error)")
        }
    }

    private func deleteAssignment(
        _ assignment: ExerciseAssignment,
        viewModel: ScheduleViewModel,
        notificationManager: NotificationManager
    ) async {
        do {
            try await viewModel.deleteAssignment(assignment, context: modelContext, notificationManager: notificationManager)
            assignmentToDelete = nil
            HapticFeedback.success()
        } catch {
            HapticFeedback.error()
            print("Error deleting schedule: \(error)")
        }
    }
}

#Preview {
    ExerciseScheduleView()
        .environment(\.scheduleViewModel, ScheduleViewModel())
        .environment(NotificationManager())
        .modelContainer(for: [ExerciseAssignment.self, Exposure.self, ActivityList.self], inMemory: true)
}
