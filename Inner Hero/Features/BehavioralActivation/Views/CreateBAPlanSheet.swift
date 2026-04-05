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

    @State private var step: CreateBAPlanStep = .moodCheck
    @State private var draft = BAPlanDraft()

    var onStartNow: ((BASession) -> Void)? = nil

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                progressDots
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
                ToolbarItem(placement: .cancellationAction) {
                    if step == .moodCheck {
                        Button(String(localized: "Cancel")) { dismiss() }
                    }
                }
            }
        }
        .interactiveDismissDisabled(step != .moodCheck)
    }

    // MARK: - Progress Dots

    private var progressDots: some View {
        HStack(spacing: Spacing.xxs) {
            ForEach(CreateBAPlanStep.allCases, id: \.rawValue) { s in
                Circle()
                    .fill(s == step ? AppColors.accent : AppColors.gray300)
                    .frame(width: s == step ? 8 : 6, height: s == step ? 8 : 6)
                    .animation(AppAnimation.standard, value: step)
            }
        }
    }

    // MARK: - Step View

    @ViewBuilder
    var stepView: some View {
        switch step {
        case .moodCheck:
            BAMoodCheckStep(mood: $draft.moodBefore, onNext: { step = .avoidance })
        case .avoidance:
            BAAvoidanceStep(
                context: $draft.avoidanceContext,
                onNext: { step = .activityPicker },
                onSkip: { step = .activityPicker }
            )
        case .activityPicker:
            BAActivityPickerStep(selected: $draft.selectedActivity, onNext: { step = .intention })
        case .intention:
            BAIntentionStep(draft: $draft, onNext: { step = .confirmation })
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
