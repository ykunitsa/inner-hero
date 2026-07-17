import SwiftUI
import SwiftData

// MARK: - ExposureCardView

struct ExposureCardView: View {
    let exposure: Exposure
    var assignment: ExerciseAssignment? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            header
            Divider()
                .foregroundStyle(AppColors.gray200)
            metadataRow
        }
        .cardStyle(cornerRadius: CornerRadius.lg, padding: Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.xxxs) {
            Text(exposure.localizedTitle)
                .appFont(.h3)
                .foregroundStyle(TextColors.primary)
                .multilineTextAlignment(.leading)

            Text(exposure.localizedDescription)
                .appFont(.body)
                .foregroundStyle(TextColors.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Metadata Row

    private var metadataRow: some View {
        HStack(spacing: Spacing.xs) {
            // Schedule badge — only when active assignment exists
            if let assignment, assignment.isActive {
                ScheduleIndicatorView(assignment: assignment)
            }

            Spacer(minLength: 0)

            // Stats
            HStack(spacing: Spacing.sm) {
                statItem(
                    systemImage: "list.bullet",
                    value: exposure.localizedStepTexts.count,
                    accessibilityLabel: String(format: String(localized: "%d steps"), exposure.localizedStepTexts.count)
                )
                statItem(
                    systemImage: "chart.bar",
                    value: exposure.sessionResults.count,
                    accessibilityLabel: String(format: String(localized: "%d sessions"), exposure.sessionResults.count)
                )
            }
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Stat Item

    private func statItem(systemImage: String, value: Int, accessibilityLabel: String) -> some View {
        HStack(spacing: Spacing.xxxs) {
            Image(systemName: systemImage)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(AppColors.primary.opacity(0.7))

            Text("\(value)")
                .appFont(.small)
                .foregroundStyle(TextColors.secondary)
                .monospacedDigit()
        }
        .accessibilityLabel(accessibilityLabel)
    }
}
