import SwiftUI

// MARK: - BASessionCard
//
// Rich session card with three distinct visual states: planned, active, completed.
// Accepts callbacks for primary actions so the parent owns mutation logic.

struct BASessionCard: View {
    let session: BASession
    let onStart: () -> Void
    let onComplete: () -> Void
    var hasActiveSession: Bool = false

    var body: some View {
        Group {
            switch session.status {
            case .planned:   plannedContent
            case .active:    activeContent
            case .completed: completedContent
            case .cancelled: EmptyView()
            }
        }
        .cardStyle(cornerRadius: CornerRadius.md, padding: Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Planned

    private var plannedContent: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            HStack(alignment: .center, spacing: Spacing.xxs) {
                // Clock + time
                Image(systemName: "clock")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(TextColors.secondary)

                Text(timeString)
                    .appFont(.smallMedium)
                    .foregroundStyle(TextColors.secondary)
                    .monospacedDigit()

                // Activity name
                Text(activityTitle)
                    .appFont(.bodyMedium)
                    .foregroundStyle(TextColors.primary)
                    .lineLimit(1)

                Spacer(minLength: Spacing.xxs)

                // Action buttons
                HStack(spacing: Spacing.xxs) {
                    startButton
                    doneButton
                }
            }

            // Mood before row
            Text(
                String(
                    format: String(localized: "Mood before: %d/10"),
                    session.moodBefore
                )
            )
            .appFont(.small)
            .foregroundStyle(TextColors.secondary)
        }
    }

    private var startButton: some View {
        Button {
            HapticFeedback.medium()
            onStart()
        } label: {
            Text(String(localized: "Start"))
                .appFont(.buttonSmall)
                .foregroundStyle(.white)
                .padding(.horizontal, Spacing.xs)
                .padding(.vertical, Spacing.xxxs)
                .background(Capsule().fill(hasActiveSession ? AppColors.gray300 : AppColors.positive))
        }
        .buttonStyle(.plain)
        .disabled(hasActiveSession)
    }

    private var doneButton: some View {
        Button {
            HapticFeedback.medium()
            onComplete()
        } label: {
            Text(String(localized: "Done"))
                .appFont(.buttonSmall)
                .foregroundStyle(AppColors.positive)
                .padding(.horizontal, Spacing.xs)
                .padding(.vertical, Spacing.xxxs)
                .background {
                    Capsule().strokeBorder(AppColors.positive, lineWidth: 1.5)
                }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Active

    private var activeContent: some View {
        HStack(spacing: Spacing.xs) {
            PulsingIndicator()
            Text(String(localized: "In progress..."))
                .appFont(.bodyMedium)
                .foregroundStyle(TextColors.primary)
            Spacer()
        }
    }

    // MARK: - Completed

    private var completedContent: some View {
        HStack(alignment: .top, spacing: Spacing.xs) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: IconSize.glyph, weight: .medium))
                .foregroundStyle(AppColors.positive)
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: Spacing.xxxs) {
                Text(activityTitle)
                    .appFont(.bodyMedium)
                    .foregroundStyle(TextColors.primary)
                    .lineLimit(1)

                if let delta = session.moodDelta, let after = session.moodAfter {
                    moodDeltaView(before: session.moodBefore, after: after, delta: delta)
                }
            }

            Spacer(minLength: 0)
        }
    }

    // MARK: - Mood Delta

    @ViewBuilder
    private func moodDeltaView(before: Int, after: Int, delta: Int) -> some View {
        let deltaSign = delta > 0 ? "+" : ""
        let deltaColor: Color = {
            if delta > 0 { return AppColors.positive }
            if delta == 0 { return TextColors.secondary }
            return AppColors.gray400
        }()

        VStack(alignment: .leading, spacing: Spacing.xxxs) {
            HStack(spacing: Spacing.xxxs) {
                Text(String(format: String(localized: "Mood: %d → %d"), before, after))
                    .appFont(.small)
                    .foregroundStyle(TextColors.secondary)

                Text("(\(deltaSign)\(delta))")
                    .appFont(.smallMedium)
                    .foregroundStyle(deltaColor)
            }

            if delta < 0 {
                Text(String(localized: "Sometimes improvement comes later"))
                    .appFont(.small)
                    .foregroundStyle(TextColors.tertiary)
            }
        }
    }

    // MARK: - Helpers

    private var timeString: String {
        session.scheduledFor.formatted(.dateTime.hour().minute())
    }

    private var activityTitle: String {
        session.activity?.localizedTitle ?? String(localized: "Activity")
    }
}

// MARK: - PulsingIndicator

private struct PulsingIndicator: View {
    @State private var isPulsing = false

    var body: some View {
        Circle()
            .fill(AppColors.positive)
            .frame(width: Spacing.xxs, height: Spacing.xxs)
            .scaleEffect(isPulsing ? 1.5 : 1.0)
            .opacity(isPulsing ? 0.5 : 1.0)
            .animation(
                .easeInOut(duration: 0.9).repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear { isPulsing = true }
    }
}

// MARK: - Preview

#Preview("Planned") {
    let activity = BAActivity(title: "Morning walk", lifeValueRaw: "health")
    let session = BASession(
        activity: activity,
        moodBefore: 4,
        scheduledFor: Date()
    )
    return BASessionCard(session: session, onStart: {}, onComplete: {})
        .padding(Spacing.sm)
        .background(AppColors.gray100)
}

#Preview("Completed – positive delta") {
    let activity = BAActivity(title: "Call a friend", lifeValueRaw: "relationships")
    let session = BASession(
        activity: activity,
        statusRaw: BAStatus.completed.rawValue,
        moodBefore: 3,
        moodAfter: 7,
        scheduledFor: Date()
    )
    return BASessionCard(session: session, onStart: {}, onComplete: {})
        .padding(Spacing.sm)
        .background(AppColors.gray100)
}

#Preview("Completed – negative delta") {
    let activity = BAActivity(title: "Read a book", lifeValueRaw: "learning")
    let session = BASession(
        activity: activity,
        statusRaw: BAStatus.completed.rawValue,
        moodBefore: 6,
        moodAfter: 4,
        scheduledFor: Date()
    )
    return BASessionCard(session: session, onStart: {}, onComplete: {})
        .padding(Spacing.sm)
        .background(AppColors.gray100)
}

#Preview("Active") {
    let activity = BAActivity(title: "Journaling", lifeValueRaw: "mindfulness")
    let session = BASession(
        activity: activity,
        statusRaw: BAStatus.active.rawValue,
        moodBefore: 5,
        scheduledFor: Date()
    )
    return BASessionCard(session: session, onStart: {}, onComplete: {})
        .padding(Spacing.sm)
        .background(AppColors.gray100)
}
