import SwiftUI
import SwiftData

struct RelaxationExerciseCardView: View {
    let exercise: RelaxationExercise
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

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center, spacing: Spacing.xs) {
            Image(systemName: exercise.icon)
                .font(.system(size: IconSize.glyph, weight: .semibold))
                .foregroundStyle(AppColors.positive)
                .iconContainer(
                    size: IconSize.card,
                    backgroundColor: AppColors.positive.opacity(Opacity.softBackground),
                    cornerRadius: CornerRadius.sm
                )
                .accessibilityHidden(true)

            Text(exercise.name)
                .appFont(.h3)
                .foregroundStyle(TextColors.primary)
                .multilineTextAlignment(.leading)

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppColors.gray400)
        }
    }

    // MARK: - Description

    private var descriptionText: some View {
        Text(exercise.description)
            .appFont(.body)
            .foregroundStyle(TextColors.secondary)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: Spacing.xs) {
            durationTag

            statTag(
                systemImage: "figure.mind.and.body",
                label: String(format: String(localized: "%d groups"), MuscleGroup.groups(for: exercise.type).count)
            )

            if let assignment, assignment.isActive {
                ScheduleIndicatorView(assignment: assignment)
            }
        }
    }

    private var durationTag: some View {
        let minutes = Int(exercise.duration / 60)
        return Text(String(format: String(localized: "%d min"), minutes))
            .appFont(.smallMedium)
            .foregroundStyle(AppColors.positive)
            .padding(.horizontal, Spacing.xxs)
            .padding(.vertical, Spacing.xxxs)
            .background(Capsule().fill(AppColors.positive.opacity(Opacity.subtleBackground)))
    }

    private func statTag(systemImage: String, label: String) -> some View {
        HStack(spacing: Spacing.xxxs) {
            Image(systemName: systemImage)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(AppColors.positive.opacity(0.7))
            Text(label)
                .appFont(.small)
                .foregroundStyle(TextColors.secondary)
        }
    }
}
