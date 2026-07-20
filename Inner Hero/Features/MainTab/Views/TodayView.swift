import SwiftUI

/// The "Today" tab. During the 2.0 rebuild this is a minimal shell:
/// the quick exposure-log card lands here first, then the day schedule.
struct TodayView: View {
    @Binding var path: NavigationPath

    @Environment(\.scenePhase) private var scenePhase

    @State private var viewModel = TodayViewModel()
    @State private var showExposureForm = false

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    exposureCard
                    scheduleSection
                }
                .padding(.horizontal, Spacing.sm)
                .padding(.top, Spacing.xxs)
                .padding(.bottom, Spacing.xxl)
            }
            .homeBackground()
            .navigationTitle(viewModel.greeting)
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
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { viewModel.refresh() }
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

    /// Spec §2.1: when nothing is planned, a quiet line of text — not a card,
    /// not an invitation to go configure something.
    @ViewBuilder
    private var scheduleSection: some View {
        if !viewModel.hasPlannedExposure {
            Text(viewModel.emptyScheduleText)
                .appFont(.body)
                .foregroundStyle(TextColors.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, Spacing.xs)
                .padding(.top, Spacing.xxs)
        }
    }
}

#Preview {
    TodayView(path: .constant(NavigationPath()))
        .environment(ArticlesStore())
}
