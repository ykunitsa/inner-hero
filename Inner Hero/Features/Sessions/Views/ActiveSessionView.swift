import SwiftUI
import SwiftData

// MARK: - Compact Timer View

private struct CompactTimerView: View {
    @Environment(\.colorScheme) private var colorScheme
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
    
    private var progressTrackColor: Color {
        Color.primary.opacity(colorScheme == .dark ? 0.18 : 0.12)
    }
    
    private var secondaryControlBackgroundColor: Color {
        Color.primary.opacity(colorScheme == .dark ? 0.14 : 0.08)
    }
    
    private var panelBackgroundGradientColors: [Color] {
        if colorScheme == .dark {
            return [
                Color(red: 0.14, green: 0.15, blue: 0.18),
                Color(red: 0.10, green: 0.11, blue: 0.14)
            ]
        }
        
        return [
            Color(red: 0.95, green: 0.97, blue: 1.0),
            Color(red: 0.92, green: 0.95, blue: 0.98)
        ]
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(progressTrackColor)
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
                                    .fill(secondaryControlBackgroundColor)
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
                        colors: panelBackgroundGradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(
                    color: Color.black.opacity(colorScheme == .dark ? 0.30 : 0.05),
                    radius: 6,
                    x: 0,
                    y: 2
                )
        )
    }
}

// MARK: - Timer Section Content

private struct TimerSectionContent: View {
    @Environment(\.colorScheme) private var colorScheme
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
    
    private var progressTrackColor: Color {
        Color.primary.opacity(colorScheme == .dark ? 0.18 : 0.12)
    }
    
    private var secondaryControlBackgroundColor: Color {
        Color.primary.opacity(colorScheme == .dark ? 0.14 : 0.08)
    }
    
    private var panelBackgroundGradientColors: [Color] {
        if colorScheme == .dark {
            return [
                Color(red: 0.14, green: 0.15, blue: 0.18),
                Color(red: 0.10, green: 0.11, blue: 0.14)
            ]
        }
        
        return [
            Color(red: 0.95, green: 0.97, blue: 1.0),
            Color(red: 0.92, green: 0.95, blue: 0.98)
        ]
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress bar at the top of timer panel
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(progressTrackColor)
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
                                    .fill(secondaryControlBackgroundColor)
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
                        colors: panelBackgroundGradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(
                    color: Color.black.opacity(colorScheme == .dark ? 0.30 : 0.05),
                    radius: 10,
                    x: 0,
                    y: 4
                )
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
}

// MARK: - Active Session View

struct ActiveSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    
    let session: ExposureSessionResult
    let exposure: Exposure
    let assignment: ExerciseAssignment?
    
    init(session: ExposureSessionResult, exposure: Exposure, assignment: ExerciseAssignment? = nil) {
        self.session = session
        self.exposure = exposure
        self.assignment = assignment
    }
    
    @State private var notes: String = ""
    @State private var showingCompletion = false
    @State private var showingPauseModal = false
    @State private var showingInterruptAlert = false
    @State private var shouldDismissAfterCompletion = false
    
    @State private var completedSteps: Set<Int> = []
    @State private var stepTimers: [Int: StepTimerController] = [:]
    @State private var timerElapsedTimes: [Int: TimeInterval] = [:]
    
    @State private var showTimer: Bool = true
    @State private var showProgressBar: Bool = false
    @State private var showAllSteps: Bool = false
    @State private var selectedStepIndex: Int? = nil
    @State private var scrollToStepId: Int? = nil

    // Swipe-to-complete (only for the large current step card)
    @State private var cardSwipeOffsetX: CGFloat = 0
    @State private var isSwipingCard: Bool = false
    
    private var backgroundGradientColors: [Color] {
        if colorScheme == .dark {
            return [
                Color(red: 0.06, green: 0.07, blue: 0.10),
                Color(red: 0.10, green: 0.11, blue: 0.14)
            ]
        }
        
        return [
            Color(red: 0.95, green: 0.97, blue: 1.0),
            Color(red: 0.92, green: 0.95, blue: 0.98)
        ]
    }
    
    private var dataManager: DataManager {
        DataManager(modelContext: modelContext)
    }
    
    private var steps: [ExposureStep] {
        exposure.steps.sorted(by: { $0.order < $1.order })
    }
    
    private var currentStepIndex: Int {
        if let selected = selectedStepIndex {
            return selected
        }
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
                        colors: backgroundGradientColors,
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
                colors: backgroundGradientColors,
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
            
            // Left side bottom toolbar - mode toggle button
            ToolbarItemGroup(placement: .bottomBar) {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        showAllSteps.toggle()
                    }
                } label: {
                    Image(systemName: showAllSteps ? "checklist.checked" : "checklist")
                        .font(.title2)
                        .foregroundStyle(TextColors.toolbar)
                        .symbolEffect(.bounce, value: showAllSteps)
                }
                .accessibilityLabel(showAllSteps ? "Скрыть все шаги" : "Показать все шаги")
                
                Spacer()
            }
            
            // Step number buttons in the middle - navigation
            ToolbarItem(placement: .bottomBar) {
                stepNumberButtons
            }
            
            // Right side buttons grouped
            ToolbarItemGroup(placement: .bottomBar) {
                Spacer()
                
                // Complete button or Finish flag
                Button {
                    if currentStepIndex == steps.count - 1 {
                        finishSession()
                    } else {
                        completeCurrentStep()
                    }
                } label: {
                    if currentStepIndex == steps.count - 1 {
                        Image(systemName: "flag.pattern.checkered")
                            .font(.title2)
                            .foregroundStyle(.green)
                            .symbolEffect(.bounce, value: completedSteps.count)
                    } else {
                        Image(systemName: completedSteps.contains(currentStepIndex) ? "checkmark.circle.fill" : "checkmark")
                            .font(.title2)
                            .foregroundStyle(completedSteps.contains(currentStepIndex) ? .green : TextColors.toolbar)
                            .symbolEffect(.bounce, value: completedSteps.contains(currentStepIndex))
                    }
                }
                .accessibilityLabel(currentStepIndex == steps.count - 1 ? "Завершить сессию" : "Завершить текущий шаг")
            }
        }
        .onAppear {
            setupSession()
        }
        .onDisappear {
            cleanupSession()
        }
        .sheet(isPresented: $showingCompletion, onDismiss: {
            guard shouldDismissAfterCompletion else { return }
            shouldDismissAfterCompletion = false
            dismiss()
        }) {
            CompleteSessionView(
                session: session,
                notes: notes,
                assignment: assignment,
                onComplete: {
                    // Close the sheet first, then close this screen in `onDismiss`.
                    saveProgress(includeNotes: false)
                    shouldDismissAfterCompletion = true
                    showingCompletion = false
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
    
    private var stepNumberButtons: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(steps.indices), id: \.self) { index in
                        stepNumberButton(index: index, scrollProxy: proxy)
                            .id(index)
                    }
                }
                .padding(.horizontal, 8)
            }
            .frame(height: 44)
            .clipShape(Capsule())
            .onAppear {
                // Center current step on first appearance
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo(currentStepIndex, anchor: .center)
                    }
                }
            }
            .onChange(of: currentStepIndex) { oldValue, newValue in
                withAnimation(.easeInOut(duration: 0.3)) {
                    proxy.scrollTo(newValue, anchor: .center)
                }
            }
            .onChange(of: scrollToStepId) { oldValue, newValue in
                if let stepId = newValue {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo(stepId, anchor: .center)
                    }
                    scrollToStepId = nil
                }
            }
        }
    }
    
    private func stepNumberButton(index: Int, scrollProxy: ScrollViewProxy) -> some View {
        let isCurrent = index == currentStepIndex
        let isCompleted = completedSteps.contains(index)
        
        return Button {
            scrollToStepId = index
            goToStep(index)
        } label: {
            if isCompleted {
                // Show checkmark for completed steps (never show the number)
                Image(systemName: "checkmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(isCurrent ? .blue : .green)
                    .symbolEffect(.bounce, value: currentStepIndex)
            } else {
                // Show number for current step or incomplete steps
                Text("\(index + 1)")
                    .font(.system(size: 16, weight: isCurrent ? .bold : .semibold))
                    .foregroundStyle(isCurrent ? .blue : TextColors.primary)
            }
        }
        .frame(minWidth: 36, minHeight: 36)
        .accessibilityLabel("Шаг \(index + 1)")
        .accessibilityValue(isCurrent ? "Текущий шаг" : (isCompleted ? "Выполнен" : "Не выполнен"))
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
            let swipeThreshold: CGFloat = 80
            let clampedOffsetX = min(max(cardSwipeOffsetX, -140), 140)
            let swipeIntensity = min(1.0, abs(clampedOffsetX) / swipeThreshold)
            let swipeColor: Color = clampedOffsetX >= 0 ? .green : .red

            ZStack {
                // Swipe feedback behind the card
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(swipeColor.opacity(0.12 * swipeIntensity))
                    .overlay {
                        HStack {
                            if clampedOffsetX > 0 {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 28, weight: .semibold))
                                    .foregroundStyle(swipeColor.opacity(0.9 * swipeIntensity))
                                Spacer()
                            } else if clampedOffsetX < 0 {
                                Spacer()
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 28, weight: .semibold))
                                    .foregroundStyle(swipeColor.opacity(0.9 * swipeIntensity))
                            }
                        }
                        .padding(.horizontal, 22)
                    }

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
                .offset(x: clampedOffsetX)
                .animation(.spring(response: 0.25, dampingFraction: 0.85), value: clampedOffsetX)
                .transition(.scale.combined(with: .opacity))
                .animation(.spring(response: 0.3), value: isCompleted)
            }
            .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .simultaneousGesture(
                DragGesture(minimumDistance: 12, coordinateSpace: .local)
                    .onChanged { value in
                        let dx = value.translation.width
                        let dy = value.translation.height
                        guard abs(dx) > abs(dy) else { return } // don't fight vertical scroll
                        isSwipingCard = true
                        cardSwipeOffsetX = dx
                    }
                    .onEnded { value in
                        defer {
                            isSwipingCard = false
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                                cardSwipeOffsetX = 0
                            }
                        }

                        guard isSwipingCard else { return }
                        let dx = value.translation.width

                        if dx >= swipeThreshold {
                            completeStepBySwipe(index)
                        } else if dx <= -swipeThreshold {
                            uncompleteStepBySwipe(index)
                        }
                    }
            )
            .onChange(of: currentStepIndex) { _, _ in
                cardSwipeOffsetX = 0
                isSwipingCard = false
            }
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
    
    private func saveProgress(includeNotes: Bool = true) {
        session.completedStepIndices = Array(completedSteps).sorted()
        
        for (index, timer) in stepTimers {
            if timer.elapsedTime > 0 {
                session.setStepTime(index, time: timer.elapsedTime)
            }
        }
        
        if includeNotes, !notes.isEmpty {
            session.notes = notes
        }
        
        try? modelContext.save()
    }
    
    private func completeCurrentStep() {
        // Capture the step the user is currently on (including manual navigation).
        let targetIndex = currentStepIndex
        let isCompleting = !completedSteps.contains(targetIndex)
        
        if isCompleting {
            triggerSuccessHaptic()
        }
        
        toggleStepCompletion(targetIndex)
        
        // After completing, return to auto-navigation; after un-completing, stay on this step.
        selectedStepIndex = isCompleting ? nil : targetIndex
    }
    
    private func finishSession() {
        // Mark the last step as completed
        withAnimation(.spring(response: 0.3)) {
            selectedStepIndex = nil // Reset to auto-navigation
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
                // When un-completing a step, also un-complete all subsequent steps
                // to keep progress consistent.
                let indicesToInvalidate = completedSteps.filter { $0 >= index }
                
                for stepIndex in indicesToInvalidate {
                    completedSteps.remove(stepIndex)
                    session.markStepIncomplete(stepIndex)
                    
                    // Clear any recorded timing for invalidated steps.
                    session.stepTimings.removeValue(forKey: stepIndex)
                    timerElapsedTimes.removeValue(forKey: stepIndex)
                    
                    // Reset any running timers for invalidated steps.
                    if let timer = stepTimers[stepIndex] {
                        timer.reset()
                    }
                }
            } else {
                // When completing a step, reset selectedStepIndex to return to auto-navigation
                if index == currentStepIndex {
                    selectedStepIndex = nil
                }
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

    // MARK: - Swipe completion (deterministic)

    private func completeStepBySwipe(_ index: Int) {
        guard index >= 0, index < steps.count else { return }
        guard !completedSteps.contains(index) else {
            // Already completed — still return to auto-navigation.
            selectedStepIndex = nil
            return
        }

        withAnimation(.spring(response: 0.3)) {
            completedSteps.insert(index)
            session.markStepCompleted(index)
            selectedStepIndex = nil // return to auto-navigation (advance to next incomplete)

            if let timer = stepTimers[index] {
                timer.stop()
            }
        }

        triggerSuccessHaptic()
        saveProgress()
    }

    private func uncompleteStepBySwipe(_ index: Int) {
        guard index >= 0, index < steps.count else { return }
        guard completedSteps.contains(index) else { return }
        toggleStepCompletion(index) // keeps existing invalidation rules for subsequent steps
    }
    
    
    // MARK: - Step Navigation
    
    private func goToStep(_ index: Int) {
        guard index >= 0 && index < steps.count else { return }
        
        withAnimation(.spring(response: 0.3)) {
            selectedStepIndex = index
        }
        
        triggerHaptic(.light)
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
