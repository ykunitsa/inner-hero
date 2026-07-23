import SwiftData
import SwiftUI

/// The exercise launcher (spec §2.2). Each tile's subtitle follows the
/// `sessions == 0` rule (§1.7): one corrective phrase until the exercise has
/// been done, the position on its ladder afterwards. The switch is driven by
/// the session count alone — there is no "has seen" flag anywhere.
///
/// Spec §2.2 says "four rows". This is a 2×2 grid instead, ratified in
/// `docs/plans/11.6-shell.md` §10: the corrective phrase is four to six words
/// of real content (Russian runs ~15% longer than the English source) and a
/// 44–60pt row cannot hold it without clipping the one thing the tile exists
/// to say.
struct ExercisesView: View {
    @Binding var path: NavigationPath

    // Unsorted: every subtitle needs the whole set anyway — the newest entry
    // for the date, a window of them for the exposure fraction — so sorting in
    // the query would only move the same work earlier.
    @Query private var exposures: [ExposureLogEntry]
    @Query private var breathingSessions: [BreathingSessionEntry]
    @Query private var pmrSessions: [PMRSessionEntry]
    @Query private var activationEntries: [BALogEntry]

    @State private var showPlannedExposure = false
    @State private var showBreathing = false
    @State private var showRelaxation = false
    @State private var showActivation = false

    /// Tiles are given a floor, not a fixed height: the corrective phrase is
    /// spec-required content and has to be allowed to grow — Russian runs
    /// ~15% longer than the English source, before Dynamic Type.
    @ScaledMetric(relativeTo: .body) private var tileMinHeight: CGFloat = 150

    private static let columns = [
        GridItem(.flexible(), spacing: Spacing.xs),
        GridItem(.flexible(), spacing: Spacing.xs),
    ]

    private struct LauncherTile: Identifiable {
        let exercise: ScheduledExercise
        /// The ladder position, or nil while `sessions == 0` (§1.7) — in which case
        /// the corrective phrase stands in.
        let status: String?
        var action: (() -> Void)? = nil

        init(exercise: ScheduledExercise, subtitle: String?, action: (() -> Void)? = nil) {
            self.exercise = exercise
            self.status = subtitle
            self.action = action
        }

        var id: String { exercise.rawValue }
        var title: String { exercise.title }
        var icon: String { exercise.icon }
        var subtitle: String { status ?? exercise.correctivePhrase }
    }

    private var tiles: [LauncherTile] {
        [
            // Title, glyph and the `sessions == 0` phrase all come from
            // `ScheduledExercise`: the widgets say the same things about the same
            // exercises, and one vocabulary cannot drift from itself (§11.7).
            .init(
                exercise: .exposure,
                subtitle: ExerciseStatus.exposure(exposures),
                // One tap from the tile to the "before" screen — no menu
                // between icon and action (principle 1.2).
                action: { showPlannedExposure = true }
            ),
            .init(
                exercise: .breathing,
                subtitle: ExerciseStatus.breathing(breathingSessions),
                action: { showBreathing = true }
            ),
            .init(
                exercise: .relaxation,
                subtitle: ExerciseStatus.pmr(pmrSessions),
                action: { showRelaxation = true }
            ),
            .init(
                exercise: .activation,
                subtitle: ExerciseStatus.activation(activationEntries),
                action: { showActivation = true }
            ),
        ]
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                LazyVGrid(columns: Self.columns, spacing: Spacing.xs) {
                    ForEach(tiles) { tile in
                        launcherTile(tile)
                    }
                }
                .padding(.horizontal, Spacing.sm)
                .padding(.top, Spacing.md)
                .padding(.bottom, Spacing.xxl)
            }
            .homeBackground()
            .navigationTitle(String(localized: "Exercises"))
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: AppRoute.self) { route in
                AppRouteView(route: route)
            }
            .fullScreenCover(isPresented: $showPlannedExposure) {
                PlannedExposureFlowView()
            }
            .fullScreenCover(isPresented: $showBreathing) {
                BreathingFlowView()
            }
            .fullScreenCover(isPresented: $showRelaxation) {
                PMRFlowView()
            }
            .fullScreenCover(isPresented: $showActivation) {
                BAFlowView()
            }
        }
    }

    @ViewBuilder
    private func launcherTile(_ tile: LauncherTile) -> some View {
        if let action = tile.action {
            Button(action: action) {
                tileContent(tile, isActive: true)
            }
            .buttonStyle(.plain)
        } else {
            // Inactive tiles are muted by *role colours*, not by a blanket
            // `.opacity`. Dimming the whole tile dragged the subtitle below
            // readable contrast — and "not built yet" is precisely the thing
            // the user needs to be able to read (codex §6).
            tileContent(tile, isActive: false)
                .accessibilityRemoveTraits(.isButton)
        }
    }

    private func tileContent(_ tile: LauncherTile, isActive: Bool) -> some View {
        let tint = isActive ? AppColors.primary : AppColors.gray400

        return VStack(alignment: .leading, spacing: Spacing.xs) {
            Image(systemName: tile.icon)
                // `.appFont`, not `.system(size:)` — a frozen point size
                // drops the glyph out of Dynamic Type.
                .appFont(.h3)
                .foregroundStyle(tint)
                .frame(width: IconSize.card, height: IconSize.card)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                        .fill(tint.opacity(Opacity.subtleBackground))
                )

            Spacer(minLength: Spacing.xxs)

            VStack(alignment: .leading, spacing: Spacing.xxxs) {
                Text(tile.title)
                    .appFont(.h3)
                    .foregroundStyle(isActive ? TextColors.primary : TextColors.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(tile.subtitle)
                    .appFont(.small)
                    .foregroundStyle(isActive ? TextColors.secondary : TextColors.tertiary)
                    // No lineLimit: the corrective phrase is the point of the
                    // tile (spec 2.2) and must never be clipped to fit.
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(
            maxWidth: .infinity,
            minHeight: tileMinHeight,
            maxHeight: .infinity,
            alignment: .topLeading
        )
        .cardStyle(cornerRadius: CornerRadius.lg, padding: Spacing.sm)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(tile.title). \(tile.subtitle)")
    }
}

#Preview {
    ExercisesView(path: .constant(NavigationPath()))
        .environment(ArticlesStore())
        .environment(NotificationManager())
        .modelContainer(
            for: [
                ExposureLogEntry.self, BreathingSessionEntry.self,
                PMRSessionEntry.self, BAActivity.self, BALogEntry.self,
            ],
            inMemory: true
        )
}
