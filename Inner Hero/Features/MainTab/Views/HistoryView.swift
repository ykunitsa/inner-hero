import SwiftUI

/// The "History" tab. Final version (spec 2.3): ladders, exposure stats,
/// the session feed, and export. Placeholder until the new log models land.
struct HistoryView: View {
    @Binding var path: NavigationPath

    var body: some View {
        NavigationStack(path: $path) {
            ContentUnavailableView(
                String(localized: "No records yet"),
                systemImage: "clock.arrow.circlepath",
                description: Text(String(localized: "Sessions will appear here after your first exercise."))
            )
            .homeBackground()
            .navigationTitle(String(localized: "History"))
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: AppRoute.self) { route in
                AppRouteView(route: route)
            }
        }
    }
}

#Preview {
    HistoryView(path: .constant(NavigationPath()))
        .environment(ArticlesStore())
}
