//
//  MainTabView.swift
//  Inner Hero
//
//  Created by Yauheni Kunitsa on 21.10.25.
//
//  HIG: Главный TabView с навигацией по основным разделам приложения
//  Следует Apple HIG для Tab Bars с правильными иконками, цветами и доступностью

import SwiftUI
import SwiftData

struct MainTabView: View {
    // HIG: @State для управления выбранной вкладкой с типобезопасностью
    @State private var selectedTab: Tab = .exposures
    
    // HIG: Enum для типобезопасного управления вкладками
    enum Tab {
        case exposures
        case history
        case profile
    }
    
    var body: some View {
        // HIG: TabView - стандартный паттерн навигации для iOS приложений с 2-5 основными разделами
        // HIG: Используем semantic colors через .tint() для автоматической поддержки Dark Mode
        TabView(selection: $selectedTab) {
            // ВКЛАДКА 1: Экспозиции (главный экран)
            ExposuresListView()
                .tag(Tab.exposures)
                .tabItem {
                    // HIG: Label с SF Symbol + текст для правильной accessibility
                    // HIG: SF Symbol "leaf.circle" символизирует рост и развитие
                    Label {
                        Text("Экспозиции")
                            // HIG: .font(.caption) для tab bar labels (автоматически применяется системой)
                    } icon: {
                        Image(systemName: "leaf.circle.fill")
                    }
                }
                // HIG: Accessibility label для VoiceOver (хотя Label уже содержит текст)
                .accessibilityLabel("Экспозиции")
            
            // ВКЛАДКА 2: История всех сеансов
            AllSessionsHistoryView()
                .tag(Tab.history)
                .tabItem {
                    // HIG: SF Symbol "chart.line.uptrend.xyaxis" для истории/прогресса
                    Label {
                        Text("История")
                    } icon: {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                    }
                }
                .accessibilityLabel("История сеансов")
            
            // ВКЛАДКА 3: Профиль/Настройки
            ProfileView()
                .tag(Tab.profile)
                .tabItem {
                    // HIG: SF Symbol "person.circle" стандартная иконка для профиля
                    Label {
                        Text("Профиль")
                    } icon: {
                        Image(systemName: "person.circle.fill")
                    }
                }
                .accessibilityLabel("Профиль")
        }
        // HIG: Используем .teal как основной accent color для успокаивающего эффекта
        // HIG: .tint() применяется к выбранным элементам TabBar
        .tint(.teal)
    }
}

// MARK: - All Sessions History View
// HIG: Экран истории всех сеансов терапии
struct AllSessionsHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SessionResult.startAt, order: .reverse) private var allSessions: [SessionResult]
    
    // HIG: Фильтрация только завершенных сеансов
    private var completedSessions: [SessionResult] {
        allSessions.filter { $0.endAt != nil }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if completedSessions.isEmpty {
                    // HIG: ContentUnavailableView - стандартный паттерн для empty states в iOS 17+
                    // HIG: Предоставляет понятную иконку, заголовок и описание
                    ContentUnavailableView {
                        Label("Нет сеансов", systemImage: "chart.line.uptrend.xyaxis")
                    } description: {
                        // HIG: .font(.body) для описания (по умолчанию)
                        // HIG: .foregroundStyle(.secondary) для вторичного текста
                        Text("Завершите первый сеанс терапии,\nчтобы увидеть историю")
                            .multilineTextAlignment(.center)
                    }
                } else {
                    // HIG: List - стандартный компонент для прокручиваемых списков с действиями
                    // HIG: Автоматически применяет правильные отступы, разделители и поддержку жестов
                    List {
                        ForEach(completedSessions) { session in
                            // HIG: NavigationLink для перехода к деталям
                            NavigationLink(destination: MainTabSessionDetailView(session: session)) {
                                SessionHistoryRowView(session: session)
                            }
                        }
                    }
                    // HIG: .listStyle(.insetGrouped) для современного grouped вида с rounded corners
                    .listStyle(.insetGrouped)
                }
            }
            // HIG: .navigationTitle с .large для главных экранов приложения
            .navigationTitle("История")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Session History Row View
// HIG: Компонент для отображения строки истории сеанса в списке
struct SessionHistoryRowView: View {
    let session: SessionResult
    
    var body: some View {
        // HIG: VStack с .leading alignment для естественного чтения слева направо
        // HIG: spacing: 8 (Spacing.xxs) для tight content внутри строки
        VStack(alignment: .leading, spacing: 8) {
            // Заголовок: название экспозиции
            Text(session.exposure?.title ?? "Без названия")
                // HIG: .font(.body.weight(.semibold)) для выделения главного текста
                .font(.body.weight(.semibold))
                // HIG: .foregroundStyle(.primary) для основного текста (авто dark mode)
                .foregroundStyle(.primary)
            
            // HIG: HStack для горизонтального расположения метаданных
            // HIG: spacing: 8 для tight spacing между иконкой и текстом
            HStack(spacing: 8) {
                // Иконка календаря
                Image(systemName: "calendar")
                    // HIG: .font(.caption) для маленьких иконок
                    .font(.caption)
                    // HIG: .foregroundStyle(.secondary) для вторичных элементов
                    .foregroundStyle(.secondary)
                    // HIG: .accessibilityHidden для декоративных иконок
                    .accessibilityHidden(true)
                
                // Дата сеанса
                Text(session.startAt, style: .date)
                    // HIG: .font(.caption) для метаданных и timestamps
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                // Разделитель
                Text("•")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
                
                // Время сеанса
                Text(session.startAt, style: .time)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            // HIG: .accessibilityElement для объединения элементов для VoiceOver
            .accessibilityElement(children: .combine)
            
            // Показать изменение уровня тревоги если сеанс завершен
            if let anxietyAfter = session.anxietyAfter {
                // HIG: HStack для anxiety level badge
                HStack(spacing: 6) {
                    Image(systemName: "heart.fill")
                        .font(.caption2)
                        .foregroundStyle(anxietyChangeColor)
                        .accessibilityHidden(true)
                    
                    Text(anxietyChangeText)
                        // HIG: .font(.caption2) для tertiary информации
                        .font(.caption2)
                        // HIG: .fontWeight(.medium) для небольшого выделения
                        .fontWeight(.medium)
                        .foregroundStyle(anxietyChangeColor)
                }
                // HIG: .padding для badge с rounded background
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                // HIG: Прозрачный фон с цветом тревоги
                .background(
                    Capsule()
                        .fill(anxietyChangeColor.opacity(0.15))
                )
            }
        }
        // HIG: .padding(.vertical, 4) для дополнительного пространства в строке списка
        .padding(.vertical, 4)
    }
    
    // Вычисление изменения уровня тревоги
    private var anxietyChange: Int {
        guard let after = session.anxietyAfter else { return 0 }
        return session.anxietyBefore - after
    }
    
    private var anxietyChangeText: String {
        guard let after = session.anxietyAfter else { return "" }
        let change = anxietyChange
        if change > 0 {
            return "Тревога: \(session.anxietyBefore) → \(after) (-\(change))"
        } else if change < 0 {
            return "Тревога: \(session.anxietyBefore) → \(after) (+\(abs(change)))"
        } else {
            return "Тревога: \(session.anxietyBefore) → \(after)"
        }
    }
    
    private var anxietyChangeColor: Color {
        let change = anxietyChange
        if change > 0 {
            return .green  // Снижение тревоги - хорошо
        } else if change < 0 {
            return .orange // Увеличение тревоги
        } else {
            return .blue   // Без изменений
        }
    }
    
    // HIG: Функция для определения цвета по уровню тревоги (из guidelines)
    private func anxietyColor(for level: Double) -> Color {
        switch level {
        case 0...3:
            return .green       // Low anxiety
        case 4...6:
            return .orange      // Moderate anxiety
        case 7...10:
            return .red         // High anxiety
        default:
            return .gray
        }
    }
}

// MARK: - Main Tab Session Detail View (placeholder)
// HIG: Детальный просмотр сеанса из главной вкладки
struct MainTabSessionDetailView: View {
    let session: SessionResult
    
    var body: some View {
        ScrollView {
            // HIG: LazyVStack для оптимизации производительности
            // HIG: spacing: 24 (Spacing.xl) для разделения секций
            LazyVStack(alignment: .leading, spacing: 24) {
                // Информация о сеансе
                VStack(alignment: .leading, spacing: 16) {
                    Text("Экспозиция")
                        // HIG: .font(.headline) для section labels
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    Text(session.exposure?.title ?? "Без названия")
                        // HIG: .font(.title2.weight(.semibold)) для заголовков секций
                        .font(.title2.weight(.semibold))
                }
                
                // Временные метки
                VStack(alignment: .leading, spacing: 12) {
                    DetailRow(icon: "calendar", title: "Начало", value: session.startAt.formatted(date: .long, time: .shortened))
                    
                    if let endAt = session.endAt {
                        DetailRow(icon: "checkmark.circle", title: "Окончание", value: endAt.formatted(date: .long, time: .shortened))
                    }
                }
                
                // Уровни тревоги
                VStack(alignment: .leading, spacing: 16) {
                    Text("Уровни тревоги")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("До сеанса")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(session.anxietyBefore)/10")
                                .font(.title2.weight(.bold))
                                .foregroundStyle(anxietyColorForLevel(session.anxietyBefore))
                        }
                        
                        Spacer()
                        
                        if let anxietyAfter = session.anxietyAfter {
                            Image(systemName: "arrow.right")
                                .foregroundStyle(.secondary)
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("После сеанса")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("\(anxietyAfter)/10")
                                    .font(.title2.weight(.bold))
                                    .foregroundStyle(anxietyColorForLevel(anxietyAfter))
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(.systemGray6))
                    )
                }
                
                // Заметки
                if !session.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Заметки")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        
                        Text(session.notes)
                            .font(.body)
                            .foregroundStyle(.primary)
                    }
                }
            }
            // HIG: Screen edges padding - 20pt horizontal, 24pt vertical
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        // HIG: Background для контрастности карточек
        .background {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
        }
        // HIG: .navigationTitle для detail экранов
        .navigationTitle("Детали сеанса")
        // HIG: .inline для detail screens (не главных)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func anxietyColorForLevel(_ level: Int) -> Color {
        switch level {
        case 0...3:
            return .green
        case 4...6:
            return .orange
        case 7...10:
            return .red
        default:
            return .gray
        }
    }
}

// MARK: - Detail Row Component
struct DetailRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        // HIG: HStack для горизонтального layout с иконкой
        HStack(spacing: 12) {
            Image(systemName: icon)
                // HIG: .font(.body) для иконок среднего размера
                .font(.body)
                .foregroundStyle(.teal)
                // HIG: .frame для минимальной ширины иконки (выравнивание)
                .frame(width: 24)
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    // HIG: .font(.caption) для labels
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(value)
                    // HIG: .font(.body) для основного контента
                    .font(.body)
                    .foregroundStyle(.primary)
            }
        }
    }
}

// MARK: - Profile View (placeholder)
// HIG: Экран профиля/настроек пользователя
struct ProfileView: View {
    var body: some View {
        NavigationStack {
            // HIG: Form для настроечных экранов
            Form {
                // Секция информации о приложении
                Section {
                    HStack {
                        Image(systemName: "leaf.circle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.teal)
                            .accessibilityHidden(true)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Inner Hero")
                                // HIG: .font(.title3.weight(.semibold))
                                .font(.title3.weight(.semibold))
                            Text("Версия 1.0")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    // HIG: .padding для дополнительного пространства
                    .padding(.vertical, 8)
                }
                
                // Секция настроек
                Section("Настройки") {
                    NavigationLink {
                        Text("Уведомления")
                            .navigationTitle("Уведомления")
                            .navigationBarTitleDisplayMode(.inline)
                    } label: {
                        Label("Уведомления", systemImage: "bell")
                    }
                    
                    NavigationLink {
                        Text("Конфиденциальность")
                            .navigationTitle("Конфиденциальность")
                            .navigationBarTitleDisplayMode(.inline)
                    } label: {
                        Label("Конфиденциальность", systemImage: "lock.shield")
                    }
                }
                
                // Секция поддержки
                Section("Поддержка") {
                    NavigationLink {
                        Text("Помощь")
                            .navigationTitle("Помощь")
                            .navigationBarTitleDisplayMode(.inline)
                    } label: {
                        Label("Помощь", systemImage: "questionmark.circle")
                    }
                    
                    NavigationLink {
                        Text("О приложении")
                            .navigationTitle("О приложении")
                            .navigationBarTitleDisplayMode(.inline)
                    } label: {
                        Label("О приложении", systemImage: "info.circle")
                    }
                }
            }
            // HIG: Large title для главных экранов
            .navigationTitle("Профиль")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Preview
#Preview {
    MainTabView()
        .modelContainer(for: Exposure.self, inMemory: true)
}
