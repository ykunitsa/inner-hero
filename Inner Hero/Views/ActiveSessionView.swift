//
//  ActiveSessionView.swift
//  Inner Hero
//
//  Calm, focused exposure session screen for anxious users
//  Redesigned according to Apple HIG and Design Guidelines
//

import SwiftUI
import SwiftData
import Combine

// MARK: - Step Timer Controller

/// Контроллер для управления таймером конкретного шага
class StepTimerController {
    private(set) var isRunning: Bool = false
    private(set) var elapsedTime: TimeInterval = 0
    private(set) var isPaused: Bool = false
    
    private var cancellable: AnyCancellable?
    private var startTime: Date?
    private var pausedDuration: TimeInterval = 0
    
    // Callback для обновления UI
    var onTimeUpdate: ((TimeInterval) -> Void)?
    
    // Добавить этот метод для установки времени извне
    func setElapsedTime(_ time: TimeInterval) {
        elapsedTime = time
        pausedDuration = time
        onTimeUpdate?(time)
    }
    
    func start() {
        guard !isRunning else { return }
        
        isRunning = true
        isPaused = false
        startTime = Date()
        
        cancellable = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateElapsedTime()
            }
    }
    
    private func updateElapsedTime() {
        guard let startTime = startTime, isRunning, !isPaused else { return }
        elapsedTime = Date().timeIntervalSince(startTime) + pausedDuration
        onTimeUpdate?(elapsedTime)
    }
    
    func pause() {
        guard isRunning, !isPaused else { return }
        
        isPaused = true
        pausedDuration = elapsedTime
        cancellable?.cancel()
    }
    
    func resume() {
        guard isPaused else { return }
        
        isPaused = false
        startTime = Date()
        
        cancellable = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateElapsedTime()
            }
    }
    
    func reset() {
        stop()
        elapsedTime = 0
        pausedDuration = 0
        startTime = nil
        onTimeUpdate?(0)
    }
    
    func stop() {
        isRunning = false
        isPaused = false
        cancellable?.cancel()
        cancellable = nil
        startTime = nil
    }
    
    func remainingTime(for duration: TimeInterval) -> TimeInterval {
        return max(0, duration - elapsedTime)
    }
    
    func isExpired(for duration: TimeInterval) -> Bool {
        return elapsedTime >= duration
    }
    
    deinit {
        stop()
    }
}

// MARK: - Breathing Animation Controller

@Observable
class BreathingController {
    var isBreathing: Bool = false
    var breathPhase: BreathPhase = .inhale
    
    enum BreathPhase {
        case inhale, hold, exhale, rest
        
        var duration: TimeInterval {
            switch self {
            case .inhale: return 4.0
            case .hold: return 2.0
            case .exhale: return 6.0
            case .rest: return 2.0
            }
        }
        
        var instruction: String {
            switch self {
            case .inhale: return "Вдохните медленно..."
            case .hold: return "Задержите дыхание..."
            case .exhale: return "Выдохните медленно..."
            case .rest: return "Расслабьтесь..."
            }
        }
        
        var next: BreathPhase {
            switch self {
            case .inhale: return .hold
            case .hold: return .exhale
            case .exhale: return .rest
            case .rest: return .inhale
            }
        }
    }
}

// MARK: - Active Session View

struct ActiveSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let session: SessionResult
    let exposure: Exposure
    
    // Состояние
    @State private var notes: String = ""
    @State private var showingCompletion = false
    @State private var showingPauseModal = false
    @State private var showingInterruptAlert = false
    
    // Шаги
    @State private var completedSteps: Set<Int> = []
    @State private var stepTimers: [Int: StepTimerController] = [:]
    @State private var timerElapsedTimes: [Int: TimeInterval] = [:]
    
    // UI preferences
    @State private var showTimer: Bool = true
    @State private var showProgressBar: Bool = false
    @State private var showAllSteps: Bool = false
    
    // Breathing guide
    @State private var breathingController = BreathingController()
    @State private var showBreathingGuide = false
    @State private var breathScale: CGFloat = 0.6
    @State private var breathTimer: Timer?
    
    private var dataManager: DataManager {
        DataManager(modelContext: modelContext)
    }
    
    private var steps: [Step] {
        exposure.steps.sorted(by: { $0.order < $1.order })
    }
    
    // Автоматическое определение текущего шага: первый невыполненный
    private var currentStepIndex: Int {
        for (index, _) in steps.enumerated() {
            if !completedSteps.contains(index) {
                return index
            }
        }
        // Если все выполнены, вернуть последний шаг
        return max(0, steps.count - 1)
    }
    
    private var currentStep: Step? {
        guard currentStepIndex < steps.count else { return nil }
        return steps[currentStepIndex]
    }
    
    private var allStepsCompleted: Bool {
        completedSteps.count == steps.count
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 40) {
                // Progress indicator
                stepProgressIndicator
                
                // Current step
                if let step = currentStep {
                    currentStepLargeCard(step: step, index: currentStepIndex)
                } else if allStepsCompleted {
                    completionPrompt
                }
                
                // Session controls - moved up for better visibility
                sessionControlButtons
                
                // Timer controls (if step has timer)
                if let step = currentStep, step.hasTimer {
                    timerControlSection(for: step, at: currentStepIndex)
                }
                
                // Breathing guide
                breathingGuideSection
                
                // Navigation buttons
                navigationButtons
                
                // Optional: Show all steps toggle
                showAllStepsToggle
                
                // All steps (collapsible)
                if showAllSteps {
                    allStepsSection
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 60)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(exposure.title)
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear {
            setupSession()
        }
        .onDisappear {
            cleanupSession()
            stopBreathing()
        }
        .sheet(isPresented: $showingCompletion) {
            CompleteSessionView(
                session: session,
                notes: notes,
                onComplete: {
                    saveProgress()
                    dismiss()
                }
            )
        }
        .sheet(isPresented: $showingPauseModal) {
            PauseSessionModal(
                onResume: {
                    showingPauseModal = false
                },
                onEnd: {
                    cleanupSession()
                    dismiss()
                }
            )
            // HIG: Standard sheet detents
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .alert("Прервать сеанс?", isPresented: $showingInterruptAlert) {
            Button("Отмена", role: .cancel) { }
            Button("Прервать", role: .destructive) {
                cleanupSession()
                dismiss()
            }
        } message: {
            Text("Вы уверены, что хотите прервать сеанс? Прогресс не будет сохранён.")
        }
    }
    
    // MARK: - View Components
    
    private var stepProgressIndicator: some View {
        VStack(spacing: 8) {
            Text("Шаг \(currentStepIndex + 1) из \(steps.count)")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
                .accessibilityLabel("Шаг \(currentStepIndex + 1) из \(steps.count)")
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(Color(.systemGray5))
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(Color.teal)
                        .frame(
                            width: geometry.size.width * CGFloat(completedSteps.count) / CGFloat(max(steps.count, 1)),
                            height: 6
                        )
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: completedSteps.count)
                }
            }
            .frame(height: 6)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Прогресс")
            .accessibilityValue("\(completedSteps.count) из \(steps.count) шагов выполнено")
        }
    }
    
    private func currentStepLargeCard(step: Step, index: Int) -> some View {
        VStack(spacing: 20) {
            Text(step.text)
                .font(.title2.weight(.semibold))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .foregroundStyle(.primary)
            
            Button {
                completeCurrentStep()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: completedSteps.contains(index) ? "checkmark.circle.fill" : "circle")
                        .font(.body)
                        .accessibilityHidden(true)
                    Text(completedSteps.contains(index) ? "Шаг выполнен" : "Отметить выполненным")
                        .font(.headline)
                }
                .foregroundStyle(completedSteps.contains(index) ? .white : .white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(completedSteps.contains(index) ? Color.green : Color.teal)
                )
            }
            .accessibilityLabel(completedSteps.contains(index) ? "Шаг выполнен" : "Отметить шаг как выполненное")
            .accessibilityHint("Дважды нажмите чтобы отметить этот шаг")
            .animation(.spring(response: 0.3), value: completedSteps.contains(index))
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
        )
        .transition(.scale.combined(with: .opacity))
    }
    
    private var completionPrompt: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.green)
                .accessibilityHidden(true)
            
            VStack(spacing: 8) {
                Text("Все шаги выполнены!")
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)
                
                Text("Вы проделали отличную работу")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
        )
    }
    
    private var sessionControlButtons: some View {
        VStack(spacing: 12) {
            // Complete session button - primary
            Button {
                saveProgress()
                showingCompletion = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark")
                        .font(.subheadline)
                        .accessibilityHidden(true)
                    Text("Завершить сеанс")
                        .font(.headline)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.teal)
                )
            }
            .accessibilityLabel("Завершить сеанс")
            .accessibilityHint("Дважды нажмите чтобы завершить и сохранить результаты")
            
            // Pause button - secondary
            Button {
                showingPauseModal = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "pause")
                        .font(.subheadline)
                        .accessibilityHidden(true)
                    Text("Сделать паузу")
                        .font(.headline)
                }
                .foregroundStyle(.teal)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.teal.opacity(0.1))
                )
            }
            .accessibilityLabel("Сделать паузу")
            .accessibilityHint("Дважды нажмите чтобы приостановить сеанс")
        }
    }
    
    private var breathingGuideSection: some View {
        Group {
            if showBreathingGuide {
                breathingGuideView
                    .transition(.scale.combined(with: .opacity))
            } else {
                Button {
                    startBreathing()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "wind")
                            .font(.subheadline)
                            .accessibilityHidden(true)
                        Text("Дыхательное упражнение")
                            .font(.headline)
                    }
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(.secondarySystemGroupedBackground))
                    )
                }
                .accessibilityLabel("Дыхательное упражнение")
                .accessibilityHint("Дважды нажмите чтобы начать дыхательное упражнение")
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3), value: showBreathingGuide)
    }
    
    private var breathingGuideView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Color.teal.opacity(0.2), lineWidth: 2)
                    .frame(width: 140, height: 140)
                    .accessibilityHidden(true)
                
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.teal.opacity(0.4), .teal.opacity(0.1)],
                            center: .center,
                            startRadius: 15,
                            endRadius: 70
                        )
                    )
                    .frame(width: 140, height: 140)
                    .scaleEffect(breathScale)
                    .animation(.easeInOut(duration: breathingController.breathPhase.duration), value: breathScale)
                    .accessibilityHidden(true)
            }
            
            Text(breathingController.breathPhase.instruction)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .accessibilityLabel(breathingController.breathPhase.instruction)
            
            Button {
                stopBreathing()
            } label: {
                Text("Закрыть")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color(.tertiarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .accessibilityLabel("Закрыть упражнение на дыхание")
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
        )
    }
    
    private func timerControlSection(for step: Step, at index: Int) -> some View {
        let timerController = getStepTimer(index)
        let duration = TimeInterval(step.timerDuration)
        let elapsedTime = timerElapsedTimes[index] ?? 0
        let remaining = max(0, duration - elapsedTime)
        let isExpired = elapsedTime >= duration
        
        return VStack(spacing: 16) {
            // Timer display toggle
            HStack(spacing: 12) {
                Button {
                    withAnimation {
                        showTimer.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: showTimer ? "eye.fill" : "eye.slash.fill")
                            .font(.caption)
                        Text(showTimer ? "Скрыть" : "Показать")
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }
                .frame(minHeight: 44)
                .accessibilityLabel(showTimer ? "Скрыть таймер" : "Показать таймер")
                
                Spacer()
                
                if showTimer {
                    Button {
                        withAnimation {
                            showProgressBar.toggle()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: showProgressBar ? "chart.bar.fill" : "timer")
                                .font(.caption)
                            Text(showProgressBar ? "Прогресс" : "Время")
                                .font(.caption)
                        }
                        .foregroundStyle(.secondary)
                    }
                    .frame(minHeight: 44)
                    .accessibilityLabel(showProgressBar ? "Показать время" : "Показать прогресс")
                }
            }
            
            if showTimer {
                VStack(spacing: 20) {
                    if !showProgressBar {
                        // Time display
                        VStack(spacing: 4) {
                            Text(isExpired ? "Готово!" : "Осталось")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            Text(formatTime(remaining))
                                .font(.system(.title, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundStyle(timerColor(for: remaining, duration: duration))
                                .monospacedDigit()
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Осталось времени: \(formatTime(remaining))")
                    } else {
                        // Progress bar view
                        VStack(spacing: 8) {
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .fill(Color(.systemGray5))
                                        .frame(height: 32)
                                    
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .fill(timerColor(for: remaining, duration: duration))
                                        .frame(
                                            width: geometry.size.width * (remaining / duration),
                                            height: 32
                                        )
                                        .animation(.linear(duration: 0.1), value: remaining)
                                }
                            }
                            .frame(height: 32)
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel("Прогресс таймера")
                            .accessibilityValue("\(Int((remaining / duration) * 100)) процентов")
                            
                            Text("\(Int((remaining / duration) * 100))%")
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(timerColor(for: remaining, duration: duration))
                        }
                    }
                    
                    // Timer controls
                    HStack(spacing: 12) {
                        // Start/Pause button
                        Button {
                            if timerController.isRunning && !timerController.isPaused {
                                timerController.pause()
                            } else if timerController.isPaused {
                                timerController.resume()
                            } else {
                                timerController.start()
                            }
                        } label: {
                            VStack(spacing: 6) {
                                Image(systemName: timerController.isRunning && !timerController.isPaused ? "pause.circle.fill" : "play.circle.fill")
                                    .font(.system(size: 24))
                                    .accessibilityHidden(true)
                                Text(timerController.isRunning && !timerController.isPaused ? "Пауза" : (timerController.isPaused ? "Продолжить" : "Старт"))
                                    .font(.subheadline.weight(.medium))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 64)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.teal)
                            )
                        }
                        .accessibilityLabel(timerController.isRunning && !timerController.isPaused ? "Пауза" : (timerController.isPaused ? "Продолжить таймер" : "Запустить таймер"))
                        
                        // Reset button
                        Button {
                            timerController.reset()
                        } label: {
                            VStack(spacing: 6) {
                                Image(systemName: "arrow.counterclockwise.circle.fill")
                                    .font(.system(size: 24))
                                    .accessibilityHidden(true)
                                Text("Сброс")
                                    .font(.subheadline.weight(.medium))
                            }
                            .foregroundStyle(.teal)
                            .frame(maxWidth: .infinity)
                            .frame(height: 64)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.teal.opacity(0.1))
                            )
                        }
                        .accessibilityLabel("Сбросить таймер")
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(.secondarySystemGroupedBackground))
                        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
                )
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3), value: showTimer)
    }
    
    private var navigationButtons: some View {
        HStack(spacing: 12) {
            // Previous step button
            Button {
                goToPreviousStep()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.subheadline)
                        .accessibilityHidden(true)
                    Text("Назад")
                        .font(.subheadline.weight(.medium))
                }
                .foregroundStyle(currentStepIndex > 0 ? .teal : .secondary)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
            }
            .disabled(currentStepIndex == 0)
            .accessibilityLabel("Предыдущий шаг")
            .accessibilityHint(currentStepIndex > 0 ? "Дважды нажмите чтобы вернуться к предыдущему шагу" : "Недоступно, вы на первом шаге")
            
            // Next step button
            Button {
                goToNextStep()
            } label: {
                HStack(spacing: 6) {
                    Text("Далее")
                        .font(.subheadline.weight(.medium))
                    Image(systemName: "chevron.right")
                        .font(.subheadline)
                        .accessibilityHidden(true)
                }
                .foregroundStyle(currentStepIndex < steps.count - 1 ? .teal : .secondary)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
            }
            .disabled(currentStepIndex >= steps.count - 1)
            .accessibilityLabel("Следующий шаг")
            .accessibilityHint(currentStepIndex < steps.count - 1 ? "Дважды нажмите чтобы перейти к следующему шагу" : "Недоступно, вы на последнем шаге")
        }
    }
    
    private var showAllStepsToggle: some View {
        Button {
            withAnimation {
                showAllSteps.toggle()
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: showAllSteps ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                    .font(.body)
                    .accessibilityHidden(true)
                Text(showAllSteps ? "Скрыть все шаги" : "Показать все шаги")
                    .font(.headline)
                Spacer()
                Text("\(completedSteps.count)/\(steps.count)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .foregroundStyle(.teal)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
        .frame(minHeight: 44)
        .accessibilityLabel(showAllSteps ? "Скрыть все шаги" : "Показать все шаги")
        .accessibilityValue("\(completedSteps.count) из \(steps.count) шагов выполнено")
    }
    
    private var allStepsSection: some View {
        VStack(spacing: 12) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                compactStepRow(step: step, index: index)
            }
        }
        .transition(.scale.combined(with: .opacity))
    }
    
    private func compactStepRow(step: Step, index: Int) -> some View {
        let isCompleted = completedSteps.contains(index)
        let isCurrent = index == currentStepIndex
        
        return HStack(spacing: 16) {
            // Step number indicator
            ZStack {
                Circle()
                    .fill(isCompleted ? Color.green : (isCurrent ? Color.teal : Color.gray.opacity(0.3)))
                    .frame(width: 36, height: 36)
                
                if isCompleted {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.white)
                        .font(.subheadline.weight(.bold))
                        .accessibilityHidden(true)
                } else {
                    Text("\(index + 1)")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(isCurrent ? .white : .primary)
                }
            }
            .accessibilityHidden(true)
            
            // Step content
            VStack(alignment: .leading, spacing: 6) {
                Text(step.text)
                    .font(.body)
                    .foregroundStyle(isCompleted ? .secondary : .primary)
                    .strikethrough(isCompleted)
                
                if step.hasTimer {
                    HStack(spacing: 6) {
                        Image(systemName: "timer")
                            .font(.caption)
                            .accessibilityHidden(true)
                        Text(formatTime(TimeInterval(step.timerDuration)))
                            .font(.caption.weight(.medium))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(.orange))
                }
            }
            
            Spacer()
            
            // Toggle button
            Button {
                toggleStepCompletion(index)
            } label: {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isCompleted ? .green : .gray)
            }
            .frame(minWidth: 44, minHeight: 44)
            .accessibilityLabel(isCompleted ? "Отменить выполнение шага" : "Отметить шаг как выполненное")
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isCurrent ? Color.teal.opacity(0.08) : Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(isCurrent ? Color.teal : Color.clear, lineWidth: 2)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Шаг \(index + 1): \(step.text)")
        .accessibilityValue(isCompleted ? "Выполнено" : (isCurrent ? "Текущий шаг" : "Не выполнено"))
    }
    
    // MARK: - Helper Functions
    
    private func setupSession() {
        // Восстановить состояние из SessionResult
        completedSteps = Set(session.completedStepIndices)
        
        // Восстановить таймеры шагов
        for (index, time) in session.stepTimings {
            let timer = getStepTimer(index)
            timer.setElapsedTime(time) // Используем новый метод
            timerElapsedTimes[index] = time // Также обновляем UI состояние
        }
    }
    
    private func cleanupSession() {
        // Остановить все таймеры шагов
        for (_, timer) in stepTimers {
            timer.stop()
        }
        stopBreathing()
    }
    
    private func saveProgress() {
        // Сохранить выполненные шаги
        session.completedStepIndices = Array(completedSteps).sorted()
        
        // Сохранить время для каждого шага
        for (index, timer) in stepTimers {
            if timer.elapsedTime > 0 {
                session.setStepTime(index, time: timer.elapsedTime)
            }
        }
        
        // Сохранить заметки
        if !notes.isEmpty {
            session.notes = notes
        }
        
        // Сохранить контекст
        try? modelContext.save()
    }
    
    private func completeCurrentStep() {
        triggerSuccessHaptic()
        toggleStepCompletion(currentStepIndex)
    }
    
    private func toggleStepCompletion(_ index: Int) {
        withAnimation(.spring(response: 0.3)) {
            if completedSteps.contains(index) {
                completedSteps.remove(index)
                session.markStepIncomplete(index)
            } else {
                completedSteps.insert(index)
                session.markStepCompleted(index)
                triggerSuccessHaptic()
                
                // Остановить таймер шага при его завершении
                if let timer = stepTimers[index] {
                    timer.stop()
                }
            }
        }
        
        saveProgress()
    }
    
    private func goToNextStep() {
        guard currentStepIndex < steps.count - 1 else { return }
        
        // Mark current step as completed if not already
        if !completedSteps.contains(currentStepIndex) {
            toggleStepCompletion(currentStepIndex)
        }
        
        triggerHaptic(.light)
    }
    
    private func goToPreviousStep() {
        guard currentStepIndex > 0 else { return }
        
        // Mark current step as incomplete to go back
        if completedSteps.contains(currentStepIndex - 1) {
            toggleStepCompletion(currentStepIndex - 1)
        }
        
        triggerHaptic(.light)
    }
    
    // MARK: - Breathing Guide Functions
    
    private func startBreathing() {
        withAnimation(.spring(response: 0.4)) {
            showBreathingGuide = true
        }
        
        breathingController.isBreathing = true
        animateBreathingCycle()
    }
    
    private func stopBreathing() {
        breathTimer?.invalidate()
        breathTimer = nil
        breathingController.isBreathing = false
        
        withAnimation(.spring(response: 0.4)) {
            showBreathingGuide = false
            breathScale = 0.6
        }
    }
    
    private func animateBreathingCycle() {
        guard breathingController.isBreathing else { return }
        
        let phase = breathingController.breathPhase
        let duration = phase.duration
        
        // Animate scale based on phase
        withAnimation(.easeInOut(duration: duration)) {
            switch phase {
            case .inhale:
                breathScale = 1.0
            case .hold:
                breathScale = 1.0
            case .exhale:
                breathScale = 0.6
            case .rest:
                breathScale = 0.6
            }
        }
        
        // Trigger haptic at phase transitions
        if phase == .inhale || phase == .exhale {
            triggerHaptic(.light)
        }
        
        // Schedule next phase
        breathTimer?.invalidate()
        breathTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { _ in
            self.breathingController.breathPhase = phase.next
            self.animateBreathingCycle()
        }
    }
    
    // MARK: - Haptic Feedback
    
    private func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    private func triggerSuccessHaptic() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    // MARK: - Helper Functions
    
    private func getStepTimer(_ index: Int) -> StepTimerController {
        if let existing = stepTimers[index] {
            return existing
        }
        let newTimer = StepTimerController()
        newTimer.onTimeUpdate = { [self] time in
            timerElapsedTimes[index] = time
        }
        stepTimers[index] = newTimer
        return newTimer
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func timerColor(for remaining: TimeInterval, duration: TimeInterval) -> Color {
        let percentage = remaining / duration
        if percentage > 0.5 {
            return .green
        } else if percentage > 0.2 {
            return .orange
        } else {
            return .red
        }
    }
}

// MARK: - Pause Session Modal

struct PauseSessionModal: View {
    let onResume: () -> Void
    let onEnd: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            // Icon and header section
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.teal.opacity(0.15))
                        .frame(width: 64, height: 64)
                    
                    Image(systemName: "heart.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.teal)
                }
                .accessibilityHidden(true)
                
                VStack(spacing: 8) {
                    Text("Вы делаете отлично!")
                        .font(.title3.weight(.semibold))
                        .multilineTextAlignment(.center)
                    
                    Text("Вы уже проделали важную работу. Можете отдохнуть в любое время.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            .padding(.top, 24)
            
            // Supportive messages
            VStack(alignment: .leading, spacing: 10) {
                supportiveMessage(icon: "checkmark.circle.fill", text: "Делайте перерывы когда нужно")
                supportiveMessage(icon: "heart.circle.fill", text: "Забота о себе - это не слабость")
                supportiveMessage(icon: "star.circle.fill", text: "Каждый шаг - это прогресс")
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            // Action buttons
            VStack(spacing: 12) {
                // Primary action - Resume
                Button {
                    onResume()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                            .font(.subheadline)
                            .accessibilityHidden(true)
                        Text("Продолжить сеанс")
                            .font(.headline)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.teal)
                    )
                }
                .accessibilityLabel("Продолжить сеанс")
                .accessibilityHint("Дважды нажмите чтобы вернуться к сеансу")
                
                // Secondary action - End
                Button {
                    onEnd()
                } label: {
                    Text("Завершить на сегодня")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color(.tertiarySystemBackground))
                        )
                }
                .accessibilityLabel("Завершить на сегодня")
                .accessibilityHint("Дважды нажмите чтобы завершить сеанс без сохранения")
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground))
    }
    
    private func supportiveMessage(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(.teal)
                .frame(width: 20)
                .accessibilityHidden(true)
            
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
            
            Spacer()
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

// MARK: - Complete Session View

struct CompleteSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let session: SessionResult
    let notes: String
    let onComplete: () -> Void
    
    @State private var anxietyAfter: Double = 5
    @State private var finalNotes: String = ""
    @State private var showError = false
    @State private var errorMessage = ""
    
    private var dataManager: DataManager {
        DataManager(modelContext: modelContext)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.teal)
                            .accessibilityHidden(true)
                        
                        Text("Завершение сеанса")
                            .font(.title3.weight(.semibold))
                    }
                    .padding(.top, 20)
                    
                    // Session Summary
                    sessionSummaryCard
                    
                    // Anxiety After section
                    VStack(alignment: .leading, spacing: 16) {
                        Label("Уровень тревоги после сеанса", systemImage: "gauge")
                            .font(.headline)
                        
                        Text("Оцените ваш уровень тревоги сейчас (0–10)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        VStack(spacing: 16) {
                            HStack {
                                Spacer()
                                Text("\(Int(anxietyAfter))")
                                    .font(.system(.title, design: .rounded))
                                    .fontWeight(.bold)
                                    .foregroundStyle(anxietyColor(for: Int(anxietyAfter)))
                                    .monospacedDigit()
                                Spacer()
                            }
                            
                            Slider(value: $anxietyAfter, in: 0...10, step: 1)
                                .tint(anxietyColor(for: Int(anxietyAfter)))
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color(.secondarySystemGroupedBackground))
                        )
                    }
                    .padding(.horizontal, 20)
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel("Уровень тревоги после сеанса")
                    
                    // Progress
                    progressCard
                    
                    // Additional Notes section
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Дополнительные заметки", systemImage: "note.text")
                            .font(.headline)
                        
                        TextEditor(text: $finalNotes)
                            .frame(minHeight: 100)
                            .padding(10)
                            .background(Color(.tertiarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(.secondarySystemGroupedBackground))
                    )
                    .padding(.horizontal, 20)
                    
                    // Primary action button
                    Button {
                        completeSession()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark")
                                .font(.subheadline)
                            Text("Сохранить результат")
                                .font(.headline)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.teal)
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                    .accessibilityLabel("Сохранить результат сеанса")
                    .accessibilityHint("Дважды нажмите чтобы сохранить и завершить")
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Завершение")
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
        .onAppear {
            finalNotes = notes
        }
    }
    
    private var sessionSummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Результаты сеанса", systemImage: "chart.bar.fill")
                .font(.headline)
            
            HStack(spacing: 16) {
                // Stats card - completed steps
                VStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.teal)
                        .accessibilityHidden(true)
                    Text("\(session.completedStepIndices.count)")
                        .font(.title2.weight(.bold))
                    Text("шагов")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(session.completedStepIndices.count) шагов выполнено")
                
                Divider()
                
                // Stats card - time spent
                VStack(spacing: 6) {
                    Image(systemName: "clock.fill")
                        .font(.title3)
                        .foregroundStyle(.teal)
                        .accessibilityHidden(true)
                    Text(formatTime(session.getTotalStepsTime()))
                        .font(.title3.weight(.bold))
                        .monospacedDigit()
                    Text("время")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Время выполнения: \(formatTime(session.getTotalStepsTime()))")
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
        )
        .padding(.horizontal, 20)
    }
    
    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Прогресс", systemImage: "chart.line.uptrend.xyaxis")
                .font(.headline)
            
            HStack(spacing: 12) {
                // Before anxiety value
                VStack(spacing: 4) {
                    Text("До")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(session.anxietyBefore)")
                        .font(.title2.weight(.bold))
                }
                
                Image(systemName: "arrow.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .accessibilityHidden(true)
                
                // After anxiety value
                VStack(spacing: 4) {
                    Text("После")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(Int(anxietyAfter))")
                        .font(.title2.weight(.bold))
                }
                
                Spacer()
                
                // Change indicator
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Изменение")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    let change = session.anxietyBefore - Int(anxietyAfter)
                    Text("\(change > 0 ? "-" : "+")\(abs(change))")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(change > 0 ? .green : (change < 0 ? .red : .gray))
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
        )
        .padding(.horizontal, 20)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Прогресс тревоги")
        .accessibilityValue("До: \(session.anxietyBefore), После: \(Int(anxietyAfter)), Изменение: \(session.anxietyBefore - Int(anxietyAfter))")
    }
    
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
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func completeSession() {
        do {
            let combinedNotes = notes.isEmpty ? finalNotes : notes + "\n\n" + finalNotes
            try dataManager.completeSession(
                session,
                anxietyAfter: Int(anxietyAfter),
                notes: combinedNotes.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            dismiss()
            onComplete()
        } catch {
            errorMessage = "Не удалось сохранить результат: \(error.localizedDescription)"
            showError = true
        }
    }
}

#Preview("Active Session") {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Exposure.self, SessionResult.self, configurations: config)
        let context = container.mainContext
        
        // Create sample data
        let exposure = Exposure(
            title: "Преодоление страха пауков",
            exposureDescription: "Постепенная экспозиция к страху пауков",
            steps: [
                Step(text: "Посмотрите на фотографию паука", hasTimer: true, timerDuration: 120, order: 0),
                Step(text: "Посмотрите видео с пауками", hasTimer: true, timerDuration: 180, order: 1),
                Step(text: "Представьте, что держите паука", hasTimer: false, timerDuration: 0, order: 2)
            ]
        )
        
        let session = SessionResult(
            exposure: exposure,
            anxietyBefore: 7
        )
        
        context.insert(exposure)
        context.insert(session)
        
        return NavigationStack {
            ActiveSessionView(session: session, exposure: exposure)
                .modelContainer(container)
        }
    } catch {
        return Text("Preview Error: \(error.localizedDescription)")
    }
}


