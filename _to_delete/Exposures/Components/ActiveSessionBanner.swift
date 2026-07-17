import SwiftUI

// MARK: - ActiveSessionBanner
//
// Sticky banner shown under the navigation bar when an exposure session
// is in progress. Replaces the old ActiveSessionCard (which was inline in the list).
//
// Layout:
//   🟢 pulse dot · "Active session" · exposure title · steps progress · Resume →
//   [+N more]  ← subtle, only when activeSessions.count > 1

struct ActiveSessionBanner: View {
    let session: ExposureSessionResult
    let exposure: Exposure
    /// Number of *additional* unfinished sessions beyond this one
    var extraCount: Int = 0
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: Spacing.xxxs) {
                HStack(spacing: Spacing.xs) {
                    // Pulsing green dot
                    PulsingDot()

                    // Labels
                    VStack(alignment: .leading, spacing: 2) {
                        Text(String(localized: "Active session"))
                            .appFont(.caption)
                            .foregroundStyle(TextColors.secondary)
                            .textCase(.uppercase)

                        Text(exposure.localizedTitle)
                            .appFont(.bodyMedium)
                            .foregroundStyle(TextColors.primary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: Spacing.xxs)

                    // Steps progress badge
                    if !exposure.localizedStepTexts.isEmpty {
                        let completed = session.completedStepIndices.count
                        let total = exposure.localizedStepTexts.count

                        Text("\(completed)/\(total)")
                            .appFont(.smallMedium)
                            .foregroundStyle(AppColors.positive)
                            .monospacedDigit()
                            .padding(.horizontal, Spacing.xxs)
                            .padding(.vertical, Spacing.xxxs)
                            .background(
                                Capsule()
                                    .fill(AppColors.positive.opacity(Opacity.subtleBackground))
                            )
                    }

                    // Resume CTA
                    HStack(spacing: 4) {
                        Text(String(localized: "Resume"))
                            .appFont(.smallMedium)
                            .foregroundStyle(AppColors.primary)

                        Image(systemName: "arrow.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(AppColors.primary)
                    }
                    .padding(.horizontal, Spacing.xs)
                    .padding(.vertical, Spacing.xxxs + 2)
                    .background(
                        Capsule()
                            .fill(AppColors.primary.opacity(Opacity.subtleBackground))
                    )
                }

                // Extra sessions hint
                if extraCount > 0 {
                    Text(String(format: String(localized: "+%d more unfinished"), extraCount))
                        .appFont(.small)
                        .foregroundStyle(TextColors.tertiary)
                        .padding(.leading, Spacing.lg + Spacing.xxs) // align under title
                }
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
                    .shadow(
                        color: .black.opacity(Opacity.lightShadow),
                        radius: 6, y: 2
                    )
            )
            .overlay(
                // Green left accent bar
                HStack {
                    RoundedRectangle(cornerRadius: CornerRadius.sm, style: .continuous)
                        .fill(AppColors.positive)
                        .frame(width: 3)
                    Spacer()
                }
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous))
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(
            format: String(localized: "Continue active session: %@"),
            exposure.localizedTitle
        ))
        .accessibilityHint(String(localized: "Double tap to resume"))
    }
}

// MARK: - PulsingDot

private struct PulsingDot: View {
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
