import SwiftUI
import SwiftData

// MARK: - Compact Timer View

private struct CompactTimerView: View {
    let timerController: StepTimerController
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
        VStack(spacing: Spacing.xxs) {
            HStack(spacing: Spacing.sm) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(isExpired ? "Time's up" : "Time left")
                        .appFont(.caption)
                        .foregroundStyle(TextColors.onColorSecondary)
                    Text(formatTime(remaining))
                        .appFont(.monoLarge)
                        .foregroundStyle(TextColors.onColor)
                        .monospacedDigit()
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(isExpired ? "Time's up" : "Time remaining: \(formatTime(remaining))")
                
                Spacer()
                
                HStack(spacing: Spacing.xs) {
                    CircleButton(
                        systemImage: isTimerRunning ? "pause.fill" : "play.fill",
                        size: 44,
                        iconSize: 16,
                        background: Color.white.opacity(0.22),
                        foreground: .white
                    ) {
                        Task { @MainActor in
                            if isTimerRunning {
                                timerController.pause()
                            } else if isTimerPaused {
                                timerController.resume()
                            } else {
                                timerController.start()
                            }
                        }
                    }
                    .accessibilityLabel(isTimerRunning ? "Pause" : (isTimerPaused ? "Resume timer" : "Start timer"))
                    
                    CircleButton(
                        systemImage: "arrow.counterclockwise",
                        size: 44,
                        iconSize: 15,
                        background: Color.white.opacity(0.16),
                        foreground: Color.white.opacity(0.9)
                    ) {
                        Task { @MainActor in
                            timerController.reset()
                        }
                    }
                    .accessibilityLabel("Reset timer")
                }
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.25))
                        .frame(height: 4)
                    
                    Capsule()
                        .fill(Color.white)
                        .frame(width: geometry.size.width * progress, height: 4)
                        .animation(AppAnimation.fast, value: progress)
                }
            }
            .frame(height: 4)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous)
                .fill(AppColors.primary)
        )
    }
}

// MARK: - Timer Section Content

private struct TimerSectionContent: View {
    let timerController: StepTimerController
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
        VStack(spacing: Spacing.xs) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.25))
                        .frame(height: 4)
                    
                    Capsule()
                        .fill(Color.white)
                        .frame(width: geometry.size.width * progress, height: 4)
                        .animation(AppAnimation.fast, value: progress)
                }
            }
            .frame(height: 4)
            .padding(.horizontal, Spacing.sm)
            .padding(.top, Spacing.xs)
            
            HStack(spacing: Spacing.sm) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(isExpired ? "Time's up" : "Time left")
                        .appFont(.caption)
                        .foregroundStyle(TextColors.onColorSecondary)
                    Text(formatTime(remaining))
                        .appFont(.monoLarge)
                        .foregroundStyle(TextColors.onColor)
                        .monospacedDigit()
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(isExpired ? "Time's up" : "Time remaining: \(formatTime(remaining))")
                
                Spacer()
                
                HStack(spacing: Spacing.xxs) {
                    CircleButton(
                        systemImage: isTimerRunning ? "pause.fill" : "play.fill",
                        size: 40,
                        iconSize: 16,
                        background: Color.white.opacity(0.22),
                        foreground: .white
                    ) {
                        Task { @MainActor in
                            if isTimerRunning {
                                timerController.pause()
                            } else if isTimerPaused {
                                timerController.resume()
                            } else {
                                timerController.start()
                            }
                        }
                    }
                    .accessibilityLabel(isTimerRunning ? "Pause" : (isTimerPaused ? "Resume timer" : "Start timer"))
                    
                    CircleButton(
                        systemImage: "arrow.counterclockwise",
                        size: 40,
                        iconSize: 15,
                        background: Color.white.opacity(0.16),
                        foreground: Color.white.opacity(0.9)
                    ) {
                        Task { @MainActor in
                            timerController.reset()
                        }
                    }
                    .accessibilityLabel("Reset timer")
                }
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.bottom, Spacing.sm)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous)
                .fill(AppColors.primary)
        )
        .shadow(color: Color.black.opacity(0.25), radius: 16, y: 6)
    }
}

// MARK: - Active Session View

struct ActiveSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let exposure: Exposure
    @State private var viewModel: ActiveSessionViewModel

    init(session: ExposureSessionResult, exposure: Exposure, assignment: ExerciseAssignment? = nil) {
        self.exposure = exposure
        let steps = exposure.steps.sorted(by: { $0.order < $1.order })
        self._viewModel = State(initialValue: ActiveSessionViewModel(session: session, steps: steps, assignment: assignment))
    }

    @State private var showingPauseModal = false
    @State private var showingInterruptAlert = false
    @State private var shouldDismissAfterCompletion = false

    @State private var showAllSteps: Bool = false
    @State private var scrollToStepId: Int? = nil

    @State private var cardSwipeOffsetX: CGFloat = 0
    @State private var isSwipingCard: Bool = false
    @State private var hasShownSwipeHint: Bool = false

    private var session: ExposureSessionResult { viewModel.session }
    private var steps: [ExposureStep] { viewModel.steps }

    private var localizedStepTexts: [String] { exposure.localizedStepTexts }

    private func localizedStepText(at index: Int, fallback step: ExposureStep) -> String {
        guard index >= 0, index < localizedStepTexts.count else { return step.text }
        return localizedStepTexts[index]
    }

    private var currentStepIndex: Int { viewModel.currentStepIndex }

    private var currentStep: ExposureStep? {
        guard currentStepIndex < steps.count else { return nil }
        return steps[currentStepIndex]
    }

    private var allStepsCompleted: Bool { viewModel.allStepsCompleted }
    
    var body: some View {
        VStack(spacing: 0) {
            // Fixed progress indicator at the top
            stepProgressIndicator
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.lg)
                .background(AppColors.gray100)
            
            // Scrollable content
            GeometryReader { geometry in
                ScrollView {
                    LazyVStack(spacing: Spacing.xl) {
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
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.lg)
                    .padding(.bottom, Spacing.xxl)
                    .frame(minHeight: geometry.size.height)
                }
            }
        }
        .pageBackground()
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            // Back button (top left)
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    showingInterruptAlert = true
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(TextColors.primary)
                        .frame(width: 32, height: 32)
                }
                .accessibilityLabel("Back")
            }
            
            // End session button (top right)
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingPauseModal = true
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(TextColors.primary)
                        .frame(width: 32, height: 32)
                }
                .accessibilityLabel("End session early")
            }
            
            ToolbarItem(placement: .principal) {
                Text(exposure.localizedTitle)
                    .appFont(.h3)
                    .foregroundStyle(TextColors.toolbar)
            }
            
            // Left side bottom toolbar - mode toggle button
            ToolbarItemGroup(placement: .bottomBar) {
                Button {
                    withAnimation(AppAnimation.spring) {
                        showAllSteps.toggle()
                    }
                } label: {
                    Image(systemName: showAllSteps ? "checklist.checked" : "checklist")
                        .font(.system(size: IconSize.glyph, weight: .regular))
                        .foregroundStyle(TextColors.toolbar)
                        .symbolEffect(.bounce, value: showAllSteps)
                }
                .accessibilityLabel(showAllSteps ? "Hide all steps" : "Show all steps")
                
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
                        HapticFeedback.success()
                        viewModel.saveProgress(context: modelContext)
                        viewModel.finishSessionUI()
                    } else {
                        if !viewModel.completedSteps.contains(currentStepIndex) {
                            HapticFeedback.success()
                        }
                        viewModel.completeCurrentStep()
                    }
                } label: {
                    if currentStepIndex == steps.count - 1 {
                        Image(systemName: "flag.pattern.checkered")
                            .font(.system(size: IconSize.glyph, weight: .regular))
                            .foregroundStyle(AppColors.positive)
                            .symbolEffect(.bounce, value: viewModel.completedSteps.count)
                    } else {
                        Image(systemName: viewModel.completedSteps.contains(currentStepIndex) ? "checkmark.circle.fill" : "checkmark")
                            .font(.system(size: IconSize.glyph, weight: .regular))
                            .foregroundStyle(viewModel.completedSteps.contains(currentStepIndex) ? AppColors.positive : TextColors.toolbar)
                            .symbolEffect(.bounce, value: viewModel.completedSteps.contains(currentStepIndex))
                    }
                }
                .accessibilityLabel(currentStepIndex == steps.count - 1 ? "End session" : "Complete current step")
            }
        }
        .onAppear {
            viewModel.setup()
        }
        .onDisappear {
            viewModel.cleanup()
        }
        .sheet(isPresented: $viewModel.showingCompletion, onDismiss: {
            guard shouldDismissAfterCompletion else { return }
            shouldDismissAfterCompletion = false
            dismiss()
        }) {
            CompleteSessionView(
                session: session,
                notes: viewModel.notes,
                assignment: viewModel.assignment,
                onSave: { anxietyAfter, notes in
                    try await viewModel.finishSession(anxietyAfter: anxietyAfter, notes: notes, context: modelContext)
                },
                onComplete: {
                    viewModel.saveProgress(context: modelContext)
                    shouldDismissAfterCompletion = true
                    viewModel.showingCompletion = false
                }
            )
        }
        .sheet(isPresented: $showingPauseModal) {
            PauseSessionModal(
                onResume: {
                    showingPauseModal = false
                },
                onEnd: {
                    viewModel.cleanup()
                    dismiss()
                }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .alert("Leave session?", isPresented: $showingInterruptAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Leave", role: .destructive) {
                viewModel.cleanup()
                dismiss()
            }
        } message: {
            Text("Your progress so far has been saved.")
        }
    }
    
    private var stepNumberButtons: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.xxxs) {
                    ForEach(Array(steps.indices), id: \.self) { index in
                        stepNumberButton(index: index, scrollProxy: proxy)
                            .id(index)
                    }
                }
                .padding(.horizontal, Spacing.xxs)
                .padding(.vertical, Spacing.xxxs)
            }
            .frame(height: 44)
            .onAppear {
                // Center current step on first appearance
                Task {
                    try? await Task.sleep(for: .seconds(0.1))
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
        let isCompleted = viewModel.completedSteps.contains(index)
        
        return Button {
            scrollToStepId = index
            viewModel.goToStep(index)
            HapticFeedback.light()
        } label: {
            if isCompleted {
                // Show checkmark for completed steps (never show the number)
                Image(systemName: "checkmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(isCurrent ? AppColors.primary : AppColors.positive)
                    .symbolEffect(.bounce, value: currentStepIndex)
            } else {
                // Show number for current step or incomplete steps
                Text("\(index + 1)")
                    .appFont(.smallMedium)
                    .foregroundStyle(isCurrent ? AppColors.primary : TextColors.primary)
            }
        }
        .frame(minWidth: 34, minHeight: 34)
        .background(
            Capsule()
                .fill(isCurrent ? AppColors.primaryLight : .clear)
        )
        .accessibilityLabel("Step \(index + 1)")
        .accessibilityValue(isCurrent ? "Current step" : (isCompleted ? "Completed" : "Not completed"))
    }
    
    private var stepProgressIndicator: some View {
        VStack(spacing: Spacing.xxs) {
            Text("Step \(currentStepIndex + 1) of \(steps.count)")
                .appFont(.caption)
                .foregroundStyle(TextColors.secondary)
                .accessibilityLabel("Step \(currentStepIndex + 1) of \(steps.count)")

            StepProgressBar(
                current: viewModel.completedSteps.count,
                total: max(steps.count, 1),
                color: AppColors.primary,
                height: 4
            )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Progress")
            .accessibilityValue("\(viewModel.completedSteps.count) of \(steps.count) steps completed")
        }
        .padding(.top, Spacing.xs)
    }
    
    private func currentStepLargeCard(step: ExposureStep, index: Int) -> some View {
        let isCompleted = viewModel.completedSteps.contains(index)
        let timerController = step.hasTimer ? viewModel.timer(for: index) : nil
        let duration = step.hasTimer ? TimeInterval(step.timerDuration) : 0
        // Use elapsedTime directly from controller for reactive updates
        let elapsedTime = timerController?.elapsedTime ?? 0
        let remaining = max(0, duration - elapsedTime)
        let isExpired = step.hasTimer && elapsedTime >= duration
        // Read timer state directly from controller to ensure UI updates
        let isTimerRunning = timerController?.isRunning == true && timerController?.isPaused == false
        let isTimerPaused = timerController?.isPaused == true
        
        return GeometryReader { geometry in
            let swipeThreshold: CGFloat = 80
            let clampedOffsetX = min(max(cardSwipeOffsetX, -140), 140)
            let swipeIntensity = min(1.0, abs(clampedOffsetX) / swipeThreshold)
            let swipeColor: Color = clampedOffsetX >= 0 ? AppColors.primary : AppColors.positive

            ZStack {
                // Swipe feedback behind the card
                RoundedRectangle(cornerRadius: CornerRadius.xl, style: .continuous)
                    .fill(swipeColor.opacity(0.14 * swipeIntensity))
                    .overlay {
                        HStack {
                            if clampedOffsetX > 0 {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 28, weight: .semibold))
                                    .foregroundStyle(swipeColor.opacity(0.85 * swipeIntensity))
                                Spacer()
                            } else if clampedOffsetX < 0 {
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 28, weight: .semibold))
                                    .foregroundStyle(swipeColor.opacity(0.85 * swipeIntensity))
                            }
                        }
                        .padding(.horizontal, Spacing.lg)
                    }

                VStack(spacing: 0) {
                    // Top section: step text (2/3 of card)
                    ZStack(alignment: .center) {
                        // Step text (centered vertically and horizontally)
                        Text(localizedStepText(at: index, fallback: step))
                            .appFont(.h1)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .foregroundStyle(TextColors.primary)
                            .lineSpacing(8)
                            .padding(.horizontal, Spacing.xl)
                        
                        // Step number in top-left corner
                        VStack {
                            HStack {
                                Text("\(index + 1)")
                                    .appFont(.monoLarge)
                                    .foregroundStyle(AppColors.primary)
                                    .frame(width: 60, height: 60)
                                    .background(Circle().fill(AppColors.primaryLight))
                                
                                Spacer()
                            }
                            
                            Spacer()
                        }
                        .padding(Spacing.lg)
                    }
                    .frame(maxWidth: .infinity, maxHeight: step.hasTimer ? geometry.size.height * 0.67 : .infinity)
                    .background(AppColors.cardBackground)
                    
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
                .background(AppColors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.xl, style: .continuous))
                .shadow(color: Color.black.opacity(Opacity.standardShadow), radius: 20, x: 0, y: 8)
                .offset(x: clampedOffsetX)
                .animation(AppAnimation.spring, value: clampedOffsetX)
                .transition(.scale.combined(with: .opacity))
                .animation(AppAnimation.spring, value: isCompleted)
            }
            .contentShape(RoundedRectangle(cornerRadius: CornerRadius.xl, style: .continuous))
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
                            uncompleteStepBySwipe(index)
                        } else if dx <= -swipeThreshold {
                            completeStepBySwipe(index)
                        }
                    }
            )
            .onChange(of: currentStepIndex) { _, _ in
                cardSwipeOffsetX = 0
                isSwipingCard = false
            }
            .task {
                guard !hasShownSwipeHint else { return }
                hasShownSwipeHint = true
                try? await Task.sleep(for: .milliseconds(700))
                withAnimation(.spring(response: 0.45, dampingFraction: 0.4)) {
                    cardSwipeOffsetX = -68
                }
                try? await Task.sleep(for: .milliseconds(420))
                withAnimation(.spring(response: 0.5, dampingFraction: 0.68)) {
                    cardSwipeOffsetX = 0
                }
            }
        }
    }
    
    private var completionPrompt: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(AppColors.positive)
                .accessibilityHidden(true)
            
            VStack(spacing: Spacing.xxxs) {
                Text("All steps completed!")
                    .appFont(.h2)
                    .foregroundStyle(TextColors.primary)
                    .multilineTextAlignment(.center)
                
                Text("You did a great job")
                    .appFont(.small)
                    .foregroundStyle(TextColors.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity)
        .cardStyle()
    }
    
    
    private var allStepsSection: some View {
        VStack(spacing: Spacing.xs) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                compactStepRow(step: step, index: index)
            }
        }
        .transition(.scale.combined(with: .opacity))
    }
    
    private func compactStepRow(step: ExposureStep, index: Int) -> some View {
        let isCompleted = viewModel.completedSteps.contains(index)
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
        let strokeColor = isCurrent ? AppColors.primary.opacity(0.25) : Color.clear
        let accessibilityValue = isCompleted ? "Completed" : (isCurrent ? "Current step" : "Not completed")
        
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.sm) {
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
        .padding(Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous)
                .fill(AppColors.cardBackground)
        )
        .shadow(color: Color.black.opacity(Opacity.standardShadow), radius: 20, x: 0, y: 8)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous)
                .stroke(strokeColor, lineWidth: 1.5)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Step \(index + 1): \(localizedStepText(at: index, fallback: step))")
        .accessibilityValue(accessibilityValue)
    }
    
    @ViewBuilder
    private func compactStepCircleIndicator(index: Int, isCompleted: Bool, isCurrent: Bool) -> some View {
        ZStack {
            Circle()
                .fill(AppColors.primaryLight)
                .frame(width: 36, height: 36)
            
            Text("\(index + 1)")
                .appFont(.bodyMedium)
                .foregroundStyle(AppColors.primary)
        }
        .accessibilityHidden(true)
    }
    
    @ViewBuilder
    private func compactStepTextContent(step: ExposureStep, index: Int, isCompleted: Bool) -> some View {
        Text(localizedStepText(at: index, fallback: step))
            .appFont(.bodyMedium)
            .foregroundStyle(isCompleted ? TextColors.secondary : TextColors.primary)
            .strikethrough(isCompleted)
    }
    
    @ViewBuilder
    private func compactStepTimer(step: ExposureStep, index: Int) -> some View {
        let timerController = viewModel.timer(for: index)
        let duration = TimeInterval(step.timerDuration)
        
        CompactTimerView(
            timerController: timerController,
            duration: duration,
            formatTime: formatTime
        )
    }
    
    private func compactStepCompletionButton(index: Int, isCompleted: Bool) -> some View {
        Button {
            viewModel.toggleStepCompletion(index)
        } label: {
            ZStack {
                Circle()
                    .stroke(isCompleted ? AppColors.positive : AppColors.gray300, lineWidth: 2)
                    .frame(width: 36, height: 36)
                
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(AppColors.positive)
                }
            }
        }
        .frame(minWidth: 44, minHeight: 44)
        .accessibilityLabel(isCompleted ? "Undo step completion" : "Mark step as completed")
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
        .padding(.horizontal, Spacing.lg)
        .padding(.bottom, Spacing.lg)
    }
    
    // MARK: - Helper Functions

    // MARK: - Swipe completion (deterministic)

    private func completeStepBySwipe(_ index: Int) {
        guard index >= 0, index < steps.count else { return }
        guard !viewModel.completedSteps.contains(index) else { return }
        withAnimation(.spring(response: 0.3)) {
            viewModel.toggleStepCompletion(index)
        }
        HapticFeedback.success()
        viewModel.saveProgress(context: modelContext)
        if index < steps.count - 1 {
            viewModel.goToStep(index + 1)
        }
    }

    private func uncompleteStepBySwipe(_ index: Int) {
        guard index >= 0, index < steps.count else { return }
        if viewModel.completedSteps.contains(index) {
            viewModel.toggleStepCompletion(index)
        }
        HapticFeedback.light()
        if index > 0 {
            viewModel.goToStep(index - 1)
        }
    }

    // MARK: - Helpers
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let totalSeconds = max(0, Int(timeInterval))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
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
