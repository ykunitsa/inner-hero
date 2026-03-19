import SwiftUI
import SwiftData

// MARK: - BreathingExercisesView

struct BreathingExercisesView: View {
    @Query(sort: \ExerciseAssignment.createdAt) private var allAssignments: [ExerciseAssignment]

    @State private var appeared = false

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xs) {
                ForEach(Array(BreathingPattern.predefinedPatterns.enumerated()), id: \.element.id) { index, pattern in
                    let assignment = allAssignments.first {
                        $0.exerciseType == .breathing && $0.breathingPattern == pattern.type
                    }

                    NavigationLink(value: AppRoute.breathingDetail(patternType: pattern.type)) {
                        BreathingPatternCard(pattern: pattern, assignment: assignment)
                    }
                    .buttonStyle(.plain)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 12)
                    .animation(AppAnimation.appear.delay(Double(index) * 0.07), value: appeared)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(pattern.localizedName)
                    .accessibilityHint(String(localized: "Double-tap to open details"))
                }
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.xxl)
        }
        .homeBackground()
        .navigationTitle(String(localized: "Breathing"))
        .navigationBarTitleDisplayMode(.large)
        .onAppear { appeared = true }
    }
}

// MARK: - BreathingPatternCard

private struct BreathingPatternCard: View {
    let pattern: BreathingPattern
    let assignment: ExerciseAssignment?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            header
            descriptionText
            footer
        }
        .cardStyle(cornerRadius: CornerRadius.lg, padding: Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .center, spacing: Spacing.xs) {
            Image(systemName: pattern.icon)
                .font(.system(size: IconSize.glyph, weight: .semibold))
                .foregroundStyle(AppColors.positive)
                .iconContainer(
                    size: IconSize.card,
                    backgroundColor: AppColors.positive.opacity(Opacity.softBackground),
                    cornerRadius: CornerRadius.sm
                )
                .accessibilityHidden(true)

            Text(pattern.localizedName)
                .appFont(.h3)
                .foregroundStyle(TextColors.primary)
                .multilineTextAlignment(.leading)

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppColors.gray400)
        }
    }

    // MARK: Description — no lineLimit, only 3 cards on screen

    private var descriptionText: some View {
        Text(pattern.localizedDescription)
            .appFont(.body)
            .foregroundStyle(TextColors.secondary)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: Footer — rhythm tag + optional schedule badge

    private var footer: some View {
        HStack(spacing: Spacing.xs) {
            // Rhythm meta tag
            Text(pattern.type.rhythmLabel)
                .appFont(.smallMedium)
                .foregroundStyle(AppColors.positive)
                .padding(.horizontal, Spacing.xxs)
                .padding(.vertical, Spacing.xxxs)
                .background(
                    Capsule()
                        .fill(AppColors.positive.opacity(Opacity.subtleBackground))
                )

            if let assignment, assignment.isActive {
                ScheduleIndicatorView(assignment: assignment)
            }
        }
    }
}

// MARK: - BreathingPatternType + rhythm label

private extension BreathingPatternType {
    /// Human-readable rhythm string shown as a tag on the card
    var rhythmLabel: String {
        switch self {
        case .box:     return "4 · 4 · 4 · 4"
        case .fourSix: return "4 · 6"
        case .paced:   return "5 · 1 · 5 · 1"
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        BreathingExercisesView()
    }
    .modelContainer(for: [ExerciseAssignment.self], inMemory: true)
}
