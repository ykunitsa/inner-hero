import SwiftUI

/// The "Today" tab. During the 2.0 rebuild this is a minimal shell:
/// the quick exposure-log card lands here first, then the day schedule.
struct TodayView: View {
    @Binding var path: NavigationPath

    @State private var showExposureForm = false

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
                    exposureCard
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
            .sheet(isPresented: $showExposureForm) {
                SituationalExposureFormView()
            }
        }
    }

    /// The single accent card of Today — always available (spec §2.1).
    private var exposureCard: some View {
        Button {
            showExposureForm = true
        } label: {
            HeroFeatureCard(
                subtitle: String(localized: "While it's fresh"),
                title: String(localized: "Log an exposure"),
                icon: "pencil"
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    TodayView(path: .constant(NavigationPath()))
        .environment(ArticlesStore())
}
