import SwiftUI
import SwiftData

// MARK: - BARecurrence

enum BARecurrence: String, CaseIterable, Identifiable {
    case once    = "once"
    case daily   = "daily"
    case weekly  = "weekly"

    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .once:   return String(localized: "Does not repeat")
        case .daily:  return String(localized: "Every day")
        case .weekly: return String(localized: "Weekly")
        }
    }
}

// MARK: - SchedulePickerSheet

struct SchedulePickerSheet: View {
    let task: ActivationTask

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(NotificationManager.self) private var notificationManager

    @Query private var categories: [ActivationCategory]

    @State private var selectedDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var selectedTime: Date = {
        var c = DateComponents()
        c.hour = 9
        c.minute = 0
        return Calendar.current.date(from: c) ?? Date()
    }()
    @State private var recurrence: BARecurrence = .once
    @State private var selectedWeekdays: Set<Int> = []
    @State private var showingPermissionAlert: Bool = false

    private var category: ActivationCategory? {
        categories.first { $0.id == task.categoryId }
    }

    private var combinedDateTime: Date {
        let timeComponents = Calendar.current.dateComponents([.hour, .minute], from: selectedTime)
        var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: selectedDate)
        dateComponents.hour = timeComponents.hour
        dateComponents.minute = timeComponents.minute
        return Calendar.current.date(from: dateComponents) ?? selectedDate
    }

    private var canSave: Bool {
        recurrence != .weekly || !selectedWeekdays.isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    ActivityPill(task: task, category: category)
                        .padding(.top, Spacing.xxs)

                    dateTimeSection
                    recurrenceSection

                    if recurrence == .weekly {
                        weekdaySection
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .padding(.horizontal, Spacing.sm)
                .padding(.bottom, Spacing.xxl)
                .animation(AppAnimation.standard, value: recurrence)
            }
            .homeBackground()
            .navigationTitle(String(localized: "Schedule"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Cancel")) { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) { saveButton }
        }
        .alert(String(localized: "Notifications are off"), isPresented: $showingPermissionAlert) {
            Button(String(localized: "OK"), role: .cancel) { }
        } message: {
            Text(String(localized: "Allow notifications in Settings to receive reminders."))
        }
    }

    // MARK: - Sections

    private var dateTimeSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionLabel(text: String(localized: "Date & time"))

            VStack(spacing: 0) {
                DatePicker(
                    String(localized: "Date"),
                    selection: $selectedDate,
                    in: Calendar.current.startOfDay(for: Date())...,
                    displayedComponents: .date
                )
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xxs)

                Divider().padding(.leading, Spacing.sm)

                DatePicker(
                    String(localized: "Time"),
                    selection: $selectedTime,
                    displayedComponents: .hourAndMinute
                )
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xxs)
            }
            .cardStyle(cornerRadius: CornerRadius.md, padding: 0)
        }
    }

    private var recurrenceSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionLabel(text: String(localized: "Repeat"))

            VStack(spacing: 0) {
                ForEach(Array(BARecurrence.allCases.enumerated()), id: \.element.id) { index, option in
                    if index > 0 { Divider().padding(.leading, Spacing.sm) }
                    Button {
                        withAnimation(AppAnimation.standard) { recurrence = option }
                    } label: {
                        HStack {
                            Text(option.localizedName)
                                .appFont(.body)
                                .foregroundStyle(TextColors.primary)
                            Spacer()
                            if recurrence == option {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(AppColors.primary)
                            }
                        }
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.sm)
                    }
                    .buttonStyle(.plain)
                }
            }
            .cardStyle(cornerRadius: CornerRadius.md, padding: 0)
        }
    }

    private var weekdaySection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionLabel(text: String(localized: "Days of the week"))

            HStack(spacing: Spacing.xxs) {
                ForEach(weekdayItems, id: \.number) { item in
                    let isSelected = selectedWeekdays.contains(item.number)
                    Button {
                        withAnimation(AppAnimation.fast) {
                            if isSelected {
                                selectedWeekdays.remove(item.number)
                            } else {
                                selectedWeekdays.insert(item.number)
                            }
                        }
                    } label: {
                        Text(item.shortName)
                            .appFont(.smallMedium)
                            .foregroundStyle(isSelected ? .white : TextColors.primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(
                                RoundedRectangle(cornerRadius: CornerRadius.sm, style: .continuous)
                                    .fill(isSelected ? AppColors.primary : AppColors.cardBackground)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: CornerRadius.sm, style: .continuous)
                                    .strokeBorder(isSelected ? Color.clear : AppColors.gray200, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // ExerciseAssignment convention: 1=Sun, 2=Mon, 3=Tue, 4=Wed, 5=Thu, 6=Fri, 7=Sat
    private var weekdayItems: [(number: Int, shortName: String)] {
        [2, 3, 4, 5, 6, 7, 1].map { (number: $0, shortName: Self.shortWeekdaySymbol(for: $0)) }
    }

    private static func shortWeekdaySymbol(for weekday: Int) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = .current
        guard let sunday = calendar.date(from: DateComponents(year: 2024, month: 1, day: 7)),
              let date = calendar.date(byAdding: .day, value: weekday - 1, to: sunday) else {
            return ""
        }
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.setLocalizedDateFormatFromTemplate("EEE")
        return formatter.string(from: date)
    }

    private var saveButton: some View {
        Button {
            saveSchedule()
        } label: {
            Text(String(localized: "Save schedule"))
                .appFont(.buttonPrimary)
                .foregroundStyle(canSave ? .white : TextColors.tertiary)
                .frame(maxWidth: .infinity)
                .frame(height: TouchTarget.large)
                .background(Capsule().fill(canSave ? AppColors.black : AppColors.gray200))
        }
        .buttonStyle(.plain)
        .disabled(!canSave)
        .padding(.horizontal, Spacing.sm)
        .padding(.bottom, Spacing.sm)
        .background(.regularMaterial)
    }

    // MARK: - Save Logic
    //
    // Single source of truth per recurrence (no dual-write):
    //   • once          → one planned `ActivationSession` + a one-time reminder
    //   • daily / weekly → a recurring `ExerciseAssignment` (drives the shared schedule
    //                      and recurring reminders via `NotificationManager`)
    // All notifications go through `NotificationManager` so scheduling/cleanup stays consistent
    // with the rest of the app.

    private func saveSchedule() {
        Task { @MainActor in
            let fireDate = combinedDateTime
            let granted = await notificationManager.requestAuthorization()

            switch recurrence {
            case .once:
                let session = ActivationSession(
                    activityId: task.id,
                    status: .planned,
                    plannedFor: fireDate
                )
                modelContext.insert(session)
                persist()
                if granted {
                    await notificationManager.scheduleActivationReminder(
                        sessionId: session.id,
                        title: task.localizedTitle,
                        at: fireDate
                    )
                }

            case .daily, .weekly:
                let days = recurrence == .daily
                    ? [1, 2, 3, 4, 5, 6, 7]
                    : Array(selectedWeekdays).sorted()
                let assignment = ExerciseAssignment(
                    exerciseType: .behavioralActivation,
                    daysOfWeek: days,
                    time: selectedTime,
                    isActive: true,
                    activityId: task.id
                )
                modelContext.insert(assignment)
                persist()
                if granted {
                    try? await notificationManager.scheduleNotification(
                        for: assignment,
                        titleOverride: task.localizedTitle
                    )
                }
            }

            // The schedule is saved either way; only warn if reminders can't fire.
            if granted {
                dismiss()
            } else {
                showingPermissionAlert = true
            }
        }
    }

    private func persist() {
        do {
            try modelContext.save()
        } catch {
            print("Failed to save BA schedule: \(error)")
        }
    }
}
