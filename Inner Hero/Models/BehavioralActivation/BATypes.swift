import Foundation

// MARK: - LifeValue

enum LifeValue: String, Codable, CaseIterable, Identifiable {
    case connection
    case body
    case creativity
    case nature
    case growth
    case rest

    var id: String { rawValue }
}

extension LifeValue {
    var localizedName: String {
        switch self {
        case .connection: String(localized: "life_value.connection")
        case .body:       String(localized: "life_value.body")
        case .creativity: String(localized: "life_value.creativity")
        case .nature:     String(localized: "life_value.nature")
        case .growth:     String(localized: "life_value.growth")
        case .rest:       String(localized: "life_value.rest")
        }
    }

    var systemIconName: String {
        switch self {
        case .connection: "figure.2.arms.open"
        case .body:       "figure.run"
        case .creativity: "paintbrush"
        case .nature:     "leaf"
        case .growth:     "book"
        case .rest:       "moon"
        }
    }
}

// MARK: - BAStatus

// Storage contract: rawValues are persisted. NEVER rename rawValue strings.
enum BAStatus: String, Codable {
    case planned
    case active
    case completed
    case cancelled
}

// MARK: - ExpectedOutcome

enum ExpectedOutcome: String, Codable {
    case better
    case asExpected
    case worse
}

extension ExpectedOutcome {
    var localizedTitle: String {
        switch self {
        case .better:      String(localized: "expected_outcome.better")
        case .asExpected:  String(localized: "expected_outcome.as_expected")
        case .worse:       String(localized: "expected_outcome.worse")
        }
    }
}
