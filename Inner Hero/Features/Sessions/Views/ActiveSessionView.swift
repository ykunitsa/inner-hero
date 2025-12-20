import SwiftUI
import SwiftData

// MARK: - Compact Timer View

private struct CompactTimerView: View {
    @ObservedObject var timerController: StepTimerController
    let duration: TimeInterval
    let formatTime: (TimeInterval) -> String
    
    private var elapsedTime: TimeInterval {
        timerController.elapsedTime
    }
    
    private var remaining: TimeInterval {
        max(0, duration - elapsedTime)
    }
    
    private var progress: Double {
        duration > 0 ? min(1.0, elapsedTime / duration) : 0.0
    }
    
    private var isTimerRunning: Bool {
        timerController.isRunning && !timerController.isPaused
    }
    
    private var isTimerPaused: Bool {
        timerController.isPaused
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(Color.white.opacity(0.3))
                        .frame(height: 4)
                    
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [.blue.opacity(0.9), .cyan.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: 4)
                        .animation(.linear(duration: 0.1), value: progress)
                }
            }
            .frame(height: 4)
            .padding(.horizontal, 12)
            .padding(.top, 8)
            
            // Timer and controls
            HStack(spacing: 12) {
                // Timer display
                Text(formatTime(remaining))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .monospacedDigit()
                    .accessibilityLabel("Осталось времени: \(formatTime(remaining))")
                
                Spacer()
                
                // Controls
                HStack(spacing: 8) {
                    // Play/Pause button
                    Button {
                        if isTimerRunning {
                            timerController.pause()
                        } else if isTimerPaused {
                            timerController.resume()
                        } else {
                            timerController.start()
                        }
                    } label: {
                        Image(systemName: isTimerRunning ? "pause.fill" : "play.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.blue, .cyan],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )
                            .shadow(color: .blue.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                    .accessibilityLabel(isTimerRunning ? "Пауза" : (isTimerPaused ? "Продолжить таймер" : "Запустить таймер"))
                    
                    // Reset button
                    Button {
                        timerController.reset()
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(TextColors.secondary)
                            .frame(width: 36, height: 36)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.5))
                            )
                    }
                    .accessibilityLabel("Сбросить таймер")
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .padding(.bottom, 8)
        }
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.95, green: 0.97, blue: 1.0),
                            Color(red: 0.92, green: 0.95, blue: 0.98)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
        )
    }
}

// MARK: - Timer Section Content

private struct TimerSectionContent: View {
    @ObservedObject var timerController: StepTimerController
    let duration: TimeInterval
    let formatTime: (TimeInterval) -> String
    
    private var elapsedTime: TimeInterval {
        timerController.elapsedTime
    }
    
    private var remaining: TimeInterval {
        max(0, duration - elapsedTime)
    }
    
    private var isExpired: Bool {
        elapsedTime >= duration
    }
    
    private var isTimerRunning: Bool {
        timerController.isRunning && !timerController.isPaused
    }
    
    private var isTimerPaused: Bool {
        timerController.isPaused
    }
    
    private var progress: Double {
        duration > 0 ? min(1.0, elapsedTime / duration) : 0.0
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress bar at the top of timer panel
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(Color.white.opacity(0.3))
                        .frame(height: 4)
                    
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [.blue.opacity(0.9), .cyan.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: 4)
                        .animation(.linear(duration: 0.1), value: progress)
                }
            }
            .frame(height: 4)
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            // Timer panel content
            HStack(spacing: 20) {
                // Timer display
                VStack(alignment: .leading, spacing: 6) {
                    Text(formatTime(remaining))
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .monospacedDigit()
                        .fixedSize(horizontal: true, vertical: false)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(isExpired ? "Время истекло" : "Осталось времени: \(formatTime(remaining))")
                
                Spacer()
                
                // Timer controls
                HStack(spacing: 12) {
                    // Play/Pause button
                    Button {
                        if isTimerRunning {
                            timerController.pause()
                        } else if isTimerPaused {
                            timerController.resume()
                        } else {
                            timerController.start()
                        }
                    } label: {
                        Image(systemName: isTimerRunning ? "pause.fill" : "play.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.white)
                            .frame(width: 52, height: 52)
                            .background(
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.blue, .cyan],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )
                            .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .accessibilityLabel(isTimerRunning ? "Пауза" : (isTimerPaused ? "Продолжить таймер" : "Запустить таймер"))
                    
                    // Reset button
                    Button {
                        timerController.reset()
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(TextColors.secondary)
                            .frame(width: 52, height: 52)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.5))
                            )
                    }
                    .accessibilityLabel("Сбросить таймер")
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 20)
        }
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.95, green: 0.97, blue: 1.0),
                            Color(red: 0.92, green: 0.95, blue: 0.98)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
}

// MARK: - Active Session View

struct ActiveSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let session: ExposureSessionResult
    let exposure: Exposure
    
    @State private var notes: String = ""
    @State private var showingCompletion = false
    @State private var showingPauseModal = false
    @State private var showingInterruptAlert = false
    
    @State private var completedSteps: Set<Int> = []
    @State private var stepTimers: [Int: StepTimerController] = [:]
    @State private var timerElapsedTimes: [Int: TimeInterval] = [:]
    
    @State private var showTimer: Bool = true
    @State private var showProgressBar: Bool = false
    @State private var showAllSteps: Bool = false
    
    private var dataManager: DataManager {
        DataManager(modelContext: modelContext)
    }
    
    private var steps: [ExposureStep] {
        exposure.steps.sorted(by: { $0.order < $1.order })
    }
    
    private var currentStepIndex: Int {
        for (index, _) in steps.enumerated() {
            if !completedSteps.contains(index) {
                return index
            }
        }
        return max(0, steps.count - 1)
    }
    
    private var currentStep: ExposureStep? {
        guard currentStepIndex < steps.count else { return nil }
        return steps[currentStepIndex]
    }
    
    private var allStepsCompleted: Bool {
        completedSteps.count == steps.count
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Fixed progress indicator at the top
            stepProgressIndicator
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 20)
                .background(
                    LinearGradient(
                        colors: [
                            Color(red: 0.95, green: 0.97, blue: 1.0),
                            Color(red: 0.92, green: 0.95, blue: 0.98)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // Scrollable content
            GeometryReader { geometry in
                ScrollView {
                    LazyVStack(spacing: 28) {
                        if showAllSteps {
                            allStepsSection
                        } else {
                            if let step = currentStep {
                                currentStepLargeCard(step: step, index: currentStepIndex)
                                    .frame(minHeight: geometry.size.height * 0.6)
                            } else if allStepsCompleted {
                                completionPrompt
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 60)
                    .frame(minHeight: geometry.size.height)
                }
            }
        }
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.97, blue: 1.0),
                    Color(red: 0.92, green: 0.95, blue: 0.98)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            // Back button (top left)
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.body.weight(.medium))
                            .foregroundStyle(TextColors.toolbar)
                    }
                }
                .accessibilityLabel("Вернуться на главную")
            }
            
            // Close/Pause button (top right)
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingPauseModal = true
                } label: {
                    Image(systemName: "xmark")
                        .font(.title3)
                        .foregroundStyle(TextColors.toolbar)
                }
                .accessibilityLabel("Пауза")
            }
            
            ToolbarItem(placement: .principal) {
                Text(exposure.title)
                    .font(.headline)
                    .foregroundStyle(TextColors.toolbar)
            }
            
            // Left side bottom toolbar
            ToolbarItem(placement: .bottomBar) {
                Button {
                    withAnimation {
                        showAllSteps.toggle()
                    }
                } label: {
                    Image(systemName: showAllSteps ? "list.bullet.circle.fill" : "list.bullet.circle")
                        .font(.title2)
                        .foregroundStyle(TextColors.toolbar)
                }
                .accessibilityLabel(showAllSteps ? "Скрыть все шаги" : "Показать все шаги")
            }
            
            // Right side buttons grouped
            ToolbarItemGroup(placement: .bottomBar) {
                Spacer()
                
                // Back button
                Button {
                    goToPreviousStep()
                } label: {
                    Image(systemName: "chevron.left.circle")
                        .font(.title2)
                        .foregroundStyle(TextColors.toolbar)
                }
                .disabled(currentStepIndex == 0)
                .accessibilityLabel("Предыдущий шаг")
                
                // Complete button or Finish flag
                Button {
                    if currentStepIndex == steps.count - 1 && !completedSteps.contains(currentStepIndex) {
                        finishSession()
                    } else {
                        completeCurrentStep()
                    }
                } label: {
                    if currentStepIndex == steps.count - 1 && !completedSteps.contains(currentStepIndex) {
                        Image(systemName: "flag.pattern.checkered.2.crossed")
                            .font(.title2)
                            .foregroundStyle(.green)
                    } else {
                        Image(systemName: completedSteps.contains(currentStepIndex) ? "checkmark.circle.fill" : "checkmark.circle")
                            .font(.title2)
                            .foregroundStyle(completedSteps.contains(currentStepIndex) ? .green : TextColors.toolbar)
                    }
                }
                .disabled(allStepsCompleted)
                .accessibilityLabel(currentStepIndex == steps.count - 1 && !completedSteps.contains(currentStepIndex) ? "Завершить сессию" : "Завершить текущий шаг")
            }
        }
        .onAppear {
            setupSession()
        }
        .onDisappear {
            cleanupSession()
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
    
    private var stepProgressIndicator: some View {
        VStack(spacing: 12) {
            Text("Шаг \(currentStepIndex + 1) из \(steps.count)")
                .font(.caption.weight(.medium))
                .foregroundStyle(TextColors.secondary)
                .accessibilityLabel("Шаг \(currentStepIndex + 1) из \(steps.count)")
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                        .fill(Color(.systemGray6))
                        .frame(height: 5)
                    
                    RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: geometry.size.width * CGFloat(completedSteps.count) / CGFloat(max(steps.count, 1)),
                            height: 5
                        )
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: completedSteps.count)
                }
            }
            .frame(height: 5)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Прогресс")
            .accessibilityValue("\(completedSteps.count) из \(steps.count) шагов выполнено")
        }
    }
    
    private func currentStepLargeCard(step: ExposureStep, index: Int) -> some View {
        let isCompleted = completedSteps.contains(index)
        let timerController = step.hasTimer ? getStepTimer(index) : nil
        let duration = step.hasTimer ? TimeInterval(step.timerDuration) : 0
        // Use elapsedTime directly from controller for reactive updates
        let elapsedTime = timerController?.elapsedTime ?? (timerElapsedTimes[index] ?? 0)
        let remaining = max(0, duration - elapsedTime)
        let isExpired = step.hasTimer && elapsedTime >= duration
        // Read timer state directly from controller to ensure UI updates
        let isTimerRunning = timerController?.isRunning == true && timerController?.isPaused == false
        let isTimerPaused = timerController?.isPaused == true
        
        return GeometryReader { geometry in
            VStack(spacing: 0) {
                // Top section: step text (2/3 of card)
                ZStack(alignment: .center) {
                    // Step text (centered vertically and horizontally)
                    Text(step.text)
                        .font(.system(size: 32, weight: .semibold))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .foregroundStyle(TextColors.primary)
                        .lineSpacing(8)
                        .padding(.horizontal, 40)
                    
                    // Step number in top-left corner
                    VStack {
                        HStack {
                            Text("\(index + 1)")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundStyle(.blue)
                                .frame(width: 60, height: 60)
                                .background(Circle().fill(Color.blue.opacity(0.1)))
                            
                            Spacer()
                        }
                        
                        Spacer()
                    }
                    .padding(24)
                }
                .frame(maxWidth: .infinity, maxHeight: step.hasTimer ? geometry.size.height * 0.67 : .infinity)
                .background(Color(.systemBackground))
                
                // Timer panel at bottom (1/3 of card)
                if step.hasTimer, let timerController = timerController {
                    timerSectionView(
                        timerController: timerController,
                        duration: duration,
                        elapsedTime: elapsedTime,
                        remaining: remaining,
                        isExpired: isExpired,
                        isTimerRunning: isTimerRunning,
                        isTimerPaused: isTimerPaused
                    )
                    .frame(height: geometry.size.height * 0.33)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: Color.black.opacity(0.08), radius: 20, x: 0, y: 8)
            .transition(.scale.combined(with: .opacity))
            .animation(.spring(response: 0.3), value: isCompleted)
        }
    }
    
    private var completionPrompt: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.green, .green.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .accessibilityHidden(true)
            
            VStack(spacing: 6) {
                Text("Все шаги выполнены!")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(TextColors.primary)
                    .multilineTextAlignment(.center)
                
                Text("Вы проделали отличную работу")
                    .font(.caption)
                    .foregroundStyle(TextColors.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.systemBackground))
        )
    }
    
    
    private func timerControlSection(for step: ExposureStep, at index: Int) -> some View {
        let timerController = getStepTimer(index)
        let duration = TimeInterval(step.timerDuration)
        let elapsedTime = timerElapsedTimes[index] ?? 0
        let remaining = max(0, duration - elapsedTime)
        let isExpired = elapsedTime >= duration
        
        return VStack {
            if showTimer {
                VStack(spacing: 24) {
                    // Large timer display
                    VStack(spacing: 8) {
                        Text(formatTime(remaining))
                            .font(.system(size: 56, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: isExpired ? [.green, .green.opacity(0.8)] : [.blue, .indigo],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .monospacedDigit()
                        
                        Text(isExpired ? "Время истекло" : "")
                            .font(.caption)
                            .foregroundStyle(TextColors.secondary)
                            .frame(height: 16)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(isExpired ? "Время истекло" : "Осталось времени: \(formatTime(remaining))")
                    
                    // Minimal progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                                .fill(Color(.systemGray6))
                                .frame(height: 5)
                            
                            RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: isExpired ? [.green, .green.opacity(0.8)] : [.blue, .indigo],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(
                                    width: geometry.size.width * (remaining / duration),
                                    height: 5
                                )
                                .animation(.linear(duration: 0.1), value: remaining)
                        }
                    }
                    .frame(height: 5)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Прогресс таймера")
                    .accessibilityValue("\(Int((remaining / duration) * 100)) процентов")
                    
                    // Timer controls
                    Button {
                        if timerController.isRunning && !timerController.isPaused {
                            timerController.pause()
                        } else if timerController.isPaused {
                            timerController.resume()
                        } else {
                            timerController.start()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: timerController.isRunning && !timerController.isPaused ? "pause.fill" : "play.fill")
                                .font(.body)
                                .accessibilityHidden(true)
                            Text(timerController.isRunning && !timerController.isPaused ? "Пауза" : (timerController.isPaused ? "Продолжить" : "Старт"))
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [.blue, .indigo],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                    }
                    .accessibilityLabel(timerController.isRunning && !timerController.isPaused ? "Пауза" : (timerController.isPaused ? "Продолжить таймер" : "Запустить таймер"))
                }
                .padding(28)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color(.systemBackground))
                )
                .transition(.scale.combined(with: .opacity))
            }
            
            // Toggle and reset controls
            HStack(spacing: 12) {
                Button {
                    withAnimation {
                        showTimer.toggle()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: showTimer ? "eye.slash.fill" : "eye.fill")
                            .font(.caption)
                        Text(showTimer ? "Скрыть" : "Показать")
                            .font(.caption.weight(.medium))
                    }
                    .foregroundStyle(TextColors.secondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color(.systemGray6))
                    )
                }
                .accessibilityLabel(showTimer ? "Скрыть таймер" : "Показать таймер")
                
                Button {
                    timerController.reset()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.caption)
                        Text("Сброс")
                            .font(.caption.weight(.medium))
                    }
                    .foregroundStyle(TextColors.secondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color(.systemGray6))
                    )
                }
                .accessibilityLabel("Сбросить таймер")
            }
        }
        .animation(.spring(response: 0.3), value: showTimer)
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
                    .foregroundStyle(TextColors.secondary)
                    .accessibilityHidden(true)
                Text(showAllSteps ? "Скрыть все шаги" : "Показать все шаги")
                    .font(.system(size: 15, weight: .medium))
                Spacer()
                Text("\(completedSteps.count)/\(steps.count)")
                    .font(.caption)
                    .foregroundStyle(TextColors.secondary)
            }
            .foregroundStyle(TextColors.primary)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.systemGray6))
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
    
    private func compactStepRow(step: ExposureStep, index: Int) -> some View {
        let isCompleted = completedSteps.contains(index)
        let isCurrent = index == currentStepIndex
        
        return compactStepRowContent(
            step: step,
            index: index,
            isCompleted: isCompleted,
            isCurrent: isCurrent
        )
    }
    
    @ViewBuilder
    private func compactStepRowContent(step: ExposureStep, index: Int, isCompleted: Bool, isCurrent: Bool) -> some View {
        let backgroundColor = LinearGradient(
                colors: [Color(.systemBackground), Color(.systemBackground)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        let strokeColor = isCurrent ? Color.blue.opacity(0.3) : Color.clear
        let accessibilityValue = isCompleted ? "Выполнено" : (isCurrent ? "Текущий шаг" : "Не выполнено")
        
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 16) {
                compactStepCircleIndicator(
                    index: index,
                    isCompleted: isCompleted,
                    isCurrent: isCurrent
                )
                
                compactStepTextContent(
                    step: step,
                    index: index,
                    isCompleted: isCompleted
                )
                
                Spacer()
                
                compactStepCompletionButton(
                    index: index,
                    isCompleted: isCompleted
                )
            }
            
            // Compact timer for steps with timer - full width
            if step.hasTimer {
                compactStepTimer(step: step, index: index)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(backgroundColor)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 20, x: 0, y: 8)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(strokeColor, lineWidth: 1.5)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Шаг \(index + 1): \(step.text)")
        .accessibilityValue(accessibilityValue)
    }
    
    @ViewBuilder
    private func compactStepCircleIndicator(index: Int, isCompleted: Bool, isCurrent: Bool) -> some View {
        ZStack {
            Circle()
                .fill(Color.blue.opacity(0.1))
                .frame(width: 36, height: 36)
            
            Text("\(index + 1)")
                .font(.body.weight(.semibold))
                .foregroundStyle(.blue)
        }
        .accessibilityHidden(true)
    }
    
    @ViewBuilder
    private func compactStepTextContent(step: ExposureStep, index: Int, isCompleted: Bool) -> some View {
        Text(step.text)
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(isCompleted ? TextColors.secondary : TextColors.primary)
            .strikethrough(isCompleted)
    }
    
    @ViewBuilder
    private func compactStepTimer(step: ExposureStep, index: Int) -> some View {
        let timerController = getStepTimer(index)
        let duration = TimeInterval(step.timerDuration)
        
        CompactTimerView(
            timerController: timerController,
            duration: duration,
            formatTime: formatTime
        )
    }
    
    private func compactStepCompletionButton(index: Int, isCompleted: Bool) -> some View {
        Button {
            toggleStepCompletion(index)
        } label: {
            ZStack {
                Circle()
                    .stroke(isCompleted ? Color.green : Color.gray.opacity(0.3), lineWidth: 2)
                    .frame(width: 36, height: 36)
                
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.body.weight(.bold))
                        .foregroundStyle(.green)
                }
            }
        }
        .frame(minWidth: 44, minHeight: 44)
        .accessibilityLabel(isCompleted ? "Отменить выполнение шага" : "Отметить шаг как выполненное")
    }
    
    // MARK: - Timer Section View
    
    @ViewBuilder
    private func timerSectionView(
        timerController: StepTimerController,
        duration: TimeInterval,
        elapsedTime: TimeInterval,
        remaining: TimeInterval,
        isExpired: Bool,
        isTimerRunning: Bool,
        isTimerPaused: Bool
    ) -> some View {
        TimerSectionContent(
            timerController: timerController,
            duration: duration,
            formatTime: formatTime
        )
    }
    
    // MARK: - Helper Functions
    
    private func setupSession() {
        completedSteps = Set(session.completedStepIndices)
        
        for (index, time) in session.stepTimings {
            let timer = getStepTimer(index)
            timer.setElapsedTime(time)
            timerElapsedTimes[index] = time
        }
    }
    
    private func cleanupSession() {
        for (_, timer) in stepTimers {
            timer.stop()
        }
    }
    
    private func saveProgress() {
        session.completedStepIndices = Array(completedSteps).sorted()
        
        for (index, timer) in stepTimers {
            if timer.elapsedTime > 0 {
                session.setStepTime(index, time: timer.elapsedTime)
            }
        }
        
        if !notes.isEmpty {
            session.notes = notes
        }
        
        try? modelContext.save()
    }
    
    private func completeCurrentStep() {
        triggerSuccessHaptic()
        toggleStepCompletion(currentStepIndex)
    }
    
    private func finishSession() {
        // Mark the last step as completed
        withAnimation(.spring(response: 0.3)) {
            completedSteps.insert(currentStepIndex)
            session.markStepCompleted(currentStepIndex)
            
            if let timer = stepTimers[currentStepIndex] {
                timer.stop()
            }
        }
        
        triggerSuccessHaptic()
        saveProgress()
        
        // Show completion screen
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showingCompletion = true
        }
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
                
                if let timer = stepTimers[index] {
                    timer.stop()
                }
            }
        }
        
        saveProgress()
    }
    
    
    // MARK: - Step Navigation
    
    private func goToPreviousStep() {
        guard currentStepIndex > 0 else { return }
        
        // Find the previous incomplete step, or the last completed one before current
        let previousIndex = currentStepIndex - 1
        
        withAnimation(.spring(response: 0.3)) {
            if completedSteps.contains(previousIndex) {
                // Uncomplete the previous step to go back to it
                completedSteps.remove(previousIndex)
                session.markStepIncomplete(previousIndex)
            }
        }
        
        triggerHaptic(.medium)
        saveProgress()
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
        // No need for onTimeUpdate callback - TimerSectionContent observes the timer directly
        // via @ObservedObject and uses elapsedTime from the timer controller
        stepTimers[index] = newTimer
        return newTimer
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let totalSeconds = max(0, Int(timeInterval))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
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

#Preview("Active Session View") {
    let exposure = Exposure(title: "Test Exposure", exposureDescription: "Test Description", steps: [ExposureStep(text: "Test Step", hasTimer: true, timerDuration: 60), ExposureStep(text: "Second Step", hasTimer: false)])
    let session = ExposureSessionResult(exposure: exposure, anxietyBefore: 10, anxietyAfter: 5)
    ActiveSessionView(
        session: session,
        exposure: exposure
    )
}
