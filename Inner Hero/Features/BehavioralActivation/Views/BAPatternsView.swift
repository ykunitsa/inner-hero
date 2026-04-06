import SwiftUI
import SwiftData

struct BAPatternsView: View {
    @Query private var sessions: [BASession]

    @State private var barsVisible = false

    private static let requiredCount = 5

    // MARK: - Computed

    private var completedSessions: [BASession] {
        sessions.filter { $0.status == .completed }
    }

    private var last14DaysSessions: [BASession] {
        BAInsightService.sessionsInLastDays(14, from: sessions)
    }

    private var averageMoodDelta: Double? {
        BAInsightService.averageMoodDelta(for: sessions)
    }

    private var topValues: [(LifeValue, Double)] {
        BAInsightService.topLifeValues(sessions: sessions, limit: 3)
    }

    private var maxTopDelta: Double {
        topValues.map(\.1).max() ?? 1.0
    }

    private var keyInsight: String? {
        BAInsightService.keyInsightText(sessions: sessions)
    }

    private var remaining: Int {
        max(0, Self.requiredCount - completedSessions.count)
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            if completedSessions.count < Self.requiredCount {
                emptyState
                    .padding(.top, Spacing.xxl)
                    .frame(maxWidth: .infinity)
            } else {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    statsCard

                    if !topValues.isEmpty {
                        topValuesSection
                    }

                    if let insight = keyInsight {
                        insightCard(text: insight)
                    }
                }
                .padding(.horizontal, Spacing.sm)
                .padding(.top, Spacing.md)
                .padding(.bottom, Spacing.xxl)
            }
        }
        .homeBackground()
        .onAppear {
            withAnimation(AppAnimation.spring.delay(0.2)) {
                barsVisible = true
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "chart.bar")
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(AppColors.accent.opacity(0.7))
                .accessibilityHidden(true)

            VStack(spacing: Spacing.xxs) {
                Text(String(localized: "Not enough data yet"))
                    .appFont(.h2)
                    .foregroundStyle(TextColors.primary)
                    .multilineTextAlignment(.center)

                Text(
                    remaining == 1
                        ? String(localized: "Complete 1 more activity to see your patterns.")
                        : String(format: String(localized: "Complete %d more activities to see your patterns."), remaining)
                )
                .appFont(.body)
                .foregroundStyle(TextColors.secondary)
                .multilineTextAlignment(.center)
            }

            emptyStateProgress
        }
        .padding(.horizontal, Spacing.lg)
        .accessibilityElement(children: .combine)
    }

    private var emptyStateProgress: some View {
        let completed = completedSessions.count
        let total = Self.requiredCount
        let fraction = Double(completed) / Double(total)

        return VStack(spacing: Spacing.xxs) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AppColors.gray200)
                        .frame(height: 8)

                    Capsule()
                        .fill(AppColors.accent)
                        .frame(width: geo.size.width * CGFloat(fraction), height: 8)
                        .animation(AppAnimation.spring, value: fraction)
                }
            }
            .frame(height: 8)

            HStack {
                Text(
                    String(
                        format: String(localized: "%d / %d activities"),
                        completed, total
                    )
                )
                .appFont(.small)
                .foregroundStyle(TextColors.tertiary)
                Spacer()
            }
        }
    }

    // MARK: - Stats Card

    private var statsCard: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            HStack(spacing: Spacing.xxs) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppColors.positive)

                Text(
                    String(
                        format: String(localized: "Last 14 days: %d activities completed"),
                        last14DaysSessions.count
                    )
                )
                .appFont(.bodyMedium)
                .foregroundStyle(TextColors.primary)
            }

            if let delta = averageMoodDelta {
                Divider()
                    .padding(.vertical, 2)

                HStack(spacing: Spacing.xxs) {
                    Image(systemName: delta >= 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(delta >= 0 ? AppColors.positive : AppColors.primary)

                    Text(
                        String(
                            format: String(localized: "Average mood shift: %@%.1f"),
                            delta >= 0 ? "+" : "",
                            delta
                        )
                    )
                    .appFont(.bodyMedium)
                    .foregroundStyle(TextColors.primary)
                }
            }
        }
        .padding(Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                .strokeBorder(AppColors.gray200, lineWidth: 1)
        )
    }

    // MARK: - Top Values Section

    private var topValuesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(String(localized: "What works best for you"))
                .appFont(.h2)
                .foregroundStyle(TextColors.primary)

            VStack(spacing: Spacing.xxs) {
                ForEach(topValues, id: \.0) { value, delta in
                    LifeValueInsightRow(
                        value: value,
                        delta: delta,
                        fraction: max(0, min(1, delta / max(maxTopDelta, 0.001))),
                        barsVisible: barsVisible
                    )
                }
            }
        }
    }

    // MARK: - Key Insight Card

    private func insightCard(text: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Image(systemName: "sparkles")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(AppColors.accent)
                .padding(.top, 2)

            Text(text)
                .appFont(.body)
                .italic()
                .foregroundStyle(TextColors.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.accent.opacity(Opacity.subtleBackground))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                .strokeBorder(AppColors.accent.opacity(Opacity.subtleBorder), lineWidth: 1)
        )
    }
}

// MARK: - LifeValueInsightRow

private struct LifeValueInsightRow: View {
    let value: LifeValue
    let delta: Double
    let fraction: Double
    let barsVisible: Bool

    private var deltaLabel: String {
        String(
            format: String(localized: "%@%.1f average"),
            delta >= 0 ? "+" : "",
            delta
        )
    }

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: value.systemIconName)
                .font(.system(size: IconSize.glyph, weight: .medium))
                .foregroundStyle(AppColors.positive)
                .iconContainer(
                    size: IconSize.card,
                    backgroundColor: AppColors.positiveLight,
                    cornerRadius: CornerRadius.sm
                )

            VStack(alignment: .leading, spacing: Spacing.xxxs) {
                HStack {
                    Text(value.localizedName)
                        .appFont(.bodyMedium)
                        .foregroundStyle(TextColors.primary)

                    Spacer()

                    Text(deltaLabel)
                        .appFont(.smallMedium)
                        .foregroundStyle(AppColors.positive)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(AppColors.gray200)
                            .frame(height: 6)

                        Capsule()
                            .fill(AppColors.positive)
                            .frame(
                                width: barsVisible
                                    ? geo.size.width * CGFloat(fraction)
                                    : 0,
                                height: 6
                            )
                            .animation(AppAnimation.spring, value: barsVisible)
                    }
                }
                .frame(height: 6)
            }
        }
        .padding(Spacing.sm)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                .strokeBorder(AppColors.gray200, lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview("Has enough data") {
    let calendar = Calendar.current
    let activity = BAActivity(
        title: "Walk outside",
        lifeValueRaw: LifeValue.body.rawValue
    )
    let activity2 = BAActivity(
        title: "Call a friend",
        lifeValueRaw: LifeValue.connection.rawValue
    )
    let activity3 = BAActivity(
        title: "Sketch something",
        lifeValueRaw: LifeValue.creativity.rawValue
    )

    let sessions: [BASession] = (0..<8).map { i in
        let lifeActivity = [activity, activity2, activity3][i % 3]
        let session = BASession(
            activity: lifeActivity,
            moodBefore: Int.random(in: 2...5),
            scheduledFor: calendar.date(byAdding: .day, value: -i, to: Date()) ?? Date()
        )
        session.complete(moodAfter: session.moodBefore + Int.random(in: 1...4), outcome: .better)
        return session
    }

    NavigationStack {
        BAPatternsView()
            .navigationTitle("Patterns")
            .navigationBarTitleDisplayMode(.large)
    }
    .modelContainer(
        { () -> ModelContainer in
            let container = try! ModelContainer(
                for: BASession.self, BAActivity.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            sessions.forEach { container.mainContext.insert($0) }
            return container
        }()
    )
}

#Preview("Not enough data") {
    NavigationStack {
        BAPatternsView()
            .navigationTitle("Patterns")
            .navigationBarTitleDisplayMode(.large)
    }
    .modelContainer(for: [BASession.self, BAActivity.self], inMemory: true)
}
