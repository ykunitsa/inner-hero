import SwiftUI
import SwiftData

// MARK: - ExerciseScheduleSection

struct ExerciseScheduleSection: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scheduleViewModel) private var scheduleViewModel
    @Environment(NotificationManager.self) private var notificationManager

    let assignments: [ExerciseAssignment]
    let exerciseType: ExerciseType
    let exposureId: UUID?
    let groundingType: GroundingType?
    let breathingPatternType: BreathingPatternType?
    let relaxationType: RelaxationType?
    let activityListId: UUID?

    @State private var showScheduleSheet = false
    @State private var assignmentToEdit: ExerciseAssignment?
    @State private var assignmentToDelete: ExerciseAssignment?
    @State private var showDeleteAlert = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            SectionLabel(text: String(localized: "Schedule"))

            if let viewModel = scheduleViewModel {
                scheduleContent(viewModel: viewModel)
            } else {
                scheduleFallback
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
        .sheet(isPresented: $showScheduleSheet) {
            if let viewModel = scheduleViewModel {
                ScheduleExerciseView(
                    assignment: assignmentToEdit,
                    viewModel: viewModel,
                    notificationManager: notificationManager,
                    preSelectedExposureId: exposureId,
                    preSelectedBreathingPattern: breathingPatternType,
                    preSelectedRelaxationType: relaxationType,
                    preSelectedGroundingType: groundingType,
                    preSelectedActivityListId: activityListId
                )
            }
        }
        .alert(String(localized: "Delete schedule?"),
               isPresented: $showDeleteAlert,
               presenting: assignmentToDelete) { assignment in
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let viewModel = scheduleViewModel {
                    Task {
                        await deleteSchedule(assignment, viewModel: viewModel, notificationManager: notificationManager)
                    }
                }
            }
        } message: { _ in
            Text(String(localized: "Are you sure you want to delete this schedule?"))
        }
    }

    // MARK: - Content (with ViewModel)

    private func scheduleContent(viewModel: ScheduleViewModel) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            if assignments.isEmpty {
                createButton
            } else {
                assignmentsList(viewModel: viewModel)
                addAnotherButton
            }
        }
    }

    // MARK: - Fallback (read-only)

    private var scheduleFallback: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            if assignments.isEmpty {
                createButton
            } else {
                assignmentsListReadOnly
                addAnotherButton
            }
        }
    }

    // MARK: - Assignments List

    private func assignmentsList(viewModel: ScheduleViewModel) -> some View {
        let sorted = assignments.sorted {
            $0.time != $1.time ? $0.time < $1.time : $0.createdAt < $1.createdAt
        }
        return VStack(alignment: .leading, spacing: Spacing.xs) {
            ForEach(Array(sorted.enumerated()), id: \.element.id) { index, assignment in
                if index > 0 { Divider() }
                scheduleRow(assignment: assignment, viewModel: viewModel)
            }
        }
    }

    private var assignmentsListReadOnly: some View {
        let sorted = assignments.sorted {
            $0.time != $1.time ? $0.time < $1.time : $0.createdAt < $1.createdAt
        }
        return VStack(alignment: .leading, spacing: Spacing.xs) {
            ForEach(Array(sorted.enumerated()), id: \.element.id) { index, assignment in
                if index > 0 { Divider() }
                scheduleRowReadOnly(assignment: assignment)
            }
        }
    }

    // MARK: - Schedule Row (editable)

    private func scheduleRow(
        assignment: ExerciseAssignment,
        viewModel: ScheduleViewModel
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: Spacing.xxxs) {
                    HStack(spacing: Spacing.xxs) {
                        Image(systemName: "clock")
                            .font(.system(size: 11))
                            .foregroundStyle(TextColors.secondary)
                        Text(ScheduleViewModel.timeFormatter.string(from: assignment.time))
                            .appFont(.bodyMedium)
                            .foregroundStyle(TextColors.primary)
                    }
                    HStack(spacing: Spacing.xxs) {
                        Image(systemName: "calendar")
                            .font(.system(size: 11))
                            .foregroundStyle(TextColors.secondary)
                        Text(assignment.getDayNamesString())
                            .appFont(.body)
                            .foregroundStyle(TextColors.secondary)
                    }
                }

                Spacer()

                Toggle("", isOn: Binding(
                    get: { assignment.isActive },
                    set: { newValue in
                        Task {
                            await toggleSchedule(
                                assignment,
                                isActive: newValue,
                                viewModel: viewModel,
                                notificationManager: notificationManager
                            )
                        }
                    }
                ))
                .labelsHidden()
                .tint(AppColors.primary)
            }

            HStack(spacing: Spacing.xxs) {
                Button {
                    assignmentToEdit = assignment
                    showScheduleSheet = true
                } label: {
                    Label(String(localized: "Edit"), systemImage: "pencil")
                        .appFont(.smallMedium)
                        .foregroundStyle(AppColors.primary)
                        .padding(.horizontal, Spacing.xs)
                        .padding(.vertical, Spacing.xxxs + 2)
                        .background(Capsule().fill(AppColors.primary.opacity(Opacity.subtleBackground)))
                }
                .buttonStyle(.plain)

                Button {
                    assignmentToDelete = assignment
                    showDeleteAlert = true
                } label: {
                    Label(String(localized: "Delete"), systemImage: "trash")
                        .appFont(.smallMedium)
                        .foregroundStyle(AppColors.State.error)
                        .padding(.horizontal, Spacing.xs)
                        .padding(.vertical, Spacing.xxxs + 2)
                        .background(Capsule().fill(AppColors.State.error.opacity(Opacity.subtleBackground)))
                }
                .buttonStyle(.plain)
            }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    // MARK: - Schedule Row (read-only)

    private func scheduleRowReadOnly(assignment: ExerciseAssignment) -> some View {
        HStack(spacing: Spacing.xxs) {
            Image(systemName: "clock")
                .font(.system(size: 11))
                .foregroundStyle(TextColors.secondary)
            Text(ScheduleViewModel.timeFormatter.string(from: assignment.time))
                .appFont(.bodyMedium)
                .foregroundStyle(TextColors.primary)
            Text("·")
                .appFont(.body)
                .foregroundStyle(TextColors.tertiary)
            Text(assignment.getDayNamesString())
                .appFont(.small)
                .foregroundStyle(TextColors.secondary)
        }
    }

    // MARK: - Buttons

    private var createButton: some View {
        PrimaryButton(
            title: String(localized: "Create schedule"),
            color: AppColors.State.warning
        ) {
            assignmentToEdit = nil
            showScheduleSheet = true
        }
    }

    private var addAnotherButton: some View {
        Button {
            assignmentToEdit = nil
            showScheduleSheet = true
        } label: {
            HStack(spacing: Spacing.xxs) {
                Image(systemName: "plus.circle")
                    .font(.system(size: IconSize.glyph - 2))
                Text(String(localized: "Add schedule"))
                    .appFont(.bodyMedium)
            }
            .foregroundStyle(AppColors.State.warning)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                    .fill(AppColors.State.warning.opacity(Opacity.subtleBackground))
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(String(localized: "Add schedule"))
    }

    // MARK: - Actions

    private func toggleSchedule(
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
        }
    }

    private func deleteSchedule(
        _ assignment: ExerciseAssignment,
        viewModel: ScheduleViewModel,
        notificationManager: NotificationManager
    ) async {
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
    }
}
