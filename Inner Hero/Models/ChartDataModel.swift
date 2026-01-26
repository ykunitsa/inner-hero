import Foundation

// MARK: - Chart Data Point

struct ChartDataPoint: Identifiable {
    let id: UUID
    let date: Date
    let anxietyBefore: Int
    let anxietyAfter: Int?
    
    init(id: UUID = UUID(), date: Date, anxietyBefore: Int, anxietyAfter: Int?) {
        self.id = id
        self.date = date
        self.anxietyBefore = anxietyBefore
        self.anxietyAfter = anxietyAfter
    }
}

// MARK: - Time Period

enum TimePeriod: CaseIterable {
    case day
    case week
    case month
    case sixMonths
    case year
    
    var label: String {
        switch self {
        case .day: return String(localized: "ДН")
        case .week: return String(localized: "НЕД")
        case .month: return String(localized: "МЕС")
        case .sixMonths: return String(localized: "6 МЕС")
        case .year: return String(localized: "ГОД")
        }
    }
    
    var daysCount: Int {
        switch self {
        case .day: return 1
        case .week: return 7
        case .month: return 30
        case .sixMonths: return 180
        case .year: return 365
        }
    }
    
    var dateFormat: String {
        switch self {
        case .day: return "HH:mm"
        case .week: return "dd MMM"
        case .month: return "dd MMM"
        case .sixMonths: return "MMM"
        case .year: return "MMM"
        }
    }
}

// MARK: - Chart Statistics

struct ChartStatistics {
    let averageAnxietyBefore: Double
    let averageAnxietyAfter: Double
    let averageChange: Double
    let trendDirection: TrendDirection
    
    enum TrendDirection {
        case improving  // anxiety decreasing
        case stable
        case worsening  // anxiety increasing
        
        var icon: String {
            switch self {
            case .improving: return "arrow.down.circle.fill"
            case .stable: return "minus.circle.fill"
            case .worsening: return "arrow.up.circle.fill"
            }
        }
        
        var description: String {
            switch self {
            case .improving: return String(localized: "Улучшение")
            case .stable: return String(localized: "Стабильно")
            case .worsening: return String(localized: "Ухудшение")
            }
        }
    }
    
    static func calculate(from dataPoints: [ChartDataPoint]) -> ChartStatistics? {
        guard !dataPoints.isEmpty else { return nil }
        
        let beforeValues = dataPoints.map { Double($0.anxietyBefore) }
        let afterValues = dataPoints.compactMap { $0.anxietyAfter }.map { Double($0) }
        
        let avgBefore = beforeValues.reduce(0, +) / Double(beforeValues.count)
        let avgAfter = afterValues.isEmpty ? avgBefore : afterValues.reduce(0, +) / Double(afterValues.count)
        let avgChange = avgAfter - avgBefore
        
        let trend: TrendDirection
        if avgChange < -0.5 {
            trend = .improving
        } else if avgChange > 0.5 {
            trend = .worsening
        } else {
            trend = .stable
        }
        
        return ChartStatistics(
            averageAnxietyBefore: avgBefore,
            averageAnxietyAfter: avgAfter,
            averageChange: avgChange,
            trendDirection: trend
        )
    }
}





