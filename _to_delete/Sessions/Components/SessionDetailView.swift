import SwiftUI
import SwiftData

struct SessionDetailView: View {
    let session: ExposureSessionResult

    private var duration: String {
        guard let endAt = session.endAt else {
            return String(localized: "Not completed")
        }
        let interval = endAt.timeIntervalSince(session.startAt)
        let minutes = Int(interval / 60)
        let seconds = Int(interval.truncatingRemainder(dividingBy: 60))
        return String(format: "%d:%02d", minutes, seconds)
    }

    private var anxietyDelta: Int? {
        guard let after = session.anxietyAfter else { return nil }
        return session.anxietyBefore - after
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.sm) {
                if let exposure = session.exposure {
                    exposureContextCard(exposure: exposure)
                }

                dateAndStatusCard

                if let after = session.anxietyAfter {
                    AnxietyProgressChart(
                        anxietyBefore: session.anxietyBefore,
                        anxietyAfter: after
                    )
                } else {
                    anxietyBeforeOnlyCard
                }

                statsRow

                if !session.notes.isEmpty {
                    notesCard
                }
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.xxl)
        }
        .homeBackground()
        .navigationTitle(String(localized: "Session details"))
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Exposure Context (top — gives session meaning)

    private func exposureContextCard(exposure: Exposure) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "leaf")
                .font(.system(size: IconSize.glyph, weight: .medium))
                .foregroundStyle(AppColors.primary)
                .iconContainer(
                    size: IconSize.card,
                    backgroundColor: AppColors.primaryLight,
                    cornerRadius: CornerRadius.sm
                )
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(exposure.localizedTitle)
                    .appFont(.bodyMedium)
                    .foregroundStyle(TextColors.primary)
                    .lineLimit(1)
                Text(String(localized: "Exposure"))
                    .appFont(.small)
                    .foregroundStyle(TextColors.secondary)
            }

            Spacer(minLength: 0)
        }
        .cardStyle()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(format: String(localized: "Exposure: %@"), exposure.localizedTitle))
    }

    // MARK: - Date & Status

    private var dateAndStatusCard: some View {
        HStack(spacing: Spacing.sm) {
            VStack(alignment: .leading, spacing: 2) {
                Text(String(localized: "Session date"))
                    .appFont(.caption)
                    .foregroundStyle(TextColors.secondary)
                Label(session.startAt.formatted(date: .abbreviated, time: .shortened), systemImage: "calendar")
                    .appFont(.bodyMedium)
                    .foregroundStyle(TextColors.primary)
            }

            Spacer()

            Image(systemName: session.endAt != nil ? "checkmark.circle.fill" : "ellipsis.circle")
                .font(.system(size: 22))
                .foregroundStyle(session.endAt != nil ? AppColors.positive : AppColors.gray400)
                .accessibilityLabel(session.endAt != nil ? String(localized: "Completed") : String(localized: "In progress"))
        }
        .cardStyle()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(format: String(localized: "Session date: %@"), session.startAt.formatted(date: .long, time: .shortened)))
    }

    // MARK: - Anxiety Before Only (no "After" recorded)

    private var anxietyBeforeOnlyCard: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "gauge")
                .font(.system(size: IconSize.glyph, weight: .medium))
                .foregroundStyle(AppColors.primary)
                .iconContainer(
                    size: IconSize.card,
                    backgroundColor: AppColors.primaryLight,
                    cornerRadius: CornerRadius.sm
                )
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(String(localized: "Anxiety before"))
                    .appFont(.small)
                    .foregroundStyle(TextColors.secondary)
                Text("\(session.anxietyBefore) / 10")
                    .appFont(.bodyMedium)
                    .foregroundStyle(AppColors.anxietyColor(for: session.anxietyBefore))
                    .monospacedDigit()
            }

            Spacer()
        }
        .cardStyle()
    }

    // MARK: - Stats Row: Duration + Delta

    private var statsRow: some View {
        HStack(spacing: 0) {
            statCell(
                icon: "timer",
                value: duration,
                label: String(localized: "Duration"),
                color: AppColors.State.warning
            )

            if let delta = anxietyDelta {
                Divider().frame(height: 32)
                deltaCell(delta: delta)
            }
        }
        .cardStyle(cornerRadius: CornerRadius.lg, padding: 0)
    }

    private func statCell(icon: String, value: String, label: String, color: Color) -> some View {
        HStack(spacing: Spacing.xxs) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(color)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .appFont(.bodyMedium)
                    .foregroundStyle(TextColors.primary)
                    .monospacedDigit()
                Text(label)
                    .appFont(.small)
                    .foregroundStyle(TextColors.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.sm)
        .padding(.horizontal, Spacing.sm)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    private func deltaCell(delta: Int) -> some View {
        let color: Color = delta > 0 ? AppColors.positive : (delta < 0 ? AppColors.primary : AppColors.State.warning)
        let icon = delta > 0 ? "arrow.down" : (delta < 0 ? "arrow.up" : "minus")
        let deltaText = delta == 0 ? "0" : "\(abs(delta))"

        return HStack(spacing: Spacing.xxs) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(color)
            VStack(alignment: .leading, spacing: 2) {
                Text(deltaText)
                    .appFont(.bodyMedium)
                    .foregroundStyle(color)
                    .monospacedDigit()
                Text(String(localized: "Change"))
                    .appFont(.small)
                    .foregroundStyle(TextColors.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.sm)
        .padding(.horizontal, Spacing.sm)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(format: String(localized: "Change %@"), deltaText))
    }

    // MARK: - Notes

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            SectionLabel(text: String(localized: "Notes"))
            Text(session.notes)
                .appFont(.body)
                .foregroundStyle(TextColors.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(format: String(localized: "Notes: %@"), session.notes))
    }
}
