import SwiftUI

struct BACompletionSheet: View {
    let session: BASession

    enum Step { case moodAfter, outcome, insight }

    @State private var step: Step = .moodAfter
    @State private var moodAfter: Int = 5
    @State private var outcome: ExpectedOutcome?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                switch step {
                case .moodAfter:
                    BAMoodPickerView(
                        question: String(localized: "How do you feel now?"),
                        mood: $moodAfter,
                        onNext: {
                            withAnimation(AppAnimation.spring) { step = .outcome }
                        }
                    )
                    .homeBackground()
                    .navigationTitle(String(localized: "After the activity"))
                    .navigationBarTitleDisplayMode(.inline)

                case .outcome:
                    BAExpectedOutcomeView { selected in
                        outcome = selected
                        withAnimation(AppAnimation.spring) { step = .insight }
                    }
                    .homeBackground()
                    .navigationTitle(String(localized: "How did it go?"))
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button {
                                withAnimation(AppAnimation.spring) { step = .moodAfter }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 13, weight: .semibold))
                                    Text(String(localized: "Back"))
                                }
                            }
                        }
                    }

                case .insight:
                    BAInsightView(
                        moodBefore: session.moodBefore,
                        moodAfter: moodAfter,
                        onDone: {
                            if let selected = outcome {
                                session.complete(moodAfter: moodAfter, outcome: selected)
                            }
                            dismiss()
                        }
                    )
                    .homeBackground()
                    .navigationTitle(String(localized: "Your insight"))
                    .navigationBarTitleDisplayMode(.inline)
                }
            }
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
            .id(step)
            .animation(AppAnimation.spring, value: step)
        }
    }
}

// MARK: - BAExpectedOutcomeView

private struct BAExpectedOutcomeView: View {
    let onSelect: (ExpectedOutcome) -> Void

    private let options: [(outcome: ExpectedOutcome, icon: String, description: String)] = [
        (.better,     "arrow.up.circle.fill",  String(localized: "Better than expected")),
        (.asExpected, "equal.circle.fill",     String(localized: "About as expected")),
        (.worse,      "arrow.down.circle.fill", String(localized: "Worse than expected")),
    ]

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Text(String(localized: "Compare to what you expected before"))
                .appFont(.body)
                .foregroundStyle(TextColors.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, Spacing.md)

            VStack(spacing: Spacing.xxs) {
                ForEach(options, id: \.outcome.rawValue) { item in
                    OutcomeOptionCard(
                        icon: item.icon,
                        title: item.description,
                        outcome: item.outcome,
                        onTap: { onSelect(item.outcome) }
                    )
                }
            }
            .padding(.horizontal, Spacing.md)

            Spacer()
        }
        .padding(.top, Spacing.lg)
    }
}

private struct OutcomeOptionCard: View {
    let icon: String
    let title: String
    let outcome: ExpectedOutcome
    let onTap: () -> Void

    @State private var isPressed = false

    private var accentColor: Color {
        switch outcome {
        case .better:     return AppColors.positive
        case .asExpected: return AppColors.accent
        case .worse:      return AppColors.primary
        }
    }

    var body: some View {
        Button(action: {
            HapticFeedback.selection()
            onTap()
        }) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 26, weight: .medium))
                    .foregroundStyle(accentColor)
                    .frame(width: IconSize.card, height: IconSize.card)

                Text(title)
                    .appFont(.bodyMedium)
                    .foregroundStyle(TextColors.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(TextColors.tertiary)
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.sm)
            .background(AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                    .strokeBorder(AppColors.gray200, lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in withAnimation(AppAnimation.fast) { isPressed = true } }
                .onEnded { _ in withAnimation(AppAnimation.fast) { isPressed = false } }
        )
        .animation(AppAnimation.fast, value: isPressed)
    }
}

// MARK: - BAInsightView

private struct BAInsightView: View {
    let moodBefore: Int
    let moodAfter: Int
    let onDone: () -> Void

    @State private var barsVisible = false

    private var delta: Int { moodAfter - moodBefore }

    private var insightText: String {
        if delta > 0 {
            return String(localized: "You did this even when you didn't want to. Remember this feeling.")
        } else if delta == 0 {
            return String(localized: "You don't always feel better right away. What matters is that you acted.")
        } else {
            return String(localized: "Sometimes improvement comes later. The important thing is you didn't avoid it.")
        }
    }

    private var deltaColor: Color {
        delta > 0 ? AppColors.positive : TextColors.secondary
    }

    private var deltaLabel: String {
        delta > 0 ? "+\(delta)" : "\(delta)"
    }

    var body: some View {
        VStack(spacing: Spacing.xl) {
            VStack(spacing: Spacing.md) {
                moodBar(
                    label: String(localized: "Before"),
                    value: moodBefore,
                    color: AppColors.accent,
                    fraction: barsVisible ? Double(moodBefore) / 10.0 : 0
                )

                moodBar(
                    label: String(localized: "After"),
                    value: moodAfter,
                    color: AppColors.positive,
                    fraction: barsVisible ? Double(moodAfter) / 10.0 : 0
                )

                HStack {
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(deltaLabel)
                            .appFont(.h2)
                            .foregroundStyle(deltaColor)
                            .animation(AppAnimation.spring, value: barsVisible)
                        Text(String(localized: "mood shift"))
                            .appFont(.small)
                            .foregroundStyle(TextColors.tertiary)
                    }
                }
            }
            .padding(Spacing.md)
            .background(AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                    .strokeBorder(AppColors.gray200, lineWidth: 1)
            )
            .padding(.horizontal, Spacing.md)

            Text(insightText)
                .appFont(.bodyLarge)
                .foregroundStyle(TextColors.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.lg)

            Spacer()

            PrimaryButton(
                title: String(localized: "Done"),
                color: AppColors.positive,
                action: onDone
            )
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Spacing.lg)
        }
        .padding(.top, Spacing.lg)
        .onAppear {
            withAnimation(AppAnimation.spring.delay(0.15)) {
                barsVisible = true
            }
        }
    }

    @ViewBuilder
    private func moodBar(label: String, value: Int, color: Color, fraction: Double) -> some View {
        VStack(spacing: Spacing.xxs) {
            HStack {
                Text(label)
                    .appFont(.small)
                    .foregroundStyle(TextColors.secondary)
                Spacer()
                Text("\(value)/10")
                    .appFont(.smallMedium)
                    .foregroundStyle(TextColors.primary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AppColors.gray200)
                        .frame(height: 10)

                    Capsule()
                        .fill(color)
                        .frame(width: geo.size.width * CGFloat(max(0, min(1, fraction))), height: 10)
                        .animation(AppAnimation.spring, value: fraction)
                }
            }
            .frame(height: 10)
        }
    }
}

// MARK: - Preview

#Preview {
    let activity = BAActivity(
        title: "Walk outside",
        lifeValueRaw: LifeValue.body.rawValue
    )
    let session = BASession(
        activity: activity,
        moodBefore: 4,
        scheduledFor: Date()
    )
    BACompletionSheet(session: session)
}
