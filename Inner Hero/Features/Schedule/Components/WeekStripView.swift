import SwiftUI

struct WeekStripView: View {
    @Binding var selectedDate: Date
    private let calendar: Calendar
    
    init(selectedDate: Binding<Date>, calendar: Calendar = .current) {
        self._selectedDate = selectedDate
        self.calendar = calendar
    }
    
    var body: some View {
        VStack(spacing: 12) {
            header
            daysRow
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Выбор дня недели")
    }
    
    private var header: some View {
        HStack(spacing: 12) {
            Button {
                shiftWeek(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.headline)
                    .foregroundStyle(TextColors.primary)
                    .touchTarget()
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Предыдущая неделя")
            
            VStack(spacing: 2) {
                Text(weekTitle)
                    .font(.headline)
                    .foregroundStyle(TextColors.primary)
                Text(monthTitle)
                    .font(.caption)
                    .foregroundStyle(TextColors.secondary)
            }
            .frame(maxWidth: .infinity)
            
            Button {
                shiftWeek(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.headline)
                    .foregroundStyle(TextColors.primary)
                    .touchTarget()
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Следующая неделя")
            
            Button {
                selectedDate = Date()
                HapticFeedback.selection()
            } label: {
                Text("Сегодня")
                    .font(.subheadline.weight(.semibold))
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .accessibilityLabel("Перейти к сегодняшнему дню")
        }
    }
    
    private var daysRow: some View {
        HStack(spacing: 8) {
            ForEach(weekDates, id: \.self) { date in
                dayCell(date)
            }
        }
    }
    
    private func dayCell(_ date: Date) -> some View {
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let isToday = calendar.isDateInToday(date)
        
        return Button {
            selectedDate = date
            HapticFeedback.selection()
        } label: {
            VStack(spacing: 6) {
                Text(weekdaySymbol(for: date))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isSelected ? .white : TextColors.secondary)
                
                Text(dayNumber(for: date))
                    .font(.body.monospacedDigit().weight(.semibold))
                    .foregroundStyle(isSelected ? .white : TextColors.primary)
                    .frame(minWidth: 28)
                
                Circle()
                    .fill(isToday ? Color.blue : Color.clear)
                    .frame(width: 5, height: 5)
                    .opacity(isSelected ? 0 : 1)
                    .accessibilityHidden(true)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        isSelected
                        ? LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
                        : LinearGradient(colors: [.clear], startPoint: .top, endPoint: .bottom)
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel(for: date, isSelected: isSelected))
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
    
    private func accessibilityLabel(for date: Date, isSelected: Bool) -> String {
        let dateString = date.formatted(date: .long, time: .omitted)
        return isSelected ? "\(dateString), выбрано" : dateString
    }
    
    private var weekDates: [Date] {
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: selectedDate) else {
            return [selectedDate]
        }
        
        return (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: interval.start)
        }
    }
    
    private var weekTitle: String {
        guard
            let start = weekDates.first,
            let end = weekDates.last
        else { return "" }
        
        let dayFormatter = Self.dayRangeFormatter
        let startDay = dayFormatter.string(from: start)
        let endDay = dayFormatter.string(from: end)
        return "\(startDay)–\(endDay)"
    }
    
    private var monthTitle: String {
        Self.monthYearFormatter.string(from: selectedDate)
    }
    
    private func shiftWeek(by value: Int) {
        guard let newDate = calendar.date(byAdding: .weekOfYear, value: value, to: selectedDate) else { return }
        selectedDate = newDate
        HapticFeedback.selection()
    }
    
    private func weekdaySymbol(for date: Date) -> String {
        var symbols = Self.weekdayFormatter.shortWeekdaySymbols ?? []
        // Make Monday-first if user calendar is Monday-first; else keep as-is.
        // DateFormatter symbols are always Sunday-first, so reorder when needed.
        if calendar.firstWeekday == 2, symbols.count == 7 {
            let mondayFirst = Array(symbols[1...]) + [symbols[0]]
            symbols = mondayFirst
        }
        
        let weekday = calendar.component(.weekday, from: date)
        // weekday: 1=Sun...7=Sat. Map to formatter symbols index.
        let index = calendar.firstWeekday == 2 ? (weekday == 1 ? 6 : weekday - 2) : weekday - 1
        guard symbols.indices.contains(index) else { return "" }
        return symbols[index].uppercased()
    }
    
    private func dayNumber(for date: Date) -> String {
        Self.dayNumberFormatter.string(from: date)
    }
    
    private static let weekdayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = .current
        return f
    }()
    
    private static let dayNumberFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = .current
        f.dateFormat = "d"
        return f
    }()
    
    private static let dayRangeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = .current
        f.dateFormat = "d"
        return f
    }()
    
    private static let monthYearFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = .current
        f.dateFormat = "LLLL yyyy"
        return f
    }()
}

#Preview {
    WeekStripView(selectedDate: .constant(Date()))
        .padding()
}


