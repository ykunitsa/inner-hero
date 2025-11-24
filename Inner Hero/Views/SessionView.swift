//
//  SessionView.swift
//  Inner Hero
//
//  Created by Yauheni Kunitsa on 21.10.25.
//

import SwiftUI
import SwiftData

struct SessionView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Exposure.createdAt, order: .reverse) private var exposures: [Exposure]
    
    @State private var selectedExposure: Exposure?
    @State private var anxietyBefore: Double = 5
    @State private var showingActiveSession = false
    @State private var currentSession: SessionResult?
    @State private var showError = false
    @State private var errorMessage = ""
    
    // HIG: Accessibility — Reduce Motion support
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    private var dataManager: DataManager {
        DataManager(modelContext: modelContext)
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if exposures.isEmpty {
                    emptyStateView
                } else {
                    startSessionForm
                }
            }
            .navigationTitle("Сеанс")
            // HIG: Navigation — Large title для главных экранов
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(isPresented: $showingActiveSession) {
                if let session = currentSession, let exposure = selectedExposure {
                    ActiveSessionView(session: session, exposure: exposure)
                }
            }
            .alert("Ошибка", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Subviews
    
    private var emptyStateView: some View {
        // HIG: Empty States — ContentUnavailableView для пустых состояний
        ContentUnavailableView(
            "Нет экспозиций",
            systemImage: "play.circle",
            description: Text("Создайте экспозицию на вкладке \"Экспозиции\"")
        )
    }
    
    private var startSessionForm: some View {
        ScrollView {
            VStack(spacing: 32) { // HIG: Spacing — 32pt между major sections
                formHeader
                
                VStack(spacing: 24) { // HIG: Spacing — 24pt между секциями формы
                    exposureSelectionSection
                    
                    Divider()
                        .padding(.horizontal, 20)
                    
                    anxietyBeforeSection
                }
                
                startSessionButton
            }
        }
        // HIG: Colors — semantic background для scroll view
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
    
    // MARK: - Form Components
    
    private var formHeader: some View {
        VStack(spacing: 16) { // HIG: Spacing — 16pt между связанными элементами
            Image(systemName: "figure.mind.and.body")
                // HIG: Typography — используем Dynamic Type вместо .system(size: 70)
                .font(.system(size: 64))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.blue)
                // HIG: Accessibility — декоративная иконка скрыта от VoiceOver
                .accessibilityHidden(true)
            
            Text("Начать новый сеанс")
                // HIG: Typography — .title2 для section headers (22pt)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
        }
        .padding(.top, 24) // HIG: Spacing — 24pt от верхнего края
    }
    
    private var exposureSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) { // HIG: Spacing — 12pt для form fields
            Label("Выберите экспозицию", systemImage: "list.bullet.clipboard")
                // HIG: Typography — .headline для emphasized labels (17pt semibold)
                .font(.headline)
                .foregroundStyle(.primary)
            
            if let selected = selectedExposure {
                exposureCard(selected)
                    // HIG: Animation — условная анимация с reduceMotion
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
            
            exposureSelectionMenu
        }
        .padding(.horizontal, 20) // HIG: Spacing — 20pt горизонтальные отступы от краев экрана
    }
    
    private var exposureSelectionMenu: some View {
        Menu {
            ForEach(exposures) { exposure in
                Button {
                    selectExposure(exposure)
                } label: {
                    HStack {
                        Text(exposure.title)
                        if exposure.id == selectedExposure?.id {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            exposureSelectionMenuLabel
        }
        // HIG: Touch Targets — минимум 44x44pt для интерактивных элементов
        .frame(minHeight: 44)
        .accessibilityLabel("Выбор экспозиции")
        .accessibilityHint(selectedExposure == nil ? "Выберите экспозицию для начала сеанса" : "Текущая экспозиция: \(selectedExposure?.title ?? "")")
    }
    
    private var exposureSelectionMenuLabel: some View {
        HStack {
            Text(selectedExposure == nil ? "Выбрать экспозицию" : "Изменить выбор")
                // HIG: Typography — .body для основного текста (17pt)
                .font(.body)
                .foregroundStyle(selectedExposure == nil ? Color.secondary : Color.blue)
            Spacer()
            Image(systemName: "chevron.down")
                // HIG: Typography — .footnote для вспомогательных иконок
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        // HIG: Spacing — 16pt padding для интерактивных элементов
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        // HIG: Colors — semantic background colors
        .background(Color(.secondarySystemGroupedBackground))
        // HIG: Layout — .continuous corner radius для современного вида
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    
    private func selectExposure(_ exposure: Exposure) {
        // HIG: Animation — respect Reduce Motion
        withAnimation(reduceMotion ? .none : .easeInOut(duration: 0.3)) {
            selectedExposure = exposure
        }
        // HIG: Haptics — selection feedback
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
    
    private var anxietyBeforeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
                        Label("Уровень тревоги (0–10)", systemImage: "gauge.with.dots.needle.33percent")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        Text("Оцените ваш текущий уровень тревоги до начала сеанса")
                            // HIG: Typography — .subheadline для supporting text (15pt)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        VStack(spacing: 20) { // HIG: Spacing — 20pt между элементами контрола
                            // Anxiety Value Display
                            HStack {
                                Spacer()
                                Text("\(Int(anxietyBefore))")
                                    // HIG: Typography — Dynamic Type для больших цифр
                                    .font(.system(.largeTitle, design: .rounded))
                                    .fontWeight(.bold)
                                    // HIG: Typography — предотвращаем "прыгание" цифр
                                    .monospacedDigit()
                                    .foregroundStyle(anxietyColor(for: Int(anxietyBefore)))
                                    // HIG: Accessibility — описание значения для VoiceOver
                                    .accessibilityLabel("Уровень тревоги: \(Int(anxietyBefore)) из 10")
                                Spacer()
                            }
                            .padding(.vertical, 12) // HIG: Spacing — 12pt vertical padding
                            
                            // Slider
                            VStack(spacing: 8) { // HIG: Spacing — 8pt tight spacing
                                Slider(value: $anxietyBefore, in: 0...10, step: 1)
                                    .tint(anxietyColor(for: Int(anxietyBefore)))
                                    // HIG: Accessibility — VoiceOver label для slider
                                    .accessibilityLabel("Уровень тревоги")
                                    .accessibilityValue("\(Int(anxietyBefore)) из 10")
                                    .onChange(of: anxietyBefore) { _, _ in
                                        // HIG: Haptics — feedback при изменении значения
                                        let generator = UISelectionFeedbackGenerator()
                                        generator.selectionChanged()
                                    }
                                
                                HStack {
                                    Text("0\nНет тревоги")
                                        // HIG: Typography — .caption2 для smallest text (11pt)
                                        .font(.caption2)
                                        .multilineTextAlignment(.leading)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text("5\nСредний\nуровень")
                                        .font(.caption2)
                                        .multilineTextAlignment(.center)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text("10\nМаксимум")
                                        .font(.caption2)
                                        .multilineTextAlignment(.trailing)
                                        .foregroundStyle(.secondary)
                                }
                                // HIG: Accessibility — скрываем декоративные метки от VoiceOver
                                .accessibilityHidden(true)
                            }
                            
                            // Anxiety Description
                            Text(anxietyDescription(for: Int(anxietyBefore)))
                                // HIG: Typography — .callout для secondary content (16pt)
                                .font(.callout)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.vertical, 12) // HIG: Spacing — 12pt padding
                                .frame(maxWidth: .infinity)
                                // HIG: Colors — semantic background colors
                                .background(Color(.tertiarySystemGroupedBackground))
                                // HIG: Layout — .continuous corner radius
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                // HIG: Accessibility — VoiceOver читает описание
                                .accessibilityLabel("Описание уровня тревоги: \(anxietyDescription(for: Int(anxietyBefore)))")
                        }
                        // HIG: Spacing — 20pt padding для card-like контента
                        .padding(20)
                        // HIG: Colors — subtle background для выделения секции
                        .background(Color(.secondarySystemGroupedBackground))
                        // HIG: Layout — .continuous corner radius 12pt
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .padding(.horizontal, 20)
    }
    
    private var startSessionButton: some View {
        Button {
                    startSession()
                } label: {
                    Label("Начать сеанс", systemImage: "play.fill")
                        // HIG: Typography — .headline для button labels (17pt semibold)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                // HIG: Buttons — используем .borderedProminent для primary actions
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                // HIG: Touch Targets — минимум 56pt для prominent buttons
                .controlSize(.large)
                .disabled(selectedExposure == nil)
                .padding(.horizontal, 20)
                .padding(.bottom, 24) // HIG: Spacing — 24pt bottom padding
                // HIG: Accessibility — VoiceOver hint
                .accessibilityHint(selectedExposure == nil ? "Сначала выберите экспозицию" : "Начать сеанс с экспозицией \(selectedExposure?.title ?? "")")
    }
    
    // MARK: - Helper Views
    
    private func exposureCard(_ exposure: Exposure) -> some View {
        VStack(alignment: .leading, spacing: 8) { // HIG: Spacing — 8pt tight spacing внутри card
            HStack {
                VStack(alignment: .leading, spacing: 4) { // HIG: Spacing — 4pt между title и description
                    Text(exposure.title)
                        // HIG: Typography — .body.weight(.semibold) для card titles
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    Text(exposure.exposureDescription)
                        // HIG: Typography — .subheadline для secondary text (15pt)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                Spacer()
            }
        }
        // HIG: Spacing — 16pt padding для compact cards
        .padding(16)
        // HIG: Colors — semantic background с accent color overlay
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                // HIG: Colors — 8% opacity для subtle backgrounds
                .fill(Color.blue.opacity(0.08))
        )
        // HIG: Layout — stroke для выделения выбранного элемента
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                // HIG: Colors — 30% opacity для borders
                .stroke(Color.blue.opacity(0.3), lineWidth: 1.5)
        )
        // HIG: Accessibility — VoiceOver описание карточки
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Выбранная экспозиция: \(exposure.title). \(exposure.exposureDescription)")
    }
    
    // MARK: - Helper Functions
    
    private func anxietyColor(for value: Int) -> Color {
        // HIG: Colors — semantic colors для anxiety levels
        switch value {
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
        guard let exposure = selectedExposure else { return }
        
        // HIG: Haptics — medium impact для важных действий
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        do {
            let session = try dataManager.createSessionResult(
                for: exposure,
                anxietyBefore: Int(anxietyBefore)
            )
            currentSession = session
            showingActiveSession = true
        } catch {
            // HIG: Haptics — error feedback при ошибке
            let errorGenerator = UINotificationFeedbackGenerator()
            errorGenerator.notificationOccurred(.error)
            
            errorMessage = "Не удалось создать сеанс: \(error.localizedDescription)"
            showError = true
        }
    }
}

// MARK: - Custom Label Style

struct TrailingIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.title
            configuration.icon
        }
    }
}

extension LabelStyle where Self == TrailingIconLabelStyle {
    static var trailingIcon: TrailingIconLabelStyle { TrailingIconLabelStyle() }
}

// MARK: - Preview

#Preview {
    SessionView()
        .modelContainer(for: Exposure.self, inMemory: true)
}
