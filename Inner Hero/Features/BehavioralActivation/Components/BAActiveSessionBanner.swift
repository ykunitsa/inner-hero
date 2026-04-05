import SwiftUI

// MARK: - BAActiveSessionBanner
//
// Sticky banner shown when a BA session is active. Displays the activity name,
// a live elapsed-time counter, and an "In progress" pill. Tapping calls onTap().
//
// Usage site should apply:
//   .transition(.move(edge: .top).combined(with: .opacity))

struct BAActiveSessionBanner: View {
    let session: BASession
    var onTap: () -> Void

    var body: some View {
        Button {
            HapticFeedback.selection()
            onTap()
        } label: {
            HStack(spacing: Spacing.sm) {
                // Left: pulsing dot + labels
                HStack(spacing: Spacing.xs) {
                    PulsingDotBA()

                    VStack(alignment: .leading, spacing: 2) {
                        // "In progress" pill
                        Text(String(localized: "In progress"))
                            .appFont(.caption)
                            .foregroundStyle(AppColors.positive)
                            .textCase(.uppercase)
                            .padding(.horizontal, Spacing.xxs)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(AppColors.positive.opacity(Opacity.subtleBackground))
                            )

                        // Activity name
                        Text(session.activity?.localizedTitle ?? String(localized: "Activity"))
                            .appFont(.bodyMedium)
                            .foregroundStyle(TextColors.primary)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: Spacing.xxs)

                // Elapsed timer
                TimelineView(.periodic(from: .now, by: 1.0)) { _ in
                    Text(elapsedTimeString)
                        .appFont(.smallMedium)
                        .foregroundStyle(TextColors.secondary)
                        .monospacedDigit()
                }

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(TextColors.tertiary)
            }
            .cardStyle(cornerRadius: CornerRadius.md, padding: Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                    .fill(AppColors.positive.opacity(0.12))
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                    .strokeBorder(AppColors.positive.opacity(0.25), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(
            format: String(localized: "Active session: %@"),
            session.activity?.localizedTitle ?? String(localized: "Activity")
        ))
        .accessibilityHint(String(localized: "Double tap to open"))
    }

    // MARK: - Helpers

    private var elapsedTimeString: String {
        let elapsed = session.startedAt.map { Date().timeIntervalSince($0) } ?? 0
        let totalSeconds = Int(max(0, elapsed))
        let hours   = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

// MARK: - PulsingDotBA

private struct PulsingDotBA: View {
    @State private var pulsing = false

    var body: some View {
        ZStack {
            Circle()
                .fill(AppColors.positive.opacity(0.3))
                .frame(width: 16, height: 16)
                .scaleEffect(pulsing ? 1.6 : 1.0)
                .opacity(pulsing ? 0 : 1)

            Circle()
                .fill(AppColors.positive)
                .frame(width: 8, height: 8)
        }
        .frame(width: 20, height: 20)
        .onAppear {
            withAnimation(
                .easeOut(duration: 1.2).repeatForever(autoreverses: false)
            ) {
                pulsing = true
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Preview

#Preview {
    let activity = BAActivity(title: "Morning walk", lifeValueRaw: "health")
    let session = BASession(
        activity: activity,
        statusRaw: BAStatus.active.rawValue,
        moodBefore: 5,
        scheduledFor: Date(),
        startedAt: Date().addingTimeInterval(-137)
    )
    return BAActiveSessionBanner(session: session, onTap: {})
        .padding(Spacing.md)
        .background(AppColors.gray100)
}
