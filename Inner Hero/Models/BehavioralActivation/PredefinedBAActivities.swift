import Foundation

/// Data transfer object used to seed predefined BA activities at first launch.
struct PredefinedBAActivityData {
    let key: String
    let title: String
    let lifeValueRaw: String
}

/// Predefined behavioral-activation activities shipped with the app.
/// Full content is implemented in INN-26.
enum PredefinedBAActivities {
    static var all: [PredefinedBAActivityData] { [] }
}
