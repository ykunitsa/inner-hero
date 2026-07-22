import SwiftData
import SwiftUI

/// The "Today" tab. During the 2.0 rebuild this is a minimal shell:
/// the quick exposure-log card lands here first, then the day schedule.
struct TodayView: View {
    @Binding var path: NavigationPath

    @Environment(\.scenePhase) private var scenePhase

    /// The open BA activity, if any (spec §2.1: first line of the day list).
    /// Queried here rather than routed through `TodayViewModel` because the
    /// schedule itself is still a §11.6 stub — this is the one real item the
    /// list can currently hold.
    @Query(sort: \BALogEntry.createdAt, order: .reverse) private var entries: [BALogEntry]

    @State private var viewModel = TodayViewModel()
    @State private var showExposureForm = false
    @State private var showActivation = false

    private var openEntry: BALogEntry? {
        entries.first { $0.isOpen }
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    exposureCard
                    openActivityRow
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
            .fullScreenCover(isPresented: $showActivation) {
                BAFlowView()
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

    /// The open BA activity (spec §2.1, §6): the tail that closes the loop.
    ///
    /// A row, never an accent card — Today already has exactly one accent and it
    /// belongs to the exposure card. Nothing here counts how long the activity
    /// has been waiting: an overdue number is a reproach, not information
    /// (codex §8). When there is no tail there is no row and no placeholder.
    @ViewBuilder
    private var openActivityRow: some View {
        if let openEntry {
            ExerciseRow(
                title: openEntry.activityTitle,
                meta: String(
                    format: String(localized: "%1$@ · %2$@"),
                    BAFlowViewModel.plannedText(createdAt: openEntry.createdAt),
                    String(localized: "Did it happen?")
                ),
                icon: "figure.walk"
            ) {
                showActivation = true
            }
        }
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
        .environment(NotificationManager())
        .modelContainer(for: [BAActivity.self, BALogEntry.self], inMemory: true)
}
