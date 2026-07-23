import SwiftData
import SwiftUI

/// Adding or editing one schedule entry: exercise, time, and how it repeats.
///
/// There is no "Cancel". Editing an existing entry commits on the way out by
/// either exit (the parent's `onDismiss`), and a new entry is created only by
/// "Done" — swiping a half-filled new entry away leaves nothing behind, so there
/// is nothing to discard.
struct ScheduleItemEditor: View {
    @Bindable var viewModel: ScheduleViewModel

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.calendar) private var calendar

    @State private var showSaveError = false

    private var exerciseOptions: [ChoiceOption<ScheduledExercise>] {
        ScheduledExercise.allCases.map {
            ChoiceOption(value: $0, title: $0.title)
        }
    }

    private var recurrenceOptions: [ChoiceOption<ScheduleRecurrence>] {
        ScheduleRecurrence.allCases.map {
            ChoiceOption(value: $0, title: $0.title)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    exerciseBlock
                    timeBlock
                    recurrenceBlock
                    parameterBlock
                }
                .padding(.horizontal, Spacing.sm)
                .padding(.top, Spacing.md)
                .padding(.bottom, Spacing.xxl)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .formBackground()
            .navigationTitle(
                viewModel.isEditing
                    ? viewModel.draftExercise.title
                    : String(localized: "New")
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "Done")) { save() }
                        .fontWeight(.semibold)
                }
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
        // The graphical date picker and both wheels do not fit a medium detent,
        // and a scroll view sharing a sheet with a wheel at half height gives two
        // competing scrolls.
        .presentationDetents([.large])
    }

    // MARK: - Blocks

    private var exerciseBlock: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            SectionLabel(text: String(localized: "Exercise"))
            // Cards, not segments: four sentence-length names collapse in one row
            // at the first Dynamic Type step.
            SegmentedChoice(
                options: exerciseOptions,
                selection: Binding(
                    get: { viewModel.draftExercise },
                    set: { viewModel.draftExercise = $0 ?? viewModel.draftExercise }
                )
            )
        }
    }

    private var timeBlock: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            SectionLabel(text: String(localized: "Time"))
            DatePicker(
                "",
                selection: $viewModel.draftTime,
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .frame(maxWidth: .infinity)
        }
    }

    private var recurrenceBlock: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            SectionLabel(text: String(localized: "Repeat"))
            SegmentedChoice(
                options: recurrenceOptions,
                selection: Binding(
                    get: { viewModel.draftRecurrence },
                    set: { viewModel.draftRecurrence = $0 ?? viewModel.draftRecurrence }
                ),
                style: .segments
            )
        }
    }

    @ViewBuilder
    private var parameterBlock: some View {
        switch viewModel.draftRecurrence {
        case .once:
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                SectionLabel(text: String(localized: "Date"))
                DatePicker(
                    "",
                    selection: $viewModel.draftOnceDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .labelsHidden()
            }

        case .weekly:
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                // Not "Days": that key belongs to the recurrence segment, and in
                // Russian the two need different words («По дням» / «Дни недели»).
                SectionLabel(text: String(localized: "Days of the week"))
                ChipFlowLayout {
                    ForEach(ScheduleViewModel.weekdayOrder(calendar: calendar), id: \.self) { weekday in
                        SelectableChip(
                            text: ScheduleViewModel.shortWeekdaySymbol(weekday, calendar: calendar),
                            isSelected: Binding(
                                get: { viewModel.draftWeekdays.contains(weekday) },
                                // The chip toggles itself; the view model owns the
                                // rule that the last day cannot be removed.
                                set: { _ in viewModel.toggleWeekday(weekday) }
                            )
                        )
                    }
                }
            }

        case .monthly:
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                SectionLabel(text: String(localized: "Day of the month"))
                Picker("", selection: $viewModel.draftMonthDay) {
                    ForEach(1...31, id: \.self) { day in
                        Text("\(day)").tag(day)
                    }
                }
                .pickerStyle(.wheel)
                .labelsHidden()
                .frame(maxWidth: .infinity)

                // Describes the behaviour, does not warn about it: a month without
                // the 31st simply does not fire, in the list and in the
                // notification alike (plan decision 7).
                if viewModel.draftMonthDay > 28 {
                    Text(String(localized: "In months without this day, no reminder arrives."))
                        .appFont(.small)
                        .foregroundStyle(TextColors.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    // MARK: - Actions

    private func save() {
        do {
            try viewModel.save(in: modelContext, calendar: calendar)
            HapticFeedback.success()
            dismiss()
        } catch {
            HapticFeedback.error()
            showSaveError = true
        }
    }
}

#Preview {
    ScheduleItemEditor(viewModel: ScheduleViewModel())
        .modelContainer(for: [ScheduleItem.self], inMemory: true)
}
