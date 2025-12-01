import SwiftUI

// MARK: - Step Status Enum

enum StepStatus {
    case notDone
    case current
    case done
    
    var color: Color {
        switch self {
        case .notDone:
            return Color(.systemGray)
        case .current:
            return .blue
        case .done:
            return .green
        }
    }
    
    var icon: String {
        switch self {
        case .notDone:
            return "circle"
        case .current:
            return "circle.circle.fill"
        case .done:
            return "checkmark.circle.fill"
        }
    }
    
    var accessibilityLabel: String {
        switch self {
        case .notDone:
            return "Не выполнен"
        case .current:
            return "Текущий шаг"
        case .done:
            return "Выполнен"
        }
    }
}

// MARK: - Individual Step Card

struct StepCardView: View {
    let step: Step
    let stepNumber: Int
    let status: StepStatus
    
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    @State private var isAnimating = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            statusIndicatorView
            
            cardContentView
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
        .onAppear {
            if status == .current && !reduceMotion {
                withAnimation(.easeInOut(duration: 1.0).repeatCount(3, autoreverses: true)) {
                    isAnimating = true
                }
            }
        }
    }
    
    // MARK: - Status Indicator
    
    private var statusIndicatorView: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(status.color.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: status.icon)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(status.color)
                    .scaleEffect(status == .current && isAnimating && !reduceMotion ? 1.1 : 1.0)
            }
            .accessibilityHidden(true)
            
            if status != .done {
                Rectangle()
                    .fill(status.color.opacity(0.3))
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
                    .accessibilityHidden(true)
            }
        }
        .frame(width: 44)
    }
    
    // MARK: - Card Content
    
    private var cardContentView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 8) {
                stepBadge
                
                Spacer()
                
                if step.hasTimer {
                    timerBadge
                }
            }
            
            Text(step.text)
                .font(status == .current ? .body : .subheadline)
                .fontWeight(status == .current ? .semibold : .regular)
                .foregroundStyle(status == .notDone ? .secondary : .primary)
                .lineLimit(status == .current ? nil : 3)
                .fixedSize(horizontal: false, vertical: true)
            
            if status == .current {
                currentStepIndicator
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(status.color.opacity(status == .current ? 0.5 : 0.2), lineWidth: status == .current ? 2 : 1)
        )
        .shadow(
            color: status == .current ? status.color.opacity(0.15) : .clear,
            radius: status == .current ? 8 : 0,
            y: status == .current ? 4 : 0
        )
    }
    
    // MARK: - Subviews
    
    private var stepBadge: some View {
        Text("Шаг \(stepNumber)")
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(status.color)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(status.color.opacity(0.15))
            .clipShape(Capsule())
    }
    
    private var timerBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "timer.circle.fill")
                .font(.caption)
            Text(formatDuration(step.timerDuration))
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundStyle(.orange)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.orange.opacity(0.15))
        .clipShape(Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Таймер \(formatDuration(step.timerDuration))")
    }
    
    private var currentStepIndicator: some View {
        HStack(spacing: 6) {
            Image(systemName: "arrow.right.circle.fill")
                .font(.caption)
            Text("Текущий шаг")
                .font(.caption)
                .fontWeight(.semibold)
        }
        .foregroundStyle(.blue)
        .accessibilityHidden(true)
    }
    
    // MARK: - Background
    
    private var cardBackground: some View {
        Group {
            switch status {
            case .current:
                Color.blue.opacity(0.08)
            case .done:
                Color.green.opacity(0.05)
            case .notDone:
                Color(.secondarySystemGroupedBackground).opacity(0.7)
            }
        }
    }
    
    // MARK: - Helpers
    
    private func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        if minutes > 0 {
            return secs > 0 ? "\(minutes)м \(secs)с" : "\(minutes)м"
        }
        return "\(secs)с"
    }
    
    private var accessibilityLabel: String {
        var label = "Шаг \(stepNumber), \(status.accessibilityLabel). "
        label += step.text
        if step.hasTimer {
            label += ". Таймер \(formatDuration(step.timerDuration))"
        }
        return label
    }
    
    private var accessibilityHint: String {
        if status == .current {
            return "Текущий активный шаг"
        } else if status == .done {
            return "Шаг выполнен"
        } else {
            return "Шаг еще не выполнен"
        }
    }
}

// MARK: - Steps Progress View (Container)

struct StepsProgressView: View {
    let steps: [Step]
    let currentStepIndex: Int
    let onStepTap: ((Int) -> Void)?
    
    init(steps: [Step], currentStepIndex: Int, onStepTap: ((Int) -> Void)? = nil) {
        self.steps = steps
        self.currentStepIndex = currentStepIndex
        self.onStepTap = onStepTap
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            headerView
                .padding(.horizontal, 20)
            
            progressBarView
                .padding(.horizontal, 20)

            stepsListView
        }
        .padding(.vertical, 24)
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            Label("Шаги экспозиции", systemImage: "list.number")
                .font(.headline)
                .foregroundStyle(.primary)
            
            Spacer()
            
            progressSummaryBadge
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Шаги экспозиции. Выполнено \(currentStepIndex) из \(steps.count)")
    }
    
    private var progressSummaryBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill")
                .font(.caption)
                .foregroundStyle(.green)
            Text("\(currentStepIndex) / \(steps.count)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(Capsule())
        .accessibilityHidden(true)
    }
    
    // MARK: - Progress Bar
    
    private var progressBarView: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color(.systemGray5))
                    .frame(height: 8)
                
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [.blue, .green],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(
                        width: geometry.size.width * CGFloat(currentStepIndex + 1) / CGFloat(max(steps.count, 1)),
                        height: 8
                    )
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: currentStepIndex)
            }
        }
        .frame(height: 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Прогресс выполнения")
        .accessibilityValue("\(Int(Double(currentStepIndex + 1) / Double(max(steps.count, 1)) * 100)) процентов")
    }
    
    // MARK: - Steps List
    
    private var stepsListView: some View {
        ScrollViewReader { proxy in
            VStack(spacing: 0) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    Button {
                        onStepTap?(index)
                    } label: {
                        StepCardView(
                            step: step,
                            stepNumber: index + 1,
                            status: stepStatus(for: index)
                        )
                        .id(index)
                    }
                    .buttonStyle(.plain)
                    .disabled(onStepTap == nil)
                    .frame(minHeight: 44)
                    .accessibilityAddTraits(onStepTap != nil ? .isButton : [])
                    .accessibilityHint(onStepTap != nil ? "Дважды нажмите для перехода к этому шагу" : "")
                }
            }
            .padding(.horizontal, 20)
            .onChange(of: currentStepIndex) { _, newIndex in
                withAnimation(.easeInOut(duration: 0.3)) {
                    proxy.scrollTo(newIndex, anchor: .center)
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private func stepStatus(for index: Int) -> StepStatus {
        if index < currentStepIndex {
            return .done
        } else if index == currentStepIndex {
            return .current
        } else {
            return .notDone
        }
    }
}

// MARK: - Compact Steps Progress View (Alternative)

struct CompactStepsProgressView: View {
    let steps: [Step]
    let currentStepIndex: Int
    
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    var body: some View {
        VStack(spacing: 16) {
            progressDotsView
            
            if currentStepIndex < steps.count {
                currentStepInfoView
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }
    
    // MARK: - Progress Dots
    
    private var progressDotsView: some View {
        HStack(spacing: 8) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, _ in
                Circle()
                    .fill(circleColor(for: index))
                    .frame(width: circleSize(for: index), height: circleSize(for: index))
                    .overlay(
                        Circle()
                            .stroke(
                                index == currentStepIndex ? Color.blue : Color.clear,
                                lineWidth: 2
                            )
                            .frame(width: circleSize(for: index) + 4, height: circleSize(for: index) + 4)
                    )
                    .animation(
                        reduceMotion ? .none : .spring(response: 0.4, dampingFraction: 0.7),
                        value: currentStepIndex
                    )
            }
        }
        .accessibilityHidden(true)
    }
    
    // MARK: - Current Step Info
    
    private var currentStepInfoView: some View {
        let currentStep = steps[currentStepIndex]
        
        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Шаг \(currentStepIndex + 1) из \(steps.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(currentStep.text)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .foregroundStyle(.primary)
            }
            
            Spacer()
            
            if currentStep.hasTimer {
                Image(systemName: "timer.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.orange)
                    .accessibilityLabel("Таймер")
            }
        }
        .padding(20)
        .background(Color.blue.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Helpers
    
    private func circleColor(for index: Int) -> Color {
        if index < currentStepIndex {
            return .green
        } else if index == currentStepIndex {
            return .blue
        } else {
            return Color(.systemGray4)
        }
    }
    
    private func circleSize(for index: Int) -> CGFloat {
        index == currentStepIndex ? 12 : 8
    }
    
    private var accessibilityLabel: String {
        if currentStepIndex < steps.count {
            let currentStep = steps[currentStepIndex]
            var label = "Шаг \(currentStepIndex + 1) из \(steps.count). "
            label += currentStep.text
            if currentStep.hasTimer {
                label += ". С таймером"
            }
            return label
        }
        return "Все шаги выполнены"
    }
}

// MARK: - Preview

#Preview("Single Step - Not Done") {
    ScrollView {
        StepCardView(
            step: Step(text: "Посмотрите на фотографию паука в течение 30 секунд", hasTimer: true, timerDuration: 30, order: 0),
            stepNumber: 1,
            status: .notDone
        )
        .padding(20)
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Single Step - Current") {
    ScrollView {
        StepCardView(
            step: Step(text: "Посмотрите видео с пауками в течение 2 минут, отмечая свои ощущения", hasTimer: true, timerDuration: 120, order: 1),
            stepNumber: 2,
            status: .current
        )
        .padding(20)
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Single Step - Done") {
    ScrollView {
        StepCardView(
            step: Step(text: "Представьте, что держите паука в руках", hasTimer: false, timerDuration: 0, order: 2),
            stepNumber: 3,
            status: .done
        )
        .padding(20)
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Full Steps Progress") {
    let sampleSteps = [
        Step(text: "Посмотрите на фотографию паука в течение 30 секунд", hasTimer: true, timerDuration: 30, order: 0),
        Step(text: "Посмотрите видео с пауками в течение 2 минут", hasTimer: true, timerDuration: 120, order: 1),
        Step(text: "Представьте, что держите паука в руках. Закройте глаза и визуализируйте эту ситуацию как можно подробнее", hasTimer: false, timerDuration: 0, order: 2),
        Step(text: "Посмотрите на живого паука в террариуме", hasTimer: false, timerDuration: 0, order: 3),
        Step(text: "Подержите паука в руках (с помощью специалиста)", hasTimer: false, timerDuration: 0, order: 4)
    ]
    
    ScrollView {
        StepsProgressView(
            steps: sampleSteps,
            currentStepIndex: 2,
            onStepTap: { index in
                print("Tapped step \(index)")
            }
        )
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Compact Progress") {
    let sampleSteps = [
        Step(text: "Посмотрите на фотографию", hasTimer: true, timerDuration: 30, order: 0),
        Step(text: "Посмотрите видео", hasTimer: true, timerDuration: 120, order: 1),
        Step(text: "Представьте ситуацию", hasTimer: false, timerDuration: 0, order: 2),
        Step(text: "Посмотрите вживую", hasTimer: false, timerDuration: 0, order: 3)
    ]
    
    VStack(alignment: .leading, spacing: 0) {
        CompactStepsProgressView(steps: sampleSteps, currentStepIndex: 1)
            .padding(20)
        Spacer()
    }
    .background(Color(.systemGroupedBackground))
}

// MARK: - Dark Mode Preview

#Preview("Dark Mode - Current Step") {
    ScrollView {
        StepCardView(
            step: Step(text: "Посмотрите видео с пауками в течение 2 минут", hasTimer: true, timerDuration: 120, order: 1),
            stepNumber: 2,
            status: .current
        )
        .padding(20)
    }
    .background(Color(.systemGroupedBackground))
    .preferredColorScheme(.dark)
}

#Preview("Accessibility - Large Text") {
    ScrollView {
        VStack(spacing: 16) {
            StepCardView(
                step: Step(text: "Посмотрите видео с пауками в течение 2 минут, отмечая свои ощущения", hasTimer: true, timerDuration: 120, order: 1),
                stepNumber: 2,
                status: .current
            )
        }
        .padding(20)
    }
    .background(Color(.systemGroupedBackground))
    .environment(\.dynamicTypeSize, .accessibility3)
}

