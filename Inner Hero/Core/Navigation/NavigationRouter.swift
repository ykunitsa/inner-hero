import SwiftUI

// MARK: - Tab

enum AppTab: String, CaseIterable {
    case today
    case exercises
    /// Spec §2 lists four tabs; the schedule is a ratified fifth
    /// (`docs/plans/11.6d-schedule.md`, decision 3) and §2 is amended with it.
    case schedule
    case history
    case knowledge
}

// MARK: - Navigation Router

@Observable
@MainActor
final class NavigationRouter {
    private var paths: [AppTab: NavigationPath] = [:]

    func path(for tab: AppTab) -> Binding<NavigationPath> {
        Binding(
            get: { self.paths[tab] ?? NavigationPath() },
            set: { self.paths[tab] = $0 }
        )
    }

    func navigate(to route: AppRoute, in tab: AppTab) {
        paths[tab, default: NavigationPath()].append(route)
    }

    /// Appends any hashable value to the navigation path for the given tab.
    func append<T: Hashable>(value: T, to tab: AppTab) {
        paths[tab, default: NavigationPath()].append(value)
    }

    func navigateBack(in tab: AppTab) {
        guard var path = paths[tab], !path.isEmpty else { return }
        path.removeLast()
        paths[tab] = path
    }

    func popToRoot(in tab: AppTab) {
        paths[tab] = NavigationPath()
    }
}

// MARK: - Environment

private struct NavigationRouterKey: EnvironmentKey {
    static let defaultValue: NavigationRouter? = nil
}

private struct CurrentAppTabKey: EnvironmentKey {
    static let defaultValue: AppTab = .today
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
