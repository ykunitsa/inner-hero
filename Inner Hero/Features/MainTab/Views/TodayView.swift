import SwiftData
import SwiftUI

/// The "Today" tab (spec §2.1): the accent card that is always available, the open
/// BA tail, and what the person put on today's schedule.
///
/// Today answers *what is on today* and leads into the exercise; the Schedule tab
/// answers *what is set up at all* and owns every edit. Neither shows the other's
/// answer, which is why there is no "configure" affordance anywhere on this screen.
struct TodayView: View {
    @Binding var path: NavigationPath

    @Environment(\.scenePhase) private var scenePhase

    /// The open BA activity, if any (spec §2.1: first line of the day).
    @Query(sort: \BALogEntry.createdAt, order: .reverse) private var entries: [BALogEntry]
    @Query private var schedule: [ScheduleItem]

    // Unsorted and unfiltered, like `ExercisesView`: the "done today" marks need a
    // membership test per exercise, and a predicate carrying today's date would go
    // stale the moment the app is left open past midnight.
    @Query private var exposures: [ExposureLogEntry]
    @Query private var breathingSessions: [BreathingSessionEntry]
    @Query private var pmrSessions: [PMRSessionEntry]

    @State private var viewModel = TodayViewModel()
    @State private var showExposureForm = false
    /// One cover for every exercise reachable from this screen — five booleans
    /// would be five ways to open two screens at once.
    @State private var activeFlow: ScheduledExercise?

    private var openEntry: BALogEntry? {
        entries.first { $0.isOpen }
    }

    private var rows: [TodayScheduleRow] {
        viewModel.rows(
            schedule: schedule,
            done: TodayViewModel.doneExercises(
                exposures: exposures,
                breathing: breathingSessions,
                pmr: pmrSessions,
                activation: entries,
                on: viewModel.now
            )
        )
    }

    private var hasExposureToday: Bool {
        TodayViewModel.hasExposure(in: rows)
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    exposureCard
                    openActivityRow
                    scheduleSection
                    emptyExposureLine
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
            .fullScreenCover(item: $activeFlow) { exercise in
                // A switch at the call site, not a view on `ScheduledExercise`:
                // the enum stays an identifier (§1.10).
                switch exercise {
                case .exposure: PlannedExposureFlowView()
                case .breathing: BreathingFlowView()
                case .relaxation: PMRFlowView()
                case .activation: BAFlowView()
                }
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
    /// (codex §8). Deliberately above the "Today" header rather than under it:
    /// the tail carries no time and is often about yesterday, and "planned
    /// yesterday at 16:40" under a header saying "Today" reads as a bug.
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
                activeFlow = .activation
            }
        }
    }

    /// What is on today, in time order. No header when there is nothing — a label
    /// over an empty space is not information.
    @ViewBuilder
    private var scheduleSection: some View {
        let rows = rows
        if !rows.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                SectionHeader(title: String(localized: "Today"))
                    .padding(.top, Spacing.xxs)

                ForEach(rows) { row in
                    if let exercise = row.item.exercise {
                        ExerciseRow(
                            title: exercise.title,
                            meta: TodayViewModel.meta(for: row),
                            icon: exercise.icon
                        ) {
                            // Straight into the exercise, never into a description
                            // of it (§1.2).
                            activeFlow = exercise
                        }
                    }
                }
            }
        }
    }

    /// Spec §2.1: when no exposure is planned, a plain line of text — not a card,
    /// not an invitation to go configure something.
    @ViewBuilder
    private var emptyExposureLine: some View {
        if !hasExposureToday {
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
        .modelContainer(
            for: [
                ExposureLogEntry.self, BreathingSessionEntry.self,
                PMRSessionEntry.self, BAActivity.self, BALogEntry.self,
                ScheduleItem.self,
            ],
            inMemory: true
        )
}
