import SwiftUI
import SwiftData

// MARK: - Tab

enum AppTab: String, CaseIterable {
    case home
    case schedule
    case knowledge
    case exercises
    case settings
}

// MARK: - Navigation Router

@Observable
@MainActor
final class NavigationRouter {
    var pathHome = NavigationPath()
    var pathSchedule = NavigationPath()
    var pathExercises = NavigationPath()
    var pathKnowledge = NavigationPath()
    var pathSettings = NavigationPath()

    func path(for tab: AppTab) -> Binding<NavigationPath> {
        switch tab {
        case .home: return Binding(get: { self.pathHome }, set: { self.pathHome = $0 })
        case .schedule: return Binding(get: { self.pathSchedule }, set: { self.pathSchedule = $0 })
        case .exercises: return Binding(get: { self.pathExercises }, set: { self.pathExercises = $0 })
        case .knowledge: return Binding(get: { self.pathKnowledge }, set: { self.pathKnowledge = $0 })
        case .settings: return Binding(get: { self.pathSettings }, set: { self.pathSettings = $0 })
        }
    }

    func navigate(to route: AppRoute, in tab: AppTab) {
        switch tab {
        case .home: pathHome.append(route)
        case .schedule: pathSchedule.append(route)
        case .exercises: pathExercises.append(route)
        case .knowledge: pathKnowledge.append(route)
        case .settings: pathSettings.append(route)
        }
    }

    func navigateBack(in tab: AppTab) {
        switch tab {
        case .home: if !pathHome.isEmpty { pathHome.removeLast() }
        case .schedule: if !pathSchedule.isEmpty { pathSchedule.removeLast() }
        case .exercises: if !pathExercises.isEmpty { pathExercises.removeLast() }
        case .knowledge: if !pathKnowledge.isEmpty { pathKnowledge.removeLast() }
        case .settings: if !pathSettings.isEmpty { pathSettings.removeLast() }
        }
    }

    func popToRoot(in tab: AppTab) {
        switch tab {
        case .home: pathHome = NavigationPath()
        case .schedule: pathSchedule = NavigationPath()
        case .exercises: pathExercises = NavigationPath()
        case .knowledge: pathKnowledge = NavigationPath()
        case .settings: pathSettings = NavigationPath()
        }
    }
}

// MARK: - Environment

private struct NavigationRouterKey: EnvironmentKey {
    static let defaultValue: NavigationRouter? = nil
}

extension EnvironmentValues {
    var navigationRouter: NavigationRouter? {
        get { self[NavigationRouterKey.self] }
        set { self[NavigationRouterKey.self] = newValue }
    }

    var currentAppTab: AppTab {
        get { self[CurrentAppTabKey.self] }
        set { self[CurrentAppTabKey.self] = newValue }
    }
}

private struct CurrentAppTabKey: EnvironmentKey {
    static let defaultValue: AppTab = .home
}
