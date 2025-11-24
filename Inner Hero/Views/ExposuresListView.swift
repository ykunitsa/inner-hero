//
//  ExposuresListView.swift
//  Inner Hero
//
//  Created by Yauheni Kunitsa on 21.10.25.
//

import SwiftUI
import SwiftData

struct ExposuresListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Exposure.createdAt, order: .reverse) private var exposures: [Exposure]
    @Query(sort: \SessionResult.startAt, order: .reverse) private var allSessions: [SessionResult]
    
    @State private var showingCreateSheet = false
    @State private var exposureToDelete: Exposure?
    @State private var showingDeleteAlert = false
    @State private var showingStartSession = false
    @State private var exposureToStart: Exposure?
    @State private var currentSession: SessionResult?
    @State private var showingActiveSession = false
    @State private var appeared = false
    
    // Active sessions computed property
    private var activeSessions: [SessionResult] {
        allSessions.filter { $0.endAt == nil }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                // HIG: LazyVStack для оптимизации производительности больших списков
                // HIG: spacing: 24 (кратно 8) для разделения между major sections
                LazyVStack(spacing: 24) {
                    // Active Session Card (if exists)
                    if let activeSession = activeSessions.first {
                        activeSessionCard(session: activeSession)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    // Exposures Section
                    if exposures.isEmpty {
                        emptyStateView
                    } else {
                        exposuresSection
                    }
                }
                // HIG: Стандартные отступы для screen edges - 20pt horizontal
                .padding(.horizontal, 20)
                // HIG: Верхний отступ 24pt для breathing room после navigation bar
                .padding(.top, 24)
                // HIG: Нижний отступ 40pt для комфортного скролла до конца
                .padding(.bottom, 40)
            }
            // HIG: Использование semantic color вместо кастомного backgroundColor
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Inner Hero")
            // HIG: .large для главного экрана приложения
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    // HIG: primaryAction вместо navigationBarTrailing для правильного расположения
                    Button {
                        showingCreateSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            // HIG: Dynamic Type - .title2 вместо фиксированного размера
                            .font(.title2)
                            // HIG: Использование системного .teal вместо кастомного primaryGreen
                            .foregroundStyle(.teal)
                    }
                    // HIG: Минимальный touch target 44x44pt для кнопок
                    .frame(minWidth: 44, minHeight: 44)
                    .accessibilityLabel("Добавить экспозицию")
                }
            }
            .sheet(isPresented: $showingCreateSheet) {
                CreateExposureView()
            }
            .sheet(isPresented: $showingStartSession) {
                if let exposure = exposureToStart {
                    StartSessionSheet(exposure: exposure) { session in
                        currentSession = session
                        showingStartSession = false
                        showingActiveSession = true
                    }
                }
            }
            .navigationDestination(isPresented: $showingActiveSession) {
                if let session = currentSession, let exposure = exposureToStart {
                    ActiveSessionView(session: session, exposure: exposure)
                }
            }
            .alert("Удалить экспозицию?", isPresented: $showingDeleteAlert, presenting: exposureToDelete) { exposure in
                Button("Отмена", role: .cancel) {
                    exposureToDelete = nil
                }
                Button("Удалить", role: .destructive) {
                    deleteExposure(exposure)
                }
            } message: { exposure in
                Text("Вы уверены, что хотите удалить экспозицию \"\(exposure.title)\"? Это действие нельзя отменить.")
            }
            .opacity(appeared ? 1 : 0)
            // HIG: Стандартная анимация 0.3-0.4s для появления контента
            .animation(.easeIn(duration: 0.3), value: appeared)
            .onAppear {
                appeared = true
            }
        }
    }
    
    // MARK: - Active Session Card
    
    @ViewBuilder
    private func activeSessionCard(session: SessionResult) -> some View {
        if let exposure = session.exposure {
            Button {
                currentSession = session
                exposureToStart = exposure
                showingActiveSession = true
            } label: {
                // HIG: spacing: 16 для стандартного card content spacing
                VStack(alignment: .leading, spacing: 16) {
                    // Header row
                    HStack {
                        Image(systemName: "circle.fill")
                            // HIG: Dynamic Type .caption для маленьких иконок
                            .font(.caption)
                            .foregroundStyle(.green)
                            .accessibilityHidden(true)
                        
                        // HIG: Убран .textCase(.uppercase) - anti-pattern для кириллицы
                        // HIG: Используем .caption + .medium для section labels
                        Text("Активный сеанс")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        Image(systemName: "arrow.right.circle.fill")
                            // HIG: Dynamic Type .body для navigation indicators
                            .font(.body)
                            .foregroundStyle(.teal)
                    }
                    
                    // Content
                    // HIG: spacing: 12 для compact spacing внутри карточки
                    VStack(alignment: .leading, spacing: 12) {
                        Text(exposure.title)
                            // HIG: .title2 + .semibold для card titles
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                        
                        // HIG: spacing: 16 для разделения metadata groups
                        HStack(spacing: 16) {
                            Label {
                                Text(session.startAt, style: .relative)
                                    // HIG: Dynamic Type .body для основного контента
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                            } icon: {
                                Image(systemName: "clock")
                                    .font(.body)
                                    .foregroundStyle(.teal)
                            }
                            
                            if !exposure.steps.isEmpty {
                                Label {
                                    Text("\(session.completedStepIndices.count)/\(exposure.steps.count)")
                                        .font(.body)
                                        .foregroundStyle(.secondary)
                                } icon: {
                                    Image(systemName: "checkmark.circle")
                                        .font(.body)
                                        .foregroundStyle(.teal)
                                }
                            }
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
                // HIG: Standard card padding - 20pt
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    // HIG: Corner radius 16pt (.lg) для large cards + .continuous style
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        // HIG: Semantic color для карточек на grouped background
                        .fill(Color(.secondarySystemGroupedBackground))
                        // HIG: Уменьшенная тень для более нативного вида
                        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
                )
                // HIG: Subtle border для active session card с использованием системного цвета
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color.teal.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Продолжить активный сеанс: \(exposure.title)")
            .accessibilityHint("Дважды нажмите, чтобы возобновить сеанс")
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        // HIG: spacing: 24 для empty state elements
        VStack(spacing: 24) {
            Image(systemName: "leaf.circle")
                .font(.system(size: 72))
                // HIG: Использование системного .teal вместо кастомного primaryGreen
                .foregroundStyle(.teal.opacity(0.6))
                .accessibilityHidden(true)
            
            // HIG: spacing: 12 для tight text groups
            VStack(spacing: 12) {
                Text("Начните свой путь")
                    // HIG: Dynamic Type .title2 + .semibold для empty state headers
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.primary)
                
                Text("Создайте первую экспозицию для работы с тревогой")
                    // HIG: Dynamic Type .body для descriptions
                    .font(.body)
                    // HIG: Semantic color .secondary вместо mutedText
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 80)
        .accessibilityElement(children: .combine)
    }
    
    // MARK: - Exposures Section
    
    private var exposuresSection: some View {
        // HIG: spacing: 20 для section content
        VStack(alignment: .leading, spacing: 20) {
            // HIG: Убран .textCase(.uppercase) и .tracking - anti-pattern для кириллицы
            Text("Мои экспозиции")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .padding(.leading, 4)
            
            // HIG: spacing: 16 для card stacks
            VStack(spacing: 16) {
                ForEach(Array(exposures.enumerated()), id: \.element.id) { index, exposure in
                    exposureCard(exposure: exposure)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                        // HIG: Staggered animation с разумной задержкой (0.05s)
                        .animation(.easeOut(duration: 0.3).delay(Double(index) * 0.05), value: appeared)
                }
            }
        }
    }
    
    // MARK: - Exposure Card
    
    private func exposureCard(exposure: Exposure) -> some View {
        NavigationLink(destination: ExposureDetailView(exposure: exposure, onStartSession: {
            startSession(for: exposure)
        })) {
            // HIG: spacing: 16 для card internal content
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    // HIG: spacing: 8 для tight content groups
                    VStack(alignment: .leading, spacing: 8) {
                        Text(exposure.title)
                            // HIG: .title3 + .semibold для exposure card titles (немного меньше чем .title2)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                        
                        Text(exposure.exposureDescription)
                            // HIG: Dynamic Type .body для descriptions
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                    
                    Spacer(minLength: 12)
                    
                    Image(systemName: "chevron.right")
                        // HIG: Dynamic Type .body для chevrons
                        .font(.body)
                        // HIG: Semantic tertiary label color для subtle indicators
                        .foregroundStyle(Color(.tertiaryLabel))
                }
                
                Divider()
                    // HIG: Использование системного .separator
                    .background(Color(.separator))
                
                // HIG: spacing: 20 для metadata row
                HStack(spacing: 20) {
                    // HIG: spacing: 6 для tight icon+text combinations
                    HStack(spacing: 6) {
                        Image(systemName: "list.bullet")
                            .font(.caption)
                            .foregroundStyle(.teal)
                        Text("\(exposure.steps.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack(spacing: 6) {
                        Image(systemName: "chart.bar")
                            .font(.caption)
                            .foregroundStyle(.teal)
                        Text("\(exposure.sessionResults.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    // HIG: Inline action button в карточке
                    Button {
                        startSession(for: exposure)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "play.fill")
                                .font(.caption)
                            Text("Начать")
                                .font(.caption.weight(.medium))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Color.teal))
                    }
                    // HIG: .plain style для кнопок внутри NavigationLink (избегаем конфликта жестов)
                    .buttonStyle(.plain)
                    // HIG: Минимальный touch target для inline buttons
                    .frame(minHeight: 44)
                }
                .accessibilityElement(children: .combine)
            }
            // HIG: Standard card padding - 20pt
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                // HIG: Corner radius 16pt + .continuous style
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    // HIG: Semantic color для карточек
                    .fill(Color(.secondarySystemGroupedBackground))
                    // HIG: Нативная тень - subtle для Light Mode
                    .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                startSession(for: exposure)
            } label: {
                Label("Начать сеанс", systemImage: "play.fill")
            }
            
            // HIG: Destructive action в context menu
            Button(role: .destructive) {
                exposureToDelete = exposure
                showingDeleteAlert = true
            } label: {
                Label("Удалить", systemImage: "trash")
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(exposure.title). \(exposure.steps.count) шагов, \(exposure.sessionResults.count) сеансов")
        .accessibilityHint("Дважды нажмите для просмотра деталей")
    }
    
    // MARK: - Actions
    
    private func startSession(for exposure: Exposure) {
        exposureToStart = exposure
        showingStartSession = true
    }
    
    private func deleteExposures(offsets: IndexSet) {
        // HIG: Стандартная анимация для удаления
        withAnimation(.easeInOut(duration: 0.3)) {
            for index in offsets {
                modelContext.delete(exposures[index])
            }
        }
    }
    
    private func deleteExposure(_ exposure: Exposure) {
        withAnimation(.easeInOut(duration: 0.3)) {
            modelContext.delete(exposure)
            exposureToDelete = nil
        }
    }
}

// MARK: - Exposure Detail View

struct ExposureDetailView: View {
    let exposure: Exposure
    let onStartSession: () -> Void
    
    // HIG: Computed properties для статистики
    private var totalSteps: Int {
        exposure.steps.count
    }
    
    private var stepsWithTimer: Int {
        exposure.steps.filter { $0.hasTimer }.count
    }
    
    var body: some View {
        ScrollView {
            // HIG: LazyVStack + spacing: 32 для major sections
            LazyVStack(spacing: 32) {
                // Hero Header
                heroHeaderSection
                
                // Quick Stats
                quickStatsSection
                
                // Description Card
                descriptionCard
                
                // Steps Section
                if !exposure.steps.isEmpty {
                    stepsSection
                }
                
                // Sessions History
                sessionsHistoryCard
                
                // Start Session Button
                startSessionButton
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 40)
        }
        // HIG: Semantic background color
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Детали")
        // HIG: .inline для detail screens
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink(destination: EditExposureView(exposure: exposure)) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.teal)
                }
                // HIG: Touch target для toolbar buttons
                .frame(minWidth: 44, minHeight: 44)
            }
        }
    }
    
    // MARK: - View Components
    
    private var heroHeaderSection: some View {
        // HIG: spacing: 16 для hero section elements
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.teal.opacity(0.15))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "figure.mind.and.body")
                    .font(.system(size: 50))
                    .foregroundStyle(.teal)
            }
            
            Text(exposure.title)
                // HIG: .title + .semibold для hero titles
                .font(.title.weight(.semibold))
                .multilineTextAlignment(.center)
        }
        .accessibilityElement(children: .combine)
    }
    
    private var quickStatsSection: some View {
        // HIG: spacing: 16 для stats grid
        HStack(spacing: 16) {
            QuickStatCard(
                icon: "list.number",
                value: "\(totalSteps)",
                label: "Шагов",
                color: .teal
            )
            
            QuickStatCard(
                icon: "timer",
                value: "\(stepsWithTimer)",
                label: "С таймером",
                color: .orange
            )
            
            QuickStatCard(
                icon: "chart.bar.fill",
                value: "\(exposure.sessionResults.count)",
                label: "Сеансов",
                color: .teal
            )
        }
    }
    
    private var descriptionCard: some View {
        // HIG: spacing: 16 для card content
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "doc.text")
                    .font(.body)
                    .foregroundStyle(.teal)
                Text("Описание")
                    // HIG: .body + .semibold для card section headers
                    .font(.body.weight(.semibold))
            }
            
            Text(exposure.exposureDescription)
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        )
    }
    
    private var stepsSection: some View {
        // HIG: spacing: 20 для section content
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "checklist")
                    .font(.body)
                    .foregroundStyle(.teal)
                Text("Шаги выполнения")
                    .font(.body.weight(.semibold))
            }
            
            // HIG: spacing: 12 для step cards stack
            VStack(spacing: 12) {
                ForEach(Array(exposure.steps.enumerated()), id: \.offset) { index, step in
                    StepDetailCard(step: step, index: index)
                }
            }
        }
    }
    
    private var sessionsHistoryCard: some View {
        NavigationLink(destination: SessionHistoryView(exposure: exposure)) {
            // HIG: spacing: 16 для card content
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "clock")
                        .font(.body)
                        .foregroundStyle(.teal)
                    Text("История сеансов")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                if exposure.sessionResults.count > 0 {
                    // HIG: spacing: 20 для stats groups
                    HStack(spacing: 20) {
                        // HIG: spacing: 4 для tight label+value
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Всего")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(exposure.sessionResults.count)")
                                // HIG: .title2 + .semibold для prominent numbers
                                .font(.title2.weight(.semibold))
                                .foregroundStyle(.primary)
                        }
                        
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Последний")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if let lastSession = exposure.sessionResults.sorted(by: { $0.startAt > $1.startAt }).first {
                                Text(lastSession.startAt, style: .relative)
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(.teal)
                            }
                        }
                    }
                } else {
                    Text("Нет завершенных сеансов")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var startSessionButton: some View {
        Button {
            onStartSession()
        } label: {
            // HIG: spacing: 12 для button icon+text
            HStack(spacing: 12) {
                Image(systemName: "play.fill")
                    .font(.body)
                Text("Начать сеанс")
                    // HIG: .headline для prominent button text
                    .font(.headline)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            // HIG: Минимальная высота 56pt для primary action buttons (больше стандартных 44pt)
            .frame(minHeight: 56)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.teal)
                    // HIG: Accent shadow для prominent actions
                    .shadow(color: Color.teal.opacity(0.3), radius: 12, y: 6)
            )
        }
        .accessibilityLabel("Начать сеанс")
    }
}

// MARK: - Supporting Views

struct QuickStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        // HIG: spacing: 8 для tight vertical layout
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(color)
            
            Text(value)
                // HIG: .title3 + .semibold для stat values
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            // HIG: Corner radius 12pt для smaller cards
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(color.opacity(0.08))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(value) \(label)")
    }
}

struct StepDetailCard: View {
    let step: Step
    let index: Int
    
    var body: some View {
        // HIG: spacing: 16 для card content
        HStack(alignment: .top, spacing: 16) {
            // Step number badge
            ZStack {
                Circle()
                    .fill(Color.teal.opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Text("\(index + 1)")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.teal)
            }
            
            // HIG: spacing: 8 для compact content
            VStack(alignment: .leading, spacing: 8) {
                Text(step.text)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                
                if step.hasTimer {
                    // HIG: spacing: 6 для tight icon+text
                    HStack(spacing: 6) {
                        Image(systemName: "timer")
                            .font(.caption)
                        Text("\(step.timerDuration / 60):\(String(format: "%02d", step.timerDuration % 60))")
                            .font(.caption.weight(.medium))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(.orange))
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                // HIG: Semantic color для nested cards
                .fill(Color(.tertiarySystemBackground))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Шаг \(index + 1): \(step.text)")
    }
}

// MARK: - Start Session Sheet

struct StartSessionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let exposure: Exposure
    let onSessionCreated: (SessionResult) -> Void
    
    @State private var anxietyBefore: Double = 5
    @State private var showError = false
    @State private var errorMessage = ""
    
    private var dataManager: DataManager {
        DataManager(modelContext: modelContext)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                // HIG: spacing: 32 для major sections в sheets
                VStack(spacing: 32) {
                    // Header
                    // HIG: spacing: 16 для header elements
                    VStack(spacing: 16) {
                        Image(systemName: "figure.mind.and.body")
                            .font(.system(size: 60))
                            .foregroundStyle(.teal)
                        
                        Text("Начать сеанс")
                            .font(.title2.weight(.semibold))
                        
                        Text(exposure.title)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // Anxiety Before
                    // HIG: spacing: 20 для form sections
                    VStack(alignment: .leading, spacing: 20) {
                        Label("Уровень тревоги", systemImage: "gauge")
                            // HIG: .headline для form section headers
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        Text("Оцените ваш текущий уровень тревоги до начала сеанса (0–10)")
                            .font(.body)
                            .foregroundStyle(.secondary)
                        
                        // HIG: spacing: 20 для form controls group
                        VStack(spacing: 20) {
                            // Anxiety Value Display
                            HStack {
                                Spacer()
                                Text("\(Int(anxietyBefore))")
                                    // HIG: Rounded design + .bold для prominent numbers
                                    // HIG: monospacedDigit() предотвращает jumping при изменении цифр
                                    .font(.system(.largeTitle, design: .rounded))
                                    .fontWeight(.bold)
                                    .monospacedDigit()
                                    .foregroundStyle(anxietyColor(for: Int(anxietyBefore)))
                                Spacer()
                            }
                            
                            // Slider
                            // HIG: spacing: 8 для slider labels
                            VStack(spacing: 8) {
                                Slider(value: $anxietyBefore, in: 0...10, step: 1)
                                    .tint(anxietyColor(for: Int(anxietyBefore)))
                                
                                HStack {
                                    Text("0\nНет тревоги")
                                        .font(.caption)
                                        .multilineTextAlignment(.leading)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text("5\nСредний")
                                        .font(.caption)
                                        .multilineTextAlignment(.center)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text("10\nМаксимум")
                                        .font(.caption)
                                        .multilineTextAlignment(.trailing)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                            // Anxiety Description
                            Text(anxietyDescription(for: Int(anxietyBefore)))
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        // HIG: Semantic tertiary background для info boxes
                                        .fill(Color(.tertiarySystemBackground))
                                )
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color(.secondarySystemGroupedBackground))
                                .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 20)
                    
                    // Start Button
                    Button {
                        startSession()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "play.fill")
                                .font(.body)
                            Text("Начать сеанс")
                                .font(.headline)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        // HIG: Минимальная высота 56pt для primary actions
                        .frame(minHeight: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.teal)
                                .shadow(color: Color.teal.opacity(0.3), radius: 12, y: 6)
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            // HIG: Semantic background для sheets
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Новый сеанс")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
            }
            .alert("Ошибка", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Helper Functions
    
    // HIG: Системные цвета для anxiety levels
    private func anxietyColor(for value: Int) -> Color {
        switch value {
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
    
    private func anxietyDescription(for value: Int) -> String {
        switch value {
        case 0:
            return "Полное спокойствие, нет тревоги"
        case 1...2:
            return "Очень низкий уровень тревоги"
        case 3...4:
            return "Легкая тревога, управляемая"
        case 5...6:
            return "Средний уровень тревоги, заметный дискомфорт"
        case 7...8:
            return "Высокая тревога, значительный дистресс"
        case 9:
            return "Очень высокая тревога, трудно терпеть"
        case 10:
            return "Экстремальная тревога, паника"
        default:
            return ""
        }
    }
    
    private func startSession() {
        do {
            let session = try dataManager.createSessionResult(
                for: exposure,
                anxietyBefore: Int(anxietyBefore)
            )
            dismiss()
            onSessionCreated(session)
        } catch {
            errorMessage = "Не удалось создать сеанс: \(error.localizedDescription)"
            showError = true
        }
    }
}

#Preview {
    ExposuresListView()
        .modelContainer(for: Exposure.self, inMemory: true)
}
