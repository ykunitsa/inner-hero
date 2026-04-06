import SwiftUI
import SwiftData

// MARK: - BAPlanDraft

struct BAPlanDraft {
    var moodBefore: Int = 5
    var avoidanceContext: String? = nil
    var selectedActivity: BAActivity? = nil
    var scheduledFor: Date = .nextRoundHour
    var implementationPlace: String? = nil
    var startNow: Bool = false
}

private extension Date {
    static var nextRoundHour: Date {
        let cal = Calendar.current
        var components = cal.dateComponents([.year, .month, .day, .hour], from: Date())
        components.hour = (components.hour ?? 0) + 1
        components.minute = 0
        components.second = 0
        return cal.date(from: components) ?? Date().addingTimeInterval(3600)
    }
}

// MARK: - CreateBAPlanStep

enum CreateBAPlanStep: Int, CaseIterable {
    case moodCheck
    case avoidance
    case activityPicker
    case intention
    case confirmation
}

// MARK: - CreateBAPlanSheet

struct CreateBAPlanSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var step: CreateBAPlanStep
    @State private var draft: BAPlanDraft

    var onStartNow: ((BASession) -> Void)? = nil

    // When launched from Library, avoidance and activityPicker are skipped.
    private let initialActivity: BAActivity?

    init(initialActivity: BAActivity? = nil, onStartNow: ((BASession) -> Void)? = nil) {
        self.initialActivity = initialActivity
        self.onStartNow = onStartNow
        if let activity = initialActivity {
            _draft = State(initialValue: BAPlanDraft(selectedActivity: activity))
            _step = State(initialValue: .intention)
        } else {
            _draft = State(initialValue: BAPlanDraft())
            _step = State(initialValue: .moodCheck)
        }
    }

    // MARK: - Computed

    private var isFirstStep: Bool {
        step == .moodCheck
    }

    private var previousStep: CreateBAPlanStep? {
        if initialActivity != nil {
            // Skipped avoidance + activityPicker — back from intention goes to moodCheck
            switch step {
            case .moodCheck:   return nil
            case .intention:   return .moodCheck
            case .confirmation: return .intention
            default:           return nil
            }
        }
        return CreateBAPlanStep(rawValue: step.rawValue - 1)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                progressIndicator
                    .padding(.top, Spacing.sm)
                    .padding(.bottom, Spacing.xs)

                stepView
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    .id(step)
            }
            .animation(AppAnimation.spring, value: step)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if isFirstStep {
                        Button(String(localized: "Cancel")) { dismiss() }
                    } else if let prev = previousStep {
                        Button {
                            withAnimation(AppAnimation.spring) { step = prev }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 13, weight: .semibold))
                                Text(String(localized: "Back"))
                            }
                        }
                    }
                }
            }
        }
        .interactiveDismissDisabled(!isFirstStep)
    }

    // MARK: - Progress Indicator

    private var progressIndicator: some View {
        HStack(spacing: Spacing.sm) {
            HStack(spacing: Spacing.xxs) {
                ForEach(visibleSteps, id: \.rawValue) { s in
                    Circle()
                        .fill(s == step ? AppColors.accent : AppColors.gray300)
                        .frame(width: s == step ? 8 : 6, height: s == step ? 8 : 6)
                        .animation(AppAnimation.standard, value: step)
                }
            }

            Text("\(currentStepNumber) / \(visibleSteps.count)")
                .appFont(.small)
                .foregroundStyle(TextColors.tertiary)
        }
    }

    private var visibleSteps: [CreateBAPlanStep] {
        if initialActivity != nil {
            return [.moodCheck, .intention, .confirmation]
        }
        return CreateBAPlanStep.allCases
    }

    private var currentStepNumber: Int {
        (visibleSteps.firstIndex(of: step) ?? 0) + 1
    }

    // MARK: - Step View

    @ViewBuilder
    var stepView: some View {
        switch step {
        case .moodCheck:
            BAMoodCheckStep(mood: $draft.moodBefore, onNext: {
                withAnimation(AppAnimation.spring) {
                    step = initialActivity != nil ? .intention : .avoidance
                }
            })
        case .avoidance:
            BAAvoidanceStep(
                context: $draft.avoidanceContext,
                onNext: { withAnimation(AppAnimation.spring) { step = .activityPicker } },
                onSkip: { withAnimation(AppAnimation.spring) { step = .activityPicker } }
            )
        case .activityPicker:
            BAActivityPickerStep(selected: $draft.selectedActivity, onNext: {
                withAnimation(AppAnimation.spring) { step = .intention }
            })
        case .intention:
            BAIntentionStep(draft: $draft, onNext: {
                withAnimation(AppAnimation.spring) { step = .confirmation }
            })
        case .confirmation:
            BAConfirmationStep(draft: draft, onCreate: savePlan)
        }
    }

    // MARK: - Save

    func savePlan() {
        let session = BASession(
            activity: draft.selectedActivity,
            moodBefore: draft.moodBefore,
            avoidanceContext: draft.avoidanceContext,
            scheduledFor: draft.scheduledFor,
            implementationPlace: draft.implementationPlace
        )
        modelContext.insert(session)
        if draft.startNow {
            session.start()
            onStartNow?(session)
        }
        dismiss()
    }
}

// MARK: - Step: Mood Check

private struct BAMoodCheckStep: View {
    @Binding var mood: Int
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            VStack(spacing: Spacing.sm) {
                Text(String(localized: "How are you feeling right now?"))
                    .appFont(.h2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(TextColors.primary)

                Text(String(localized: "Rate your mood from 1 (very low) to 10 (very good)"))
                    .appFont(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(TextColors.secondary)
            }
            .padding(.horizontal, Spacing.lg)

            VStack(spacing: Spacing.sm) {
                Text("\(mood)")
                    .appFont(.monoLarge)
                    .foregroundStyle(AppColors.accent)
                    .contentTransition(.numericText())
                    .animation(AppAnimation.standard, value: mood)

                Slider(
                    value: Binding(get: { Double(mood) }, set: { mood = Int($0) }),
                    in: 1...10,
                    step: 1
                )
                .tint(AppColors.accent)
                .padding(.horizontal, Spacing.md)

                HStack {
                    Text(String(localized: "Very low"))
                        .appFont(.small)
                        .foregroundStyle(TextColors.tertiary)
                    Spacer()
                    Text(String(localized: "Very good"))
                        .appFont(.small)
                        .foregroundStyle(TextColors.tertiary)
                }
                .padding(.horizontal, Spacing.md)
            }

            Spacer()

            Button(action: onNext) {
                Text(String(localized: "Continue"))
                    .appFont(.buttonPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: TouchTarget.large)
                    .background(AppColors.accent)
                    .foregroundStyle(TextColors.onColor)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
            }
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Spacing.xl)
        }
    }
}


// MARK: - Preview

#Preview {
    CreateBAPlanSheet()
        .modelContainer(for: [BASession.self, BAActivity.self], inMemory: true)
}
