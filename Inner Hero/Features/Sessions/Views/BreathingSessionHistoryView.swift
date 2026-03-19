import SwiftUI
import SwiftData

struct BreathingSessionHistoryView: View {
    let patternType: BreathingPatternType
    let title: String

    @Query(sort: \BreathingSessionResult.performedAt, order: .reverse) private var allSessions: [BreathingSessionResult]

    private var sessions: [BreathingSessionResult] {
        allSessions.filter { $0.patternType == patternType }
    }

    private var totalDuration: TimeInterval {
        sessions.reduce(0) { $0 + $1.duration }
    }

    var body: some View {
        Group {
            if sessions.isEmpty {
                emptyState
            } else {
                sessionList
            }
        }
        .homeBackground()
        .navigationTitle(String(localized: "History"))
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Session List

    private var sessionList: some View {
        ScrollView {
            VStack(spacing: Spacing.sm) {
                summaryRow
                    .padding(.horizontal, Spacing.sm)
                    .padding(.top, Spacing.md)

                VStack(spacing: Spacing.xxs) {
                    ForEach(sessions) { session in
                        BreathingSessionHistoryRowView(session: session)
                    }
                }
                .padding(.horizontal, Spacing.sm)
                .padding(.bottom, Spacing.xxl)
            }
        }
    }

    private var summaryRow: some View {
        HStack(spacing: 0) {
            statItem(
                icon: "chart.bar.fill",
                value: "\(sessions.count)",
                label: String(localized: "sessions"),
                color: AppColors.positive
            )
            Divider().frame(height: 28)
            statItem(
                icon: "timer",
                value: formatDuration(totalDuration / Double(max(sessions.count, 1))),
                label: String(localized: "avg"),
                color: AppColors.State.warning
            )
            Divider().frame(height: 28)
            statItem(
                icon: "clock",
                value: formatDuration(totalDuration),
                label: String(localized: "total"),
                color: AppColors.positive
            )
        }
        .cardStyle(cornerRadius: CornerRadius.lg, padding: 0)
    }

    private func statItem(icon: String, value: String, label: String, color: Color) -> some View {
        HStack(spacing: Spacing.xxs) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(color)
            Text(value)
                .appFont(.bodyMedium)
                .foregroundStyle(TextColors.primary)
                .monospacedDigit()
            Text(label)
                .appFont(.small)
                .foregroundStyle(TextColors.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.sm)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "wind")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(AppColors.positive.opacity(0.6))
                .accessibilityHidden(true)

            VStack(spacing: Spacing.xxs) {
                Text(String(localized: "No sessions"))
                    .appFont(.h2)
                    .foregroundStyle(TextColors.primary)

                Text(String(format: String(localized: "Session history for \"%@\" is empty"), title))
                    .appFont(.body)
                    .foregroundStyle(TextColors.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.xxxl)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let totalSeconds = Int(duration.rounded())
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return "\(minutes):\(String(format: "%02d", seconds))"
    }
}

// MARK: - Session Row

private struct BreathingSessionHistoryRowView: View {
    let session: BreathingSessionResult

    private var formattedDate: String {
        session.performedAt.formatted(date: .abbreviated, time: .shortened)
    }

    private var durationText: String {
        let totalSeconds = Int(session.duration.rounded())
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return "\(minutes):\(String(format: "%02d", seconds))"
    }

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "wind")
                .font(.system(size: IconSize.glyph, weight: .medium))
                .foregroundStyle(AppColors.positive)
                .iconContainer(
                    size: IconSize.card,
                    backgroundColor: AppColors.positive.opacity(Opacity.softBackground),
                    cornerRadius: CornerRadius.sm
                )
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(formattedDate)
                    .appFont(.bodyMedium)
                    .foregroundStyle(TextColors.primary)

                HStack(spacing: Spacing.xxs) {
                    Image(systemName: "timer")
                        .font(.system(size: 11))
                    Text(durationText)
                        .appFont(.smallMedium)
                        .monospacedDigit()
                }
                .foregroundStyle(TextColors.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .cardStyle(cornerRadius: CornerRadius.lg, padding: 0)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(format: String(localized: "Session: %@, duration %@"), formattedDate, durationText))
    }
}

#Preview {
    NavigationStack {
        BreathingSessionHistoryView(patternType: .box, title: "Box breathing")
    }
    .modelContainer(for: [BreathingSessionResult.self], inMemory: true)
}
