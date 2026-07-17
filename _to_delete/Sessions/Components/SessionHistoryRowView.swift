import SwiftUI
import SwiftData

struct SessionHistoryRowView: View {
    let session: ExposureSessionResult

    private var formattedDate: String {
        session.startAt.formatted(date: .abbreviated, time: .shortened)
    }

    private var duration: String? {
        guard let endAt = session.endAt else { return nil }
        let interval = endAt.timeIntervalSince(session.startAt)
        let minutes = Int(interval / 60)
        return String(format: String(localized: "%d min"), minutes)
    }

    private var anxietyDelta: Int? {
        guard let after = session.anxietyAfter else { return nil }
        return session.anxietyBefore - after
    }

    private var deltaColor: Color {
        guard let delta = anxietyDelta else { return AppColors.gray400 }
        if delta > 0 { return AppColors.positive }
        if delta < 0 { return AppColors.primary }
        return AppColors.State.warning
    }

    private var deltaIcon: String {
        guard let delta = anxietyDelta else { return "minus" }
        if delta > 0 { return "arrow.down" }
        if delta < 0 { return "arrow.up" }
        return "minus"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            dateRow
            anxietyRow
            if !session.notes.isEmpty {
                notesRow
            }
        }
        .padding(.vertical, Spacing.xxs)
    }

    private var dateRow: some View {
        HStack {
            Label(formattedDate, systemImage: "calendar")
                .appFont(.bodyMedium)
                .foregroundStyle(TextColors.primary)
                .accessibilityLabel(String(format: String(localized: "Session date: %@"), formattedDate))

            Spacer()

            if let duration {
                HStack(spacing: Spacing.xxxs) {
                    Image(systemName: "timer")
                        .font(.system(size: 11))
                    Text(duration)
                        .appFont(.smallMedium)
                        .monospacedDigit()
                }
                .foregroundStyle(TextColors.secondary)
                .accessibilityLabel(String(format: String(localized: "Duration: %@"), duration))
            }
        }
    }

    private var anxietyRow: some View {
        HStack(spacing: Spacing.xs) {
            anxietyBadge(
                label: String(localized: "Before"),
                value: session.anxietyBefore,
                color: AppColors.primary
            )

            Image(systemName: "arrow.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(AppColors.gray400)
                .accessibilityHidden(true)

            if let after = session.anxietyAfter {
                anxietyBadge(
                    label: String(localized: "After"),
                    value: after,
                    color: AppColors.anxietyColor(for: after)
                )

                Spacer()

                deltaBadge
            } else {
                Spacer()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(anxietyAccessibilityLabel)
    }

    private func anxietyBadge(label: String, value: Int, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .appFont(.caption)
                .foregroundStyle(TextColors.secondary)
            Text("\(value)")
                .appFont(.h3)
                .foregroundStyle(color)
                .monospacedDigit()
        }
    }

    @ViewBuilder
    private var deltaBadge: some View {
        if let delta = anxietyDelta {
            HStack(spacing: Spacing.xxxs) {
                Image(systemName: deltaIcon)
                    .font(.system(size: 11, weight: .semibold))
                Text(delta == 0 ? "0" : "\(abs(delta))")
                    .appFont(.smallMedium)
                    .monospacedDigit()
            }
            .foregroundStyle(deltaColor)
            .padding(.horizontal, Spacing.xxs)
            .padding(.vertical, Spacing.xxxs + 2)
            .background(
                Capsule()
                    .fill(deltaColor.opacity(Opacity.subtleBackground))
            )
        }
    }

    private var notesRow: some View {
        Text(session.notes)
            .appFont(.body)
            .foregroundStyle(TextColors.secondary)
            .lineLimit(2)
            .accessibilityLabel(String(format: String(localized: "Notes: %@"), session.notes))
    }

    private var anxietyAccessibilityLabel: String {
        var label = "Anxiety before: \(session.anxietyBefore)"
        if let after = session.anxietyAfter {
            label += ", after: \(after)"
            if let delta = anxietyDelta {
                label += delta > 0 ? ", decreased by \(delta)" : (delta < 0 ? ", increased by \(abs(delta))" : ", no change")
            }
        }
        return label
    }
}
