import SwiftUI

// MARK: - BAConfirmationStep

struct BAConfirmationStep: View {
    let draft: BAPlanDraft
    var onCreate: () -> Void

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            VStack(spacing: Spacing.xxs) {
                if let activity = draft.selectedActivity {
                    PlanSummaryRow(
                        icon: activity.lifeValue.systemIconName,
                        label: String(localized: "Activity"),
                        value: activity.localizedTitle
                    )
                }

                PlanSummaryRow(
                    icon: "clock",
                    label: String(localized: "Time"),
                    value: draft.startNow
                        ? String(localized: "Now")
                        : draft.scheduledFor.formatted(date: .omitted, time: .shortened)
                )

                PlanSummaryRow(
                    icon: "face.smiling",
                    label: String(localized: "Mood before"),
                    value: "\(draft.moodBefore)/10"
                )

                if let place = draft.implementationPlace, !place.isEmpty {
                    PlanSummaryRow(
                        icon: "mappin.circle",
                        label: String(localized: "Place"),
                        value: place
                    )
                }
            }
            .padding(.horizontal, Spacing.md)

            Spacer()

            VStack(spacing: Spacing.sm) {
                PrimaryButton(title: String(localized: "Done"), action: onCreate)
                    .padding(.horizontal, Spacing.md)

                Text(String(localized: "You'll be asked how you feel after."))
                    .appFont(.small)
                    .foregroundStyle(TextColors.tertiary)
                    .multilineTextAlignment(.center)
            }
            .padding(.bottom, Spacing.xl)
        }
    }
}

// MARK: - PlanSummaryRow

struct PlanSummaryRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: IconSize.glyph))
                .foregroundStyle(AppColors.accent)
                .frame(width: IconSize.inline, height: IconSize.inline)

            Text(label)
                .appFont(.small)
                .foregroundStyle(TextColors.secondary)

            Spacer()

            Text(value)
                .appFont(.bodyMedium)
                .foregroundStyle(TextColors.primary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(AppColors.gray200, lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview {
    BAConfirmationStep(draft: BAPlanDraft(), onCreate: {})
}
