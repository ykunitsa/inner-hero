import SwiftUI
import Charts

struct ExposureProgressChart: View {
    let dataPoints: [ChartDataPoint]
    @State private var selectedPeriod: TimePeriod = .month
    @State private var selectedDataPoint: ChartDataPoint?

    private var filteredDataPoints: [ChartDataPoint] {
        let cutoffDate = Calendar.current.date(
            byAdding: .day,
            value: -selectedPeriod.daysCount,
            to: Date()
        ) ?? Date()
        return dataPoints
            .filter { $0.date >= cutoffDate }
            .sorted { $0.date < $1.date }
    }

    private var statistics: ChartStatistics? {
        ChartStatistics.calculate(from: filteredDataPoints)
    }

    private var latestDataPoint: ChartDataPoint? { filteredDataPoints.last }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            headerSection
            periodSelector
            legendView
            chartView
            if let stats = statistics, !filteredDataPoints.isEmpty {
                statsRow(stats: stats)
            }
        }
        .cardStyle()
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Anxiety progress chart")
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.xxs) {
            VStack(alignment: .leading, spacing: 2) {
                Label(String(localized: "Anxiety dynamics"), systemImage: "chart.line.uptrend.xyaxis")
                    .appFont(.h3)
                    .foregroundStyle(TextColors.primary)
                    .accessibilityAddTraits(.isHeader)

                if let latest = latestDataPoint {
                    HStack(alignment: .firstTextBaseline, spacing: Spacing.xxs) {
                        Text("\(latest.anxietyAfter ?? latest.anxietyBefore)")
                            .appFont(.monoLarge)
                            .foregroundStyle(AppColors.primary)
                            .monospacedDigit()
                        Text(String(localized: "level"))
                            .appFont(.body)
                            .foregroundStyle(TextColors.secondary)
                    }
                    Text(latest.date.formatted(date: .abbreviated, time: .omitted))
                        .appFont(.small)
                        .foregroundStyle(TextColors.tertiary)
                } else {
                    Text(String(localized: "No data"))
                        .appFont(.h2)
                        .foregroundStyle(TextColors.tertiary)
                }
            }
        }
    }

    // MARK: - Period Selector

    private var periodSelector: some View {
        HStack(spacing: 0) {
            ForEach(TimePeriod.allCases, id: \.self) { period in
                Button {
                    withAnimation(AppAnimation.standard) { selectedPeriod = period }
                } label: {
                    Text(period.label)
                        .appFont(selectedPeriod == period ? .smallMedium : .small)
                        .foregroundStyle(selectedPeriod == period ? .white : TextColors.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.xxs)
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadius.sm, style: .continuous)
                                .fill(selectedPeriod == period ? AppColors.primary : Color.clear)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(periodAccessibilityLabel(for: period))
                .accessibilityAddTraits(selectedPeriod == period ? [.isSelected] : [])
            }
        }
        .padding(Spacing.xxxs)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.sm + 2, style: .continuous)
                .fill(AppColors.gray100)
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Display period selection")
    }

    private func periodAccessibilityLabel(for period: TimePeriod) -> String {
        switch period {
        case .day: return String(localized: "One day")
        case .week: return String(localized: "Week")
        case .month: return String(localized: "Month")
        case .sixMonths: return String(localized: "Six months")
        case .year: return String(localized: "Year")
        }
    }

    // MARK: - Legend

    private var legendView: some View {
        HStack(spacing: Spacing.sm) {
            legendItem(color: AppColors.primary, label: String(localized: "Before session"))
            legendItem(color: AppColors.accent, label: String(localized: "After session"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: Spacing.xxxs) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .appFont(.small)
                .foregroundStyle(TextColors.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label) indicator")
    }

    // MARK: - Chart Marks

    @ChartContentBuilder
    private func averageRuleMarks() -> some ChartContent {
        if let stats = statistics, !filteredDataPoints.isEmpty {
            RuleMark(y: .value(String(localized: "Avg Before"), stats.averageAnxietyBefore))
                .foregroundStyle(AppColors.primary.opacity(0.25))
                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 5]))
                .accessibilityHidden(true)
            if stats.averageAnxietyAfter != stats.averageAnxietyBefore {
                RuleMark(y: .value(String(localized: "Avg After"), stats.averageAnxietyAfter))
                    .foregroundStyle(AppColors.accent.opacity(0.25))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 5]))
                    .accessibilityHidden(true)
            }
        }
    }

    @ChartContentBuilder
    private func beforeLineMarks() -> some ChartContent {
        ForEach(filteredDataPoints) { point in
            LineMark(
                x: .value(String(localized: "Date"), point.date),
                y: .value(String(localized: "Before session"), point.anxietyBefore),
                series: .value(String(localized: "Streak"), String(localized: "Before"))
            )
            .foregroundStyle(AppColors.primary)
            .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
            .interpolationMethod(.catmullRom)

            PointMark(
                x: .value(String(localized: "Date"), point.date),
                y: .value(String(localized: "Before session"), point.anxietyBefore)
            )
            .foregroundStyle(AppColors.primary)
            .symbolSize(60)
        }
    }

    @ChartContentBuilder
    private func afterLineMarks() -> some ChartContent {
        ForEach(filteredDataPoints.filter { $0.anxietyAfter != nil }) { point in
            if let after = point.anxietyAfter {
                LineMark(
                    x: .value(String(localized: "Date"), point.date),
                    y: .value(String(localized: "After session"), after),
                    series: .value(String(localized: "Streak"), String(localized: "After"))
                )
                .foregroundStyle(AppColors.accent)
                .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                .interpolationMethod(.catmullRom)

                PointMark(
                    x: .value(String(localized: "Date"), point.date),
                    y: .value(String(localized: "After session"), after)
                )
                .foregroundStyle(AppColors.accent)
                .symbolSize(60)
            }
        }
    }

    // MARK: - Chart

    private var chartView: some View {
        Chart {
            averageRuleMarks()
            beforeLineMarks()
            afterLineMarks()
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(AppColors.gray200)
                AxisValueLabel()
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(TextColors.tertiary)
            }
        }
        .chartYAxis {
            AxisMarks(position: .trailing, values: .automatic) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(AppColors.gray200)
                AxisValueLabel()
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(TextColors.tertiary)
            }
        }
        .chartYScale(domain: 0...10)
        .frame(height: 200)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Anxiety dynamics chart by date")
    }

    // MARK: - Stats Row

    private func statsRow(stats: ChartStatistics) -> some View {
        HStack(spacing: 0) {
            statItem(
                title: String(localized: "Avg Before"),
                value: String(format: "%.1f", stats.averageAnxietyBefore),
                color: AppColors.primary
            )

            Divider().frame(height: 32)

            statItem(
                title: String(localized: "Avg After"),
                value: String(format: "%.1f", stats.averageAnxietyAfter),
                color: AppColors.accent
            )

            Divider().frame(height: 32)

            trendItem(stats: stats)
        }
        .padding(.top, Spacing.xxs)
    }

    private func statItem(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .appFont(.caption)
                .foregroundStyle(TextColors.secondary)
            Text(value)
                .appFont(.bodyMedium)
                .foregroundStyle(color)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }

    private func trendItem(stats: ChartStatistics) -> some View {
        let trendColor: Color = {
            switch stats.trendDirection {
            case .improving: return AppColors.positive
            case .stable: return AppColors.State.warning
            case .worsening: return AppColors.primary
            }
        }()

        return VStack(spacing: 2) {
            HStack(spacing: Spacing.xxxs) {
                Image(systemName: stats.trendDirection.icon)
                    .font(.system(size: 11, weight: .semibold))
                Text(stats.trendDirection.description)
                    .appFont(.smallMedium)
            }
            .foregroundStyle(trendColor)

            Text(String(format: "%.1f", abs(stats.averageChange)))
                .appFont(.bodyMedium)
                .foregroundStyle(TextColors.primary)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(format: NSLocalizedString("Trend: %1$@, change %2$@", comment: ""), stats.trendDirection.description, String(format: "%.1f", abs(stats.averageChange))))
    }
}

#Preview {
    ScrollView {
        ExposureProgressChart(
            dataPoints: [
                ChartDataPoint(date: Date().addingTimeInterval(-604800 * 4), anxietyBefore: 7, anxietyAfter: 5),
                ChartDataPoint(date: Date().addingTimeInterval(-604800 * 3), anxietyBefore: 6, anxietyAfter: 4),
                ChartDataPoint(date: Date().addingTimeInterval(-604800 * 2), anxietyBefore: 5, anxietyAfter: 3),
                ChartDataPoint(date: Date().addingTimeInterval(-604800), anxietyBefore: 4, anxietyAfter: 3),
                ChartDataPoint(date: Date(), anxietyBefore: 4, anxietyAfter: 2)
            ]
        )
        .padding()
    }
}
