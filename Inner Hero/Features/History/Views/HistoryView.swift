import SwiftData
import SwiftUI
import UniformTypeIdentifiers

/// The "History" tab (spec §2.3): where you stand, the rule that fired, exposure
/// statistics, the session feed, export.
///
/// A reading screen. The only action is the rule card, and it only exists when a
/// rule actually fired — so the screen has at most one accent (codex §1).
struct HistoryView: View {
    @Binding var path: NavigationPath

    @Query private var exposures: [ExposureLogEntry]
    @Query private var breathingSessions: [BreathingSessionEntry]
    @Query private var pmrSessions: [PMRSessionEntry]
    @Query private var activationEntries: [BALogEntry]

    @State private var viewModel = HistoryViewModel()
    @State private var showBreathing = false
    @State private var showRelaxation = false
    @State private var showExporter = false
    @State private var exportDocument: ExportJSONDocument?
    @State private var showExportError = false

    private var positions: [LadderPosition] {
        viewModel.ladderPositions(
            breathing: breathingSessions, pmr: pmrSessions, activation: activationEntries
        )
    }

    private var rule: ActiveRule? {
        viewModel.activeRule(breathing: breathingSessions, pmr: pmrSessions)
    }

    private var stats: ExposureStats {
        viewModel.exposureStats(exposures)
    }

    private var days: [HistoryDay] {
        viewModel.feed(
            exposures: exposures,
            breathing: breathingSessions,
            pmr: pmrSessions,
            activation: activationEntries
        )
    }

    private var isEmpty: Bool {
        days.isEmpty
    }

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if isEmpty {
                    emptyState
                } else {
                    content
                }
            }
            .homeBackground()
            .navigationTitle(String(localized: "History"))
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: AppRoute.self) { route in
                AppRouteView(route: route)
            }
            .fullScreenCover(isPresented: $showBreathing) {
                BreathingFlowView()
            }
            .fullScreenCover(isPresented: $showRelaxation) {
                PMRFlowView()
            }
            .fileExporter(
                isPresented: $showExporter,
                document: exportDocument,
                contentType: .json,
                defaultFilename: "inner-hero-export"
            ) { result in
                if case .failure = result { showExportError = true }
            }
            .alert(
                String(localized: "Couldn't save the file."),
                isPresented: $showExportError
            ) {
                Button(String(localized: "OK"), role: .cancel) {}
            }
        }
    }

    // MARK: Content

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                ladderBlock
                ruleCard
                exposureBlock
                whatWorksBlock
                feedBlock
                exportButton
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.top, Spacing.xxs)
            .padding(.bottom, Spacing.xxl)
        }
    }

    /// Spec §2.3.1. No section label: this block sits directly under the screen
    /// title, which already names it (plan `11.6-shell.md` §2, decision 10).
    @ViewBuilder
    private var ladderBlock: some View {
        if !positions.isEmpty {
            VStack(spacing: 0) {
                ForEach(positions) { position in
                    StatRow(label: position.exercise, value: position.position)
                }
            }
            .cardStyle(cornerRadius: CornerRadius.lg, padding: Spacing.sm)
        }
    }

    /// Spec §2.3.2. The tap opens the exercise with the value already applied —
    /// History has no session of its own to apply it to, and a rule that led to
    /// a menu would be a menu between icon and action (§1.2).
    @ViewBuilder
    private var ruleCard: some View {
        if let rule {
            LadderRuleRow(text: rule.text, direction: rule.direction) {
                switch rule.exercise {
                case .breathing: showBreathing = true
                case .relaxation: showRelaxation = true
                }
            }
        }
    }

    /// Spec §2.3.3. Absent entirely when there is nothing to divide — three
    /// zeroes would be a statement the data does not support.
    @ViewBuilder
    private var exposureBlock: some View {
        if !stats.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                SectionLabel(text: String(localized: "Exposures"))
                VStack(spacing: 0) {
                    if let stayed = stats.stayed {
                        StatRow(
                            label: String(localized: "stayed"),
                            value: fraction(stayed)
                        )
                    }
                    if let missed = stats.predictionsMissed {
                        StatRow(
                            label: String(localized: "predictions didn't come true"),
                            value: fraction(missed)
                        )
                    }
                    if let clean = stats.withoutSafetyBehaviors {
                        StatRow(
                            label: String(localized: "no safety behaviors"),
                            value: fraction(clean)
                        )
                    }
                }
                .cardStyle(cornerRadius: CornerRadius.lg, padding: Spacing.sm)
            }
        }
    }

    /// Spec §6, "Что работает": the insight card, the activity table, the
    /// closing line. Absent entirely until something has been done *and* rated —
    /// there is no empty version of this block, because an empty finding is not
    /// a finding.
    @ViewBuilder
    private var whatWorksBlock: some View {
        let rows = BAInsights.rows(activationEntries)
        if let summary = BAInsights.summary(rows) {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                SectionLabel(text: String(localized: "What works"))

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    if let insight = BAInsights.insight(rows) {
                        Text(insightText(insight))
                            .appFont(.bodyMedium)
                            .foregroundStyle(TextColors.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    VStack(spacing: 0) {
                        ForEach(rows) { row in
                            StatRow(
                                label: row.title,
                                value: fraction((done: row.beatForecast, total: row.rated))
                            )
                        }
                    }

                    Text(
                        String(
                            format: String(localized: "Better than expected overall: %1$d of %2$d"),
                            summary.beatForecast, summary.rated
                        )
                    )
                    .appFont(.small)
                    .foregroundStyle(TextColors.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                }
                .cardStyle(cornerRadius: CornerRadius.lg, padding: Spacing.sm)
            }
        }
    }

    /// Spec §6 words this as «Прогулку ты недооцениваешь: 7 из 8 вышло лучше,
    /// чем думал». Two things stop that exact sentence from shipping: activity
    /// titles are free text and Russian would need them declined into the
    /// accusative, which cannot be done programmatically; and «думал» carries
    /// gender. The fact itself is the insight, so it is stated plainly.
    private func insightText(_ insight: BAInsights.Insight) -> String {
        String(
            format: String(localized: "%1$@ — %2$d of %3$d turned out better than expected"),
            insight.title, insight.beatForecast, insight.rated
        )
    }

    private var feedBlock: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            SectionLabel(text: String(localized: "Sessions"))

            ForEach(days) { day in
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(day.id.formatted(.dateTime.day().month(.wide)))
                        .appFont(.small)
                        .foregroundStyle(TextColors.tertiary)

                    VStack(spacing: Spacing.xs) {
                        ForEach(day.items) { item in
                            SessionFeedRow(item: item)
                        }
                    }
                    .cardStyle(cornerRadius: CornerRadius.lg, padding: Spacing.sm)
                }
            }
        }
    }

    /// Spec §2.3.5, with one neutral label: the app never learns whether the
    /// user has a therapist, and §7 forbids asking (plan `11.6-shell.md` §2,
    /// decision 9).
    private var exportButton: some View {
        Button {
            prepareExport()
        } label: {
            Text(String(localized: "Export data"))
                .appFont(.buttonSmall)
                .foregroundStyle(AppColors.accent)
                .frame(maxWidth: .infinity, minHeight: TouchTarget.minimum)
        }
        .buttonStyle(.plain)
        .padding(.top, Spacing.sm)
    }

    /// Spec §2.3, empty state. A quiet fact, not an invitation to go do an
    /// exercise — this screen does not recruit (§1.1).
    private var emptyState: some View {
        VStack {
            Spacer()
            Text(String(localized: "Nothing here yet"))
                .appFont(.body)
                .foregroundStyle(TextColors.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Actions

    private func prepareExport() {
        let payload = HistoryExport.payload(
            exposures: exposures,
            breathing: breathingSessions,
            relaxation: pmrSessions,
            activation: activationEntries
        )
        do {
            exportDocument = ExportJSONDocument(data: try HistoryExport.data(for: payload))
            showExporter = true
        } catch {
            showExportError = true
        }
    }

    private func fraction(_ value: (done: Int, total: Int)) -> String {
        String(format: String(localized: "%1$d of %2$d"), value.done, value.total)
    }
}

#Preview {
    HistoryView(path: .constant(NavigationPath()))
        .environment(ArticlesStore())
        .environment(NotificationManager())
        .modelContainer(
            for: [
                ExposureLogEntry.self, BreathingSessionEntry.self,
                PMRSessionEntry.self, BAActivity.self, BALogEntry.self,
            ],
            inMemory: true
        )
}
