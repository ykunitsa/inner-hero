import Foundation

extension Exposure {
    var localizedTitle: String {
        guard let predefinedKey,
              let key = PredefinedExposureKey(rawValue: predefinedKey) else {
            return title
        }
        return PredefinedExposures.data(for: key).title
    }

    var localizedDescription: String {
        guard let predefinedKey,
              let key = PredefinedExposureKey(rawValue: predefinedKey) else {
            return exposureDescription
        }
        return PredefinedExposures.data(for: key).description
    }

    var localizedStepTexts: [String] {
        guard let predefinedKey,
              let key = PredefinedExposureKey(rawValue: predefinedKey) else {
            return steps.sorted { $0.order < $1.order }.map(\.text)
        }
        return PredefinedExposures.data(for: key).steps
    }
}
