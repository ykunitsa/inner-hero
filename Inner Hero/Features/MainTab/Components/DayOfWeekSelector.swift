import SwiftUI

struct DayOfWeekSelector: View {
    @Binding var selectedDays: [Int]
    
    private let dayNumbers = [1, 2, 3, 4, 5, 6, 7] // Sunday = 1, Monday = 2, etc.
    
    private var dayLabels: [String] {
        let formatter = DateFormatter()
        formatter.locale = .current
        return formatter.shortWeekdaySymbols
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Quick options
            quickOptionsSection
            
            // Individual day buttons
            HStack(spacing: 12) {
                ForEach(Array(dayNumbers.enumerated()), id: \.element) { index, day in
                    dayButton(day: day, label: dayLabels[index])
                }
            }
        }
    }
    
    private var quickOptionsSection: some View {
        HStack(spacing: 12) {
            quickOptionButton(
                title: String(localized: "Все дни"),
                isSelected: selectedDays.sorted() == [1, 2, 3, 4, 5, 6, 7]
            ) {
                if selectedDays.sorted() == [1, 2, 3, 4, 5, 6, 7] {
                    selectedDays = []
                } else {
                    selectedDays = [1, 2, 3, 4, 5, 6, 7]
                }
                HapticFeedback.selection()
            }
            
            quickOptionButton(
                title: String(localized: "Будни"),
                isSelected: selectedDays.sorted() == [2, 3, 4, 5, 6]
            ) {
                if selectedDays.sorted() == [2, 3, 4, 5, 6] {
                    selectedDays = []
                } else {
                    selectedDays = [2, 3, 4, 5, 6]
                }
                HapticFeedback.selection()
            }
            
            quickOptionButton(
                title: String(localized: "Выходные"),
                isSelected: selectedDays.sorted() == [1, 7]
            ) {
                if selectedDays.sorted() == [1, 7] {
                    selectedDays = []
                } else {
                    selectedDays = [1, 7]
                }
                HapticFeedback.selection()
            }
        }
    }
    
    private func quickOptionButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(isSelected ? .white : TextColors.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.blue : Color(.systemGray5))
                )
        }
        .buttonStyle(.plain)
    }
    
    private func dayButton(day: Int, label: String) -> some View {
        Button {
            toggleDay(day)
            HapticFeedback.selection()
        } label: {
            Text(label)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(selectedDays.contains(day) ? .white : TextColors.primary)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(selectedDays.contains(day) ? Color.blue : Color(.systemGray5))
                )
        }
        .buttonStyle(.plain)
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
    
    return VStack {
        DayOfWeekSelector(selectedDays: $selectedDays)
            .padding()
    }
}


