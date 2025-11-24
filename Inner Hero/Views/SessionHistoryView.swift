//
//  SessionHistoryView.swift
//  Inner Hero
//
//  Created by AI Assistant on 25.10.25.
//

import SwiftUI
import SwiftData

struct SessionHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    let exposure: Exposure
    
    @State private var sessions: [SessionResult] = []
    @State private var errorMessage: String?
    @State private var showingError = false
    
    var body: some View {
        Group {
            if sessions.isEmpty {
                // HIG: ContentUnavailableView для empty state с семантическими иконками
                ContentUnavailableView(
                    "Нет сеансов",
                    systemImage: "clock.badge.xmark",
                    description: Text("История сеансов для этой экспозиции пуста")
                        .font(.body) // HIG: Dynamic Type для описаний
                )
            } else {
                // HIG: List для навигационного контента с встроенными actions
                List {
                    ForEach(sessions) { session in
                        NavigationLink(destination: SessionDetailView(session: session)) {
                            SessionRow(session: session)
                        }
                        // HIG: List автоматически обеспечивает минимальную высоту 44pt
                    }
                }
                // HIG: List автоматически использует системные цвета и адаптируется к Dark Mode
                .listStyle(.plain)
            }
        }
        .navigationTitle("История сеансов")
        .navigationBarTitleDisplayMode(.inline) // HIG: inline для detail screens
        .onAppear {
            loadSessions()
        }
        .alert("Ошибка", isPresented: $showingError) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.body) // HIG: Dynamic Type в алертах
            }
        }
    }
    
    private func loadSessions() {
        let dataManager = DataManager(modelContext: modelContext)
        // HIG: Error handling с пользовательскими сообщениями
        do {
            sessions = try dataManager.fetchSessionResults(for: exposure)
        } catch {
            errorMessage = "Не удалось загрузить сеансы: \(error.localizedDescription)"
            showingError = true
        }
    }
}

struct SessionRow: View {
    let session: SessionResult
    
    // HIG: Spacing constants кратные 4pt
    private enum Layout {
        static let rowSpacing: CGFloat = 12 // между элементами строки
        static let contentSpacing: CGFloat = 8 // внутри контента
        static let verticalPadding: CGFloat = 8 // вертикальные отступы
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: session.startAt)
    }
    
    private var duration: String? {
        guard let endAt = session.endAt else { return nil }
        let interval = endAt.timeIntervalSince(session.startAt)
        let minutes = Int(interval / 60)
        return "\(minutes) мин"
    }
    
    private func anxietyColor(for level: Int, comparing comparison: Int) -> Color {
        // HIG: Semantic colors для anxiety levels
        if level < comparison {
            return .green // Success state
        } else if level > comparison {
            return .red // Error/Critical state
        } else {
            return .orange // Warning state
        }
    }
    
    var body: some View {
        // HIG: VStack с spacing кратным 4pt для вертикальной иерархии
        VStack(alignment: .leading, spacing: Layout.rowSpacing) {
            // Дата и длительность
            HStack {
                Label(formattedDate, systemImage: "calendar")
                    .font(.body.weight(.semibold)) // HIG: .headline замена — semibold body
                    .foregroundStyle(.primary) // HIG: Semantic color для основного текста
                    .accessibilityLabel("Дата сеанса: \(formattedDate)") // HIG: VoiceOver
                
                Spacer()
                
                if let duration = duration {
                    Text(duration)
                        .font(.caption) // HIG: caption для metadata
                        .foregroundStyle(.secondary) // HIG: secondary для вспомогательного текста
                        .accessibilityLabel("Длительность: \(duration)") // HIG: VoiceOver
                }
            }
            
            // Уровни тревожности
            HStack(spacing: 16) { // HIG: spacing кратный 4pt
                // Уровень до
                VStack(alignment: .leading, spacing: Layout.contentSpacing) {
                    Text("Уровень до")
                        .font(.caption) // HIG: caption для labels
                        .foregroundStyle(.secondary)
                    Text("\(session.anxietyBefore)")
                        .font(.title3.weight(.semibold)) // HIG: title3 для числовых значений
                        .foregroundStyle(.blue) // HIG: blue для default state
                        .monospacedDigit() // HIG: предотвращает jumping при изменении
                }
                .accessibilityElement(children: .combine) // HIG: объединить для VoiceOver
                .accessibilityLabel("Тревога до сеанса: \(session.anxietyBefore)")
                
                Spacer()
                
                // Уровень после
                if let anxietyAfter = session.anxietyAfter {
                    VStack(alignment: .trailing, spacing: Layout.contentSpacing) {
                        Text("Уровень после")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(anxietyAfter)")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(
                                anxietyColor(for: anxietyAfter, comparing: session.anxietyBefore)
                            ) // HIG: semantic color для изменений
                            .monospacedDigit()
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Тревога после сеанса: \(anxietyAfter)")
                    .accessibilityHint(
                        anxietyAfter < session.anxietyBefore 
                            ? "Уровень снизился" 
                            : "Уровень повысился"
                    ) // HIG: hint для контекста
                }
            }
            
            // Заметки
            if !session.notes.isEmpty {
                Text(session.notes)
                    .font(.subheadline) // HIG: subheadline для supporting text
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .accessibilityLabel("Заметки: \(session.notes)") // HIG: VoiceOver
            }
        }
        // HIG: вертикальные отступы кратные 4pt
        .padding(.vertical, Layout.verticalPadding)
        // HIG: List row автоматически имеет минимальную высоту 44pt
    }
}

struct SessionDetailView: View {
    let session: SessionResult
    
    // HIG: Spacing constants кратные 4pt для консистентности
    private enum Layout {
        static let screenHorizontalPadding: CGFloat = 20 // стандартный horizontal padding
        static let screenVerticalPadding: CGFloat = 24 // стандартный vertical padding
        static let sectionSpacing: CGFloat = 32 // между секциями
        static let contentSpacing: CGFloat = 12 // внутри секций
        static let tightSpacing: CGFloat = 8 // tight spacing
        static let cardPadding: CGFloat = 20 // padding внутри карточек
        static let cardCornerRadius: CGFloat = 16 // HIG: lg corner radius
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: session.startAt)
    }
    
    private var duration: String {
        guard let endAt = session.endAt else { return "Не завершён" }
        let interval = endAt.timeIntervalSince(session.startAt)
        let minutes = Int(interval / 60)
        let seconds = Int(interval.truncatingRemainder(dividingBy: 60))
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private var anxietyChange: Int? {
        guard let anxietyAfter = session.anxietyAfter else { return nil }
        return session.anxietyBefore - anxietyAfter
    }
    
    var body: some View {
        ScrollView {
            // HIG: VStack с section spacing для визуальной иерархии
            VStack(alignment: .leading, spacing: Layout.sectionSpacing) {
                // Дата и время
                VStack(alignment: .leading, spacing: Layout.tightSpacing) {
                    Text("Дата сеанса")
                        .font(.caption.weight(.medium)) // HIG: caption для labels
                        .foregroundStyle(.secondary)
                        .textCase(nil) // HIG: избегаем uppercase для русского
                    Label(formattedDate, systemImage: "calendar")
                        .font(.body.weight(.semibold)) // HIG: body вместо headline
                        .foregroundStyle(.primary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Дата сеанса: \(formattedDate)")
                
                // График изменения тревожности
                if let anxietyAfter = session.anxietyAfter {
                    AnxietyProgressChart(
                        anxietyBefore: session.anxietyBefore,
                        anxietyAfter: anxietyAfter
                    )
                }
                
                // Статистика
                VStack(spacing: Layout.contentSpacing) {
                    // Карточки со статистикой
                    HStack(spacing: Layout.contentSpacing) { // HIG: spacing кратный 4pt
                        StatCard(
                            title: "Тревога до",
                            value: "\(session.anxietyBefore)",
                            color: .blue
                        )
                        
                        if let anxietyAfter = session.anxietyAfter {
                            StatCard(
                                title: "Тревога после",
                                value: "\(anxietyAfter)",
                                color: anxietyAfter < session.anxietyBefore ? .green : .red
                            )
                            
                            if let change = anxietyChange {
                                StatCard(
                                    title: "Изменение",
                                    value: "\(change > 0 ? "-" : "+")\(abs(change))",
                                    color: change > 0 ? .green : (change < 0 ? .red : .gray)
                                )
                            }
                        }
                    }
                    
                    // Карточка длительности
                    HStack {
                        VStack(alignment: .leading, spacing: Layout.tightSpacing) {
                            Text("Длительность")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.secondary)
                            Text(duration)
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(.primary) // HIG: primary для основного текста
                                .monospacedDigit() // HIG: для таймеров
                        }
                        
                        Spacer()
                        
                        if session.endAt != nil {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.green)
                                .accessibilityLabel("Завершён") // HIG: VoiceOver для иконки
                        } else {
                            Image(systemName: "ellipsis.circle")
                                .font(.title2)
                                .foregroundStyle(.gray)
                                .accessibilityLabel("В процессе") // HIG: VoiceOver для иконки
                        }
                    }
                    .padding(Layout.cardPadding) // HIG: стандартный card padding
                    .background(
                        // HIG: semantic background для карточек
                        RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous)
                            .fill(.background.tertiary)
                    )
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Длительность: \(duration), " + 
                        (session.endAt != nil ? "Завершён" : "В процессе"))
                }
                
                // Заметки
                if !session.notes.isEmpty {
                    VStack(alignment: .leading, spacing: Layout.contentSpacing) {
                        Text("Заметки")
                            .font(.title3.weight(.semibold)) // HIG: title3 для subsection headers
                            .foregroundStyle(.primary)
                        
                        Text(session.notes)
                            .font(.body) // HIG: body для основного текста
                            .foregroundStyle(.primary)
                            .padding(Layout.cardPadding)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous)
                                    .fill(.background.tertiary)
                            )
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Заметки: \(session.notes)")
                }
                
                // Информация об экспозиции
                if let exposure = session.exposure {
                    VStack(alignment: .leading, spacing: Layout.contentSpacing) {
                        Text("Экспозиция")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.primary)
                        
                        VStack(alignment: .leading, spacing: Layout.tightSpacing) {
                            Text(exposure.title)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.primary)
                            
                            Text(exposure.exposureDescription)
                                .font(.subheadline) // HIG: subheadline для supporting text
                                .foregroundStyle(.secondary)
                        }
                        .padding(Layout.cardPadding)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous)
                                .fill(.background.tertiary)
                        )
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Экспозиция: \(exposure.title). \(exposure.exposureDescription)")
                }
            }
            .padding(.horizontal, Layout.screenHorizontalPadding) // HIG: screen edges padding
            .padding(.vertical, Layout.screenVerticalPadding)
        }
        // HIG: системный background для grouped content
        .background(.background.secondary)
        .ignoresSafeArea(.all)
        .navigationTitle("Детали сеанса")
        .navigationBarTitleDisplayMode(.inline) // HIG: inline для detail screens
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    
    // HIG: Spacing constants
    private enum Layout {
        static let cardSpacing: CGFloat = 8
        static let cardPadding: CGFloat = 16 // немного меньше для компактных карточек
        static let cornerRadius: CGFloat = 12
    }
    
    var body: some View {
        VStack(spacing: Layout.cardSpacing) { // HIG: spacing кратный 4pt
            Text(title)
                .font(.caption.weight(.medium)) // HIG: medium weight для labels
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2.weight(.bold)) // HIG: bold для числовых значений
                .foregroundStyle(color) // HIG: semantic colors
                .monospacedDigit() // HIG: предотвращает jumping
        }
        .frame(maxWidth: .infinity)
        // HIG: минимальная высота для touch target, хотя карточка не интерактивная
        .frame(minHeight: 44)
        .padding(Layout.cardPadding)
        .background(
            // HIG: .continuous style для modern look
            RoundedRectangle(cornerRadius: Layout.cornerRadius, style: .continuous)
                .fill(.background.tertiary) // HIG: semantic background
        )
        .accessibilityElement(children: .combine) // HIG: объединить для VoiceOver
        .accessibilityLabel("\(title): \(value)") // HIG: читаемый label
    }
}

// MARK: - Anxiety Progress Chart

struct AnxietyProgressChart: View {
    let anxietyBefore: Int
    let anxietyAfter: Int
    
    // HIG: Reduce Motion support
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    // HIG: Layout constants кратные 4pt
    private enum Layout {
        static let headerSpacing: CGFloat = 12
        static let contentSpacing: CGFloat = 16
        static let barSpacing: CGFloat = 80 // расстояние между барами
        static let barWidth: CGFloat = 50
        static let chartHeight: CGFloat = 200
        static let cardPadding: CGFloat = 20
        static let cornerRadius: CGFloat = 12
        static let labelSpacing: CGFloat = 4
        static let barCornerRadius: CGFloat = 8
    }
    
    private var maxValue: CGFloat { 10 }
    
    private var beforeHeight: CGFloat {
        CGFloat(anxietyBefore) / maxValue
    }
    
    private var afterHeight: CGFloat {
        CGFloat(anxietyAfter) / maxValue
    }
    
    // HIG: Semantic colors для состояний
    private var changeColor: Color {
        if anxietyAfter < anxietyBefore {
            return .green // Success state
        } else if anxietyAfter > anxietyBefore {
            return .red // Error/Critical state
        } else {
            return .orange // Warning state
        }
    }
    
    private var changeIcon: String {
        if anxietyAfter < anxietyBefore {
            return "arrow.down"
        } else if anxietyAfter > anxietyBefore {
            return "arrow.up"
        } else {
            return "minus"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Layout.headerSpacing) {
            // Заголовок
            Label("Динамика тревожности", systemImage: "chart.line.uptrend.xyaxis")
                .font(.title3.weight(.semibold)) // HIG: title3 для subsection headers
                .foregroundStyle(.primary)
                .accessibilityAddTraits(.isHeader) // HIG: пометить как заголовок
            
            VStack(spacing: Layout.contentSpacing) {
                // График
                GeometryReader { geometry in
                    let chartHeight = geometry.size.height
                    
                    ZStack(alignment: .bottom) {
                        // Фоновая сетка
                        VStack(spacing: 0) {
                            ForEach(0..<11) { i in
                                Divider()
                                    .background(.separator) // HIG: semantic separator
                                if i < 10 {
                                    Spacer()
                                }
                            }
                        }
                        .accessibilityHidden(true) // HIG: декоративный элемент
                        
                        HStack(alignment: .bottom, spacing: Layout.barSpacing) {
                            // Бар "До"
                            BarView(
                                value: anxietyBefore,
                                height: chartHeight * beforeHeight,
                                maxHeight: chartHeight,
                                color: .blue,
                                label: "До"
                            )
                            
                            // Стрелка изменения
                            VStack {
                                Image(systemName: changeIcon)
                                    .font(.title)
                                    .foregroundStyle(changeColor)
                                    .padding(.bottom, chartHeight * 0.4)
                                    .accessibilityHidden(true) // HIG: визуальный индикатор
                            }
                            
                            // Бар "После"
                            BarView(
                                value: anxietyAfter,
                                height: chartHeight * afterHeight,
                                maxHeight: chartHeight,
                                color: changeColor,
                                label: "После"
                            )
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: Layout.chartHeight)
                .accessibilityElement(children: .contain)
                .accessibilityLabel("График динамики тревожности")
                
                // Шкала
                HStack {
                    ScaleLabelView(value: "0", description: "Нет тревоги", alignment: .leading)
                    Spacer()
                    ScaleLabelView(value: "10", description: "Максимум", alignment: .trailing)
                }
                .accessibilityHidden(true) // HIG: вспомогательная информация
            }
            .padding(Layout.cardPadding)
            .background(
                // HIG: semantic background с continuous corner radius
                RoundedRectangle(cornerRadius: Layout.cornerRadius, style: .continuous)
                    .fill(.background.tertiary.opacity(0.5))
            )
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Динамика тревожности от \(anxietyBefore) до \(anxietyAfter)")
    }
}

// MARK: - Bar View (вспомогательный компонент)

private struct BarView: View {
    let value: Int
    let height: CGFloat
    let maxHeight: CGFloat
    let color: Color
    let label: String
    
    // HIG: Layout constants
    private enum Layout {
        static let barWidth: CGFloat = 50
        static let barCornerRadius: CGFloat = 8
        static let spacing: CGFloat = 8
        static let labelSpacing: CGFloat = 4
    }
    
    var body: some View {
        VStack(spacing: Layout.spacing) {
            // Бар с градиентом
            ZStack(alignment: .bottom) {
                // Фоновый бар
                RoundedRectangle(cornerRadius: Layout.barCornerRadius, style: .continuous)
                    .fill(color.opacity(0.15)) // HIG: opacity для фона
                    .frame(width: Layout.barWidth, height: maxHeight)
                
                // Заполненный бар
                RoundedRectangle(cornerRadius: Layout.barCornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.7), color],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: Layout.barWidth, height: height)
            }
            
            // Значение и label
            VStack(spacing: Layout.labelSpacing) {
                Text("\(value)")
                    .font(.title2.weight(.bold)) // HIG: bold для числовых значений
                    .foregroundStyle(color)
                    .monospacedDigit() // HIG: предотвращает jumping
                Text(label)
                    .font(.caption) // HIG: caption для labels
                            .foregroundStyle(.secondary)
                    }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

// MARK: - Scale Label View (вспомогательный компонент)

private struct ScaleLabelView: View {
    let value: String
    let description: String
    let alignment: HorizontalAlignment
    
    var body: some View {
        VStack(alignment: alignment, spacing: 4) {
            Text(value)
                .font(.caption2) // HIG: caption2 для smallest text
                .foregroundStyle(.secondary)
            Text(description)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Previews

#Preview("Session History") {
    NavigationStack {
        SessionHistoryView(exposure: Exposure(
            title: "Тестовая экспозиция",
            exposureDescription: "Описание"
        ))
    }
    .modelContainer(for: [Exposure.self, SessionResult.self], inMemory: true)
}

#Preview("Session Detail") {
    let exposure = Exposure(
        title: "Тестовая экспозиция",
        exposureDescription: "Описание"
    )
    
    let session = SessionResult(
        exposure: exposure,
        startAt: Date().addingTimeInterval(-3600),
        endAt: Date(),
        anxietyBefore: 8,
        anxietyAfter: 4,
        notes: "Сеанс прошел успешно, тревога снизилась"
    )
    
    NavigationStack {
        SessionDetailView(session: session)
    }
}

