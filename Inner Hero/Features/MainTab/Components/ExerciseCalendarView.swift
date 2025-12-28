import SwiftUI
import SwiftData

struct ExerciseCalendarView: View {
    @Query(sort: \ExerciseAssignment.time) private var allAssignments: [ExerciseAssignment]
    
    @State private var selectedDate = Date()
    @State private var currentMonth = Date()
    
    private var activeAssignments: [ExerciseAssignment] {
        allAssignments.filter { $0.isActive }
    }
    
    private var datesWithExercises: [String: [ExerciseType]] {
        let calendar = Calendar.current
        var dates: [String: [ExerciseType]] = [:]
        
        for assignment in activeAssignments {
            // Generate dates for current month and next month
            let startOfMonth = calendar.dateInterval(of: .month, for: currentMonth)?.start ?? currentMonth
            let endOfMonth = calendar.date(byAdding: .month, value: 2, to: startOfMonth) ?? currentMonth
            
            var currentDate = startOfMonth
            while currentDate <= endOfMonth {
                let weekday = calendar.component(.weekday, from: currentDate)
                
                if assignment.daysOfWeek.contains(weekday) {
                    let dateKey = dateKeyString(from: currentDate)
                    
                    if dates[dateKey] == nil {
                        dates[dateKey] = []
                    }
                    if !dates[dateKey]!.contains(assignment.exerciseType) {
                        dates[dateKey]?.append(assignment.exerciseType)
                    }
                }
                
                if let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) {
                    currentDate = nextDate
                } else {
                    break
                }
            }
        }
        
        return dates
    }
    
    private func dateKeyString(from date: Date) -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return "\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)"
    }
    
    private func getExerciseTypes(for dateComponents: DateComponents) -> [ExerciseType] {
        let dateKey = "\(dateComponents.year ?? 0)-\(dateComponents.month ?? 0)-\(dateComponents.day ?? 0)"
        return datesWithExercises[dateKey] ?? []
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "calendar")
                    .font(.body)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Text("Календарь упражнений")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(TextColors.primary)
                
                Spacer()
                
                HStack(spacing: 8) {
                    Button {
                        withAnimation {
                            currentMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(TextColors.primary)
                    }
                    
                    Text(monthYearString(from: currentMonth))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(TextColors.primary)
                        .frame(minWidth: 120)
                    
                    Button {
                        withAnimation {
                            currentMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(TextColors.primary)
                    }
                }
            }
            
            calendarGrid
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
    }
    
    private var calendarGrid: some View {
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: currentMonth)?.start ?? currentMonth
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        let daysInMonth = calendar.range(of: .day, in: .month, for: currentMonth)?.count ?? 30
        let daysToAdd = (firstWeekday - 1) % 7
        
        return VStack(spacing: 8) {
            // Weekday headers
            HStack(spacing: 0) {
                ForEach(["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"], id: \.self) { day in
                    Text(day)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(TextColors.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Calendar days
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                // Empty cells for days before month starts
                ForEach(0..<daysToAdd, id: \.self) { _ in
                    Color.clear
                        .frame(height: 40)
                }
                
                // Days of the month
                ForEach(1...daysInMonth, id: \.self) { day in
                    let dateComponents = DateComponents(
                        year: calendar.component(.year, from: currentMonth),
                        month: calendar.component(.month, from: currentMonth),
                        day: day
                    )
                    
                    if let date = calendar.date(from: dateComponents) {
                        CalendarDayView(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            exerciseTypes: getExerciseTypes(for: dateComponents),
                            onTap: {
                                selectedDate = date
                            }
                        )
                    }
                }
            }
        }
    }
    
    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: date).capitalized
    }
}

// MARK: - Calendar Day View

struct CalendarDayView: View {
    let date: Date
    let isSelected: Bool
    let exerciseTypes: [ExerciseType]
    let onTap: () -> Void
    
    private var dayNumber: Int {
        Calendar.current.component(.day, from: date)
    }
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .cyan],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 36, height: 36)
                    } else if isToday {
                        Circle()
                            .strokeBorder(Color.blue.opacity(0.5), lineWidth: 2)
                            .frame(width: 36, height: 36)
                    }
                    
                    Text("\(dayNumber)")
                        .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                        .foregroundStyle(isSelected ? .white : (isToday ? .blue : TextColors.primary))
                }
                
                // Exercise type indicators as underlines
                if !exerciseTypes.isEmpty {
                    HStack(spacing: 2) {
                        ForEach(Array(Set(exerciseTypes)).prefix(3), id: \.self) { exerciseType in
                            RoundedRectangle(cornerRadius: 1)
                                .fill(colorForExerciseType(exerciseType))
                                .frame(height: 3)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .frame(width: 32)
                } else {
                    // Empty space to maintain consistent height
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color.clear)
                        .frame(height: 3)
                        .frame(width: 32)
                }
            }
        }
        .frame(height: 50)
        .buttonStyle(.plain)
    }
    
    private func colorForExerciseType(_ type: ExerciseType) -> Color {
        switch type {
        case .exposure:
            return .blue
        case .breathing:
            return .teal
        case .relaxation:
            return .mint
        case .behavioralActivation:
            return .green
        }
    }
}

