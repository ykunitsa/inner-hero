import Foundation

enum PredefinedExposureKey: String, CaseIterable {
    case publicSpeaking = "public_speaking"
    case elevator
    case callingStranger = "calling_stranger"
    case cafeIntroduction = "cafe_introduction"
    case crowdedPlace = "crowded_place"
    case askingSalesperson = "asking_salesperson"
    case onlineMeeting = "online_meeting"
    case cinemaAlone = "cinema_alone"
}

struct PredefinedExposureData {
    let key: PredefinedExposureKey
    let title: String
    let description: String
    let steps: [String]
}

enum PredefinedExposures {
    static var all: [PredefinedExposureData] {
        PredefinedExposureKey.allCases.map(data(for:))
    }

    static func data(for key: PredefinedExposureKey) -> PredefinedExposureData {
        switch key {
        case .publicSpeaking:
            return makeData(for: .publicSpeaking, stepsCount: 5)
        case .elevator:
            return makeData(for: .elevator, stepsCount: 6)
        case .callingStranger:
            return makeData(for: .callingStranger, stepsCount: 7)
        case .cafeIntroduction:
            return makeData(for: .cafeIntroduction, stepsCount: 7)
        case .crowdedPlace:
            return makeData(for: .crowdedPlace, stepsCount: 6)
        case .askingSalesperson:
            return makeData(for: .askingSalesperson, stepsCount: 6)
        case .onlineMeeting:
            return makeData(for: .onlineMeeting, stepsCount: 7)
        case .cinemaAlone:
            return makeData(for: .cinemaAlone, stepsCount: 7)
        }
    }

    private static func makeData(for key: PredefinedExposureKey, stepsCount: Int) -> PredefinedExposureData {
        PredefinedExposureData(
            key: key,
            title: localizedString(for: key, field: "title"),
            description: localizedString(for: key, field: "description"),
            steps: (1...stepsCount).map { localizedString(for: key, field: "step\($0)") }
        )
    }

    private static func localizedString(for key: PredefinedExposureKey, field: String) -> String {
        let fullKey = "predefined.exposure.\(key.rawValue).\(field)"
        return Bundle.main.localizedString(forKey: fullKey, value: nil, table: nil)
    }
}
