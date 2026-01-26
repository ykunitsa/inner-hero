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
    
    private var latestDataPoint: ChartDataPoint? {
        filteredDataPoints.last
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header with current value
            headerSection
            
            // Time period filters
            periodSelector
            
            // Legend
            legendView
            
            // Chart (always show)
            chartView
            
            // Statistics
            if let stats = statistics, !filteredDataPoints.isEmpty {
                statisticsSection(stats: stats)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(red: 0.98, green: 0.99, blue: 1.0))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [.blue.opacity(0.2), .cyan.opacity(0.15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .accessibilityElement(children: .contain)
                .accessibilityLabel("График прогресса тревожности")
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Динамика тревожности", systemImage: "chart.line.uptrend.xyaxis")
                .font(.headline)
                .foregroundStyle(TextColors.primary)
                .accessibilityAddTraits(.isHeader)
            
            if let latest = latestDataPoint {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    if let after = latest.anxietyAfter {
                        Text("\(after)")
                            .font(.system(size: 48, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .cyan],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .monospacedDigit()
                    } else {
                        Text("\(latest.anxietyBefore)")
                            .font(.system(size: 48, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .cyan],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .monospacedDigit()
                    }
                    
                    Text("уровень")
                        .font(.title3)
                        .foregroundStyle(TextColors.secondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(
                    String(
                        format: NSLocalizedString("Текущий уровень тревожности: %d", comment: ""),
                        latest.anxietyAfter ?? latest.anxietyBefore
                    )
                )
                
                Text(latest.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.subheadline)
                    .foregroundStyle(TextColors.tertiary)
                    .accessibilityLabel(
                        String(
                            format: NSLocalizedString("Дата: %@", comment: ""),
                            latest.date.formatted(date: .long, time: .omitted)
                        )
                    )
            } else {
                Text("Нет данных")
                    .font(.system(size: 48, weight: .medium))
                    .foregroundStyle(TextColors.tertiary)
            }
        }
    }
    
    private var periodSelector: some View {
        HStack(spacing: 0) {
            ForEach(TimePeriod.allCases, id: \.self) { period in
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedPeriod = period
                    }
                } label: {
                    Text(period.label)
                        .font(.subheadline.weight(selectedPeriod == period ? .semibold : .regular))
                        .foregroundStyle(selectedPeriod == period ? .white : TextColors.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(
                                    selectedPeriod == period ?
                                    LinearGradient(
                                        colors: [.blue, .cyan],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ) : LinearGradient(
                                        colors: [.clear],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(periodAccessibilityLabel(for: period))
                .accessibilityAddTraits(selectedPeriod == period ? [.isSelected] : [])
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(red: 0.95, green: 0.96, blue: 0.98))
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Выбор периода отображения")
    }
    
    private func periodAccessibilityLabel(for period: TimePeriod) -> String {
        switch period {
        case .day: return String(localized: "Один день")
        case .week: return String(localized: "Неделя")
        case .month: return String(localized: "Месяц")
        case .sixMonths: return String(localized: "Шесть месяцев")
        case .year: return String(localized: "Год")
        }
    }
    
    private var legendView: some View {
        HStack(spacing: 16) {
            HStack(spacing: 6) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .blue.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 10, height: 10)
                Text("До сеанса")
                    .font(.caption)
                    .foregroundStyle(TextColors.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Синяя линия: тревожность до сеанса")
            
            HStack(spacing: 6) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.cyan, .cyan.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 10, height: 10)
                Text("После сеанса")
                    .font(.caption)
                    .foregroundStyle(TextColors.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Голубая линия: тревожность после сеанса")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var chartView: some View {
        Chart {
            // Reference lines (average)
            if let stats = statistics, !filteredDataPoints.isEmpty {
            RuleMark(y: .value(String(localized: "Среднее До"), stats.averageAnxietyBefore))
                    .foregroundStyle(.blue.opacity(0.25))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 5]))
                    .accessibilityHidden(true)
                
                if stats.averageAnxietyAfter != stats.averageAnxietyBefore {
                RuleMark(y: .value(String(localized: "Среднее После"), stats.averageAnxietyAfter))
                        .foregroundStyle(.cyan.opacity(0.25))
                        .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 5]))
                        .accessibilityHidden(true)
                }
            }
            
            // Anxiety Before line - continuous line through all points
            ForEach(filteredDataPoints) { point in
                LineMark(
                    x: .value(String(localized: "Дата"), point.date),
                    y: .value(String(localized: "До сеанса"), point.anxietyBefore),
                    series: .value(String(localized: "Серия"), String(localized: "До"))
                )
                .foregroundStyle(.blue)
                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                .interpolationMethod(.catmullRom)
                
                PointMark(
                    x: .value(String(localized: "Дата"), point.date),
                    y: .value(String(localized: "До сеанса"), point.anxietyBefore)
                )
                .foregroundStyle(.blue)
                .symbolSize(80)
            }
            
            // Anxiety After line - continuous line through all points with data
            ForEach(filteredDataPoints.filter { $0.anxietyAfter != nil }) { point in
                if let after = point.anxietyAfter {
                    LineMark(
                        x: .value(String(localized: "Дата"), point.date),
                        y: .value(String(localized: "После сеанса"), after),
                        series: .value(String(localized: "Серия"), String(localized: "После"))
                    )
                    .foregroundStyle(.cyan)
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    .interpolationMethod(.catmullRom)
                    
                    PointMark(
                        x: .value(String(localized: "Дата"), point.date),
                        y: .value(String(localized: "После сеанса"), after)
                    )
                    .foregroundStyle(.cyan)
                    .symbolSize(80)
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(.gray.opacity(0.15))
                AxisValueLabel()
                    .font(.caption2)
                    .foregroundStyle(TextColors.tertiary)
            }
        }
        .chartYAxis {
            AxisMarks(position: .trailing, values: .automatic) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(.gray.opacity(0.15))
                AxisValueLabel()
                    .font(.caption2)
                    .foregroundStyle(TextColors.tertiary)
            }
        }
        .chartYScale(domain: 0...10)
        .frame(height: 220)
        .padding(.vertical, 8)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("График динамики тревожности по датам")
    }
    
    private func statisticsSection(stats: ChartStatistics) -> some View {
        HStack(spacing: 20) {
            StatItemView(
                title: "Среднее До",
                value: String(format: "%.1f", stats.averageAnxietyBefore),
                color: .blue
            )
            .accessibilityElement(children: .combine)
            .accessibilityLabel(
                String(
                    format: NSLocalizedString("Средняя тревожность до сеанса: %@", comment: ""),
                    String(format: "%.1f", stats.averageAnxietyBefore)
                )
            )
            
            Divider()
                .frame(height: 30)
                .accessibilityHidden(true)
            
            StatItemView(
                title: "Среднее После",
                value: String(format: "%.1f", stats.averageAnxietyAfter),
                color: .cyan
            )
            .accessibilityElement(children: .combine)
            .accessibilityLabel(
                String(
                    format: NSLocalizedString("Средняя тревожность после сеанса: %@", comment: ""),
                    String(format: "%.1f", stats.averageAnxietyAfter)
                )
            )
            
            Divider()
                .frame(height: 30)
                .accessibilityHidden(true)
            
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: stats.trendDirection.icon)
                        .font(.caption)
                    Text(stats.trendDirection.description)
                        .font(.caption.weight(.medium))
                }
                .foregroundStyle(trendColor(for: stats.trendDirection))
                
                Text(String(format: "%.1f", abs(stats.averageChange)))
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(TextColors.primary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(
                String(
                    format: NSLocalizedString("Тренд: %@, изменение %@", comment: ""),
                    stats.trendDirection.description,
                    String(format: "%.1f", abs(stats.averageChange))
                )
            )
        }
        .padding(.top, 8)
    }
    
    private func trendColor(for direction: ChartStatistics.TrendDirection) -> Color {
        switch direction {
        case .improving: return .green
        case .stable: return .orange
        case .worsening: return .red
        }
    }
}

// MARK: - Stat Item View

private struct StatItemView: View {
    let title: LocalizedStringKey
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(TextColors.secondary)
            Text(value)
                .font(.headline.monospacedDigit())
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

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

