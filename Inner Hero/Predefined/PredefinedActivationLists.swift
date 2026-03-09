import Foundation

enum PredefinedActivationListKey: String, CaseIterable {
    case morningRoutine = "morning_routine"
    case selfCare = "self_care"
    case socialContacts = "social_contacts"
    case productiveTasks = "productive_tasks"
    case physicalActivity = "physical_activity"
}

struct PredefinedActivationListData {
    let key: PredefinedActivationListKey
    let title: String
    let activities: [String]
}

enum PredefinedActivationLists {
    static var all: [PredefinedActivationListData] {
        PredefinedActivationListKey.allCases.map(data(for:))
    }

    static func data(for key: PredefinedActivationListKey) -> PredefinedActivationListData {
        switch key {
        case .morningRoutine:
            return makeData(for: .morningRoutine, activitiesCount: 5)
        case .selfCare:
            return makeData(for: .selfCare, activitiesCount: 6)
        case .socialContacts:
            return makeData(for: .socialContacts, activitiesCount: 6)
        case .productiveTasks:
            return makeData(for: .productiveTasks, activitiesCount: 6)
        case .physicalActivity:
            return makeData(for: .physicalActivity, activitiesCount: 7)
        }
    }

    private static func makeData(
        for key: PredefinedActivationListKey,
        activitiesCount: Int
    ) -> PredefinedActivationListData {
        PredefinedActivationListData(
            key: key,
            title: localizedString(for: key, field: "title"),
            activities: (1...activitiesCount).map { localizedString(for: key, field: "activity\($0)") }
        )
    }

    private static func localizedString(for key: PredefinedActivationListKey, field: String) -> String {
        let key = "predefined.activation.\(key.rawValue).\(field)"
        return Bundle.main.localizedString(forKey: key, value: nil, table: nil)
    }
}
