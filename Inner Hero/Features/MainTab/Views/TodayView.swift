import SwiftUI

/// The "Today" tab. During the 2.0 rebuild this is a minimal shell:
/// the quick exposure-log card lands here first, then the day schedule.
struct TodayView: View {
    @Binding var path: NavigationPath

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:  return String(localized: "Good morning")
        case 12..<17: return String(localized: "Good afternoon")
        case 17..<22: return String(localized: "Good evening")
        default:      return String(localized: "Good night")
        }
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    placeholderCard
                }
                .padding(.horizontal, Spacing.sm)
                .padding(.top, Spacing.xxs)
                .padding(.bottom, Spacing.xxl)
            }
            .homeBackground()
            .navigationTitle(greeting)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    // Plain system button: the iOS 26 toolbar supplies its own
                    // round glass chrome — a custom background inside it
                    // renders as a stretched pill.
                    Button {
                        path.append(AppRoute.settings)
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel(String(localized: "Settings"))
                }
            }
            .navigationDestination(for: AppRoute.self) { route in
                AppRouteView(route: route)
            }
        }
    }

    private var placeholderCard: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text(String(localized: "Rebuild in progress"))
                .appFont(.h3)
                .foregroundStyle(TextColors.primary)
            Text(String(localized: "The exposure log lands here first."))
                .appFont(.body)
                .foregroundStyle(TextColors.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}

#Preview {
    TodayView(path: .constant(NavigationPath()))
        .environment(ArticlesStore())
}
