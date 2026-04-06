import SwiftUI
import SwiftData

// MARK: - BASessionSummaryCard

struct BASessionSummaryCard: View {
    let session: BASession

    private var timeString: String {
        session.scheduledFor.formatted(.dateTime.hour().minute())
    }

    private var badgeStyle: AppBadge.BadgeStyle {
        session.status == .completed ? .success : .accent
    }

    private var statusLabel: String {
        switch session.status {
        case .planned:   return String(localized: "Planned")
        case .active:    return String(localized: "Active")
        case .completed: return String(localized: "Done")
        case .cancelled: return String(localized: "Cancelled")
        }
    }

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: session.activity?.lifeValue.systemIconName ?? "figure.walk")
                .font(.system(size: IconSize.glyph, weight: .medium))
                .foregroundStyle(AppColors.accent)
                .iconContainer(
                    size: IconSize.card,
                    backgroundColor: AppColors.accentLight,
                    cornerRadius: CornerRadius.sm
                )

            VStack(alignment: .leading, spacing: Spacing.xxxs) {
                Text(session.activity?.localizedTitle ?? String(localized: "Activity"))
                    .appFont(.bodyMedium)
                    .foregroundStyle(TextColors.primary)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text(timeString)
                        .appFont(.small)
                        .foregroundStyle(TextColors.secondary)

                    if let value = session.activity?.lifeValue {
                        Text("·")
                            .appFont(.small)
                            .foregroundStyle(TextColors.tertiary)
                        Text(value.localizedName)
                            .appFont(.small)
                            .foregroundStyle(TextColors.secondary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer(minLength: Spacing.xxs)

            VStack(alignment: .trailing, spacing: Spacing.xxxs) {
                AppBadge(text: statusLabel, style: badgeStyle)

                if let delta = session.moodDelta {
                    let sign = delta >= 0 ? "+" : ""
                    Text("\(sign)\(delta)")
                        .appFont(.smallMedium)
                        .foregroundStyle(delta >= 0 ? AppColors.positive : AppColors.primary)
                }
            }
        }
        .cardStyle(cornerRadius: CornerRadius.md, padding: Spacing.sm)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            String(
                format: String(localized: "%@, %@, %@"),
                session.activity?.localizedTitle ?? String(localized: "Activity"),
                timeString,
                statusLabel
            )
        )
    }
}

// MARK: - BATodayView

struct BATodayView: View {
    var onActiveSessionTap: (BASession) -> Void = { _ in }

    @Query(
        filter: #Predicate<BASession> { $0.statusRaw != "cancelled" },
        sort: \BASession.scheduledFor
    ) private var sessions: [BASession]

    @State private var appeared = false

    // MARK: - Computed

    private var todaySessions: [BASession] {
        sessions.filter(\.isToday)
    }

    private var activeSession: BASession? {
        sessions.first { $0.statusRaw == "active" }
    }

    private var todayNonActiveSessions: [BASession] {
        todaySessions.filter { $0.statusRaw != "active" }
    }

    private var weekCompletedSessions: [BASession] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return sessions.filter { $0.status == .completed && $0.scheduledFor >= cutoff }
    }

    private var avgDelta: Double? {
        let deltas = weekCompletedSessions.compactMap { session -> Double? in
            guard let d = session.moodDelta else { return nil }
            return Double(d)
        }
        guard !deltas.isEmpty else { return nil }
        return deltas.reduce(0, +) / Double(deltas.count)
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Spacing.md) {

                // 1. Active session banner
                if let session = activeSession {
                    BAActiveSessionBanner(session: session, onTap: { onActiveSessionTap(session) })
                        .padding(.horizontal, Spacing.sm)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                // 2 & 3. Empty state or session cards
                if todaySessions.isEmpty {
                    emptyState
                        .padding(.top, Spacing.xxl)
                        .frame(maxWidth: .infinity)
                } else {
                    ForEach(
                        Array(todayNonActiveSessions.enumerated()),
                        id: \.element.id
                    ) { index, session in
                        BASessionSummaryCard(session: session)
                            .padding(.horizontal, Spacing.sm)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 12)
                            .animation(
                                AppAnimation.appear.delay(Double(index) * 0.06),
                                value: appeared
                            )
                    }
                }

                // 4. Weekly stats footer
                if !weekCompletedSessions.isEmpty {
                    weekStatsFooter
                        .padding(.horizontal, Spacing.sm)
                }
            }
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.xxl)
            .animation(AppAnimation.spring, value: activeSession?.id)
        }
        .onAppear { appeared = true }
    }

    // MARK: - Subviews

    private var emptyState: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "figure.walk")
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(AppColors.accent.opacity(0.7))
                .accessibilityHidden(true)

            VStack(spacing: Spacing.xxs) {
                Text(String(localized: "Plan something for today"))
                    .appFont(.h2)
                    .foregroundStyle(TextColors.primary)
                    .multilineTextAlignment(.center)
                Text(String(localized: "A single small action can shift how you feel."))
                    .appFont(.body)
                    .foregroundStyle(TextColors.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, Spacing.lg)
        .accessibilityElement(children: .combine)
    }

    private var weekStatsFooter: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            HStack(spacing: Spacing.xxs) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppColors.positive)
                Text(
                    String(
                        format: String(localized: "%d activities completed this week"),
                        weekCompletedSessions.count
                    )
                )
                .appFont(.small)
                .foregroundStyle(TextColors.secondary)
            }

            if let delta = avgDelta {
                let rounded = Int(delta.rounded())
                let sign = rounded >= 0 ? "+" : ""
                HStack(spacing: Spacing.xxs) {
                    Image(systemName: rounded >= 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(rounded >= 0 ? AppColors.positive : AppColors.primary)
                    Text(
                        String(
                            format: String(localized: "Average mood shift: %@%d"),
                            sign, rounded
                        )
                    )
                    .appFont(.small)
                    .foregroundStyle(TextColors.secondary)
                }
            }
        }
        .padding(Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                .fill(AppColors.positive.opacity(Opacity.subtleBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                .strokeBorder(AppColors.positive.opacity(Opacity.subtleBorder), lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Spacing.md) {
                BATodayView()
            }
        }
        .navigationTitle("Today")
    }
    .modelContainer(for: [BASession.self, BAActivity.self], inMemory: true)
}
