import SwiftUI

struct DayOfWeekSelector: View {
    @Binding var selectedDays: [Int]

    private let dayNumbers = [1, 2, 3, 4, 5, 6, 7]

    private var dayLabels: [String] {
        let formatter = DateFormatter()
        formatter.locale = .current
        return formatter.shortWeekdaySymbols
    }

    var body: some View {
        VStack(spacing: Spacing.xs) {
            quickOptionsRow
            individualDaysRow
        }
    }

    // MARK: - Quick Options

    private var quickOptionsRow: some View {
        HStack(spacing: Spacing.xxs) {
            quickOptionButton(
                title: String(localized: "All days"),
                isSelected: selectedDays.sorted() == [1, 2, 3, 4, 5, 6, 7]
            ) {
                selectedDays = selectedDays.sorted() == [1, 2, 3, 4, 5, 6, 7] ? [] : [1, 2, 3, 4, 5, 6, 7]
                HapticFeedback.selection()
            }

            quickOptionButton(
                title: String(localized: "Weekdays"),
                isSelected: selectedDays.sorted() == [2, 3, 4, 5, 6]
            ) {
                selectedDays = selectedDays.sorted() == [2, 3, 4, 5, 6] ? [] : [2, 3, 4, 5, 6]
                HapticFeedback.selection()
            }

            quickOptionButton(
                title: String(localized: "Weekends"),
                isSelected: selectedDays.sorted() == [1, 7]
            ) {
                selectedDays = selectedDays.sorted() == [1, 7] ? [] : [1, 7]
                HapticFeedback.selection()
            }
        }
    }

    private func quickOptionButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .appFont(.smallMedium)
                .foregroundStyle(isSelected ? .white : TextColors.primary)
                .padding(.horizontal, Spacing.xs)
                .padding(.vertical, Spacing.xxs)
                .background(
                    Capsule()
                        .fill(isSelected ? AppColors.primary : AppColors.gray100)
                )
        }
        .buttonStyle(.plain)
        .animation(AppAnimation.fast, value: isSelected)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    // MARK: - Individual Days

    private var individualDaysRow: some View {
        HStack(spacing: Spacing.xxs) {
            ForEach(Array(dayNumbers.enumerated()), id: \.element) { index, day in
                dayButton(day: day, label: dayLabels[index])
            }
        }
    }

    private func dayButton(day: Int, label: String) -> some View {
        let isSelected = selectedDays.contains(day)

        return Button {
            toggleDay(day)
            HapticFeedback.selection()
        } label: {
            Text(String(label.prefix(1)))
                .appFont(.smallMedium)
                .foregroundStyle(isSelected ? .white : TextColors.primary)
                .frame(maxWidth: .infinity)
                .frame(height: TouchTarget.minimum)
                .background(
                    Circle()
                        .fill(isSelected ? AppColors.primary : AppColors.gray100)
                )
        }
        .buttonStyle(.plain)
        .animation(AppAnimation.fast, value: isSelected)
        .accessibilityLabel(label)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private func toggleDay(_ day: Int) {
        if selectedDays.contains(day) {
            selectedDays.removeAll { $0 == day }
        } else {
            selectedDays.append(day)
            selectedDays.sort()
        }
    }
}

#Preview {
    @Previewable @State var selectedDays: [Int] = [2, 3, 4, 5, 6]

    VStack {
        DayOfWeekSelector(selectedDays: $selectedDays)
            .padding()
    }
}
