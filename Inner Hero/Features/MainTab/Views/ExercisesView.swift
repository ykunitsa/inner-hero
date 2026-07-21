import SwiftUI

/// The exercise launcher: four fixed rows (spec 2.2). Subtitles will reflect
/// state (`sessions == 0` → one corrective phrase, otherwise last-session
/// state) when the shell lands in §11.6. During the rebuild the rows light
/// up one by one as each exercise flow is rebuilt; the rest stay inactive
/// placeholders.
struct ExercisesView: View {
    @Binding var path: NavigationPath

    @State private var showPlannedExposure = false
    @State private var showBreathing = false
    @State private var showRelaxation = false

    /// Tiles are given a floor, not a fixed height: the corrective phrase is
    /// spec-required content and has to be allowed to grow — Russian runs
    /// ~15% longer than the English source, before Dynamic Type.
    @ScaledMetric(relativeTo: .body) private var tileMinHeight: CGFloat = 150

    private static let columns = [
        GridItem(.flexible(), spacing: Spacing.xs),
        GridItem(.flexible(), spacing: Spacing.xs),
    ]

    private struct LauncherTile: Identifiable {
        var id: String { title }
        let title: String
        let subtitle: String
        let icon: String
        var action: (() -> Void)? = nil
    }

    private var tiles: [LauncherTile] {
        [
            .init(
                title: String(localized: "Exposures"),
                // Corrective phrase (spec 2.2): the exercise's success
                // criterion, not marketing.
                subtitle: String(localized: "Success is staying, not calming down"),
                icon: "leaf",
                // One tap from the tile to the "before" screen — no menu
                // between icon and action (principle 1.2).
                action: { showPlannedExposure = true }
            ),
            .init(
                title: String(localized: "Breathing"),
                // Corrective phrase (spec 2.2): breathing is applied
                // relaxation — a skill trained on a schedule, not something
                // reached for when the anxiety is already peaking.
                subtitle: String(localized: "Training, not first aid"),
                icon: "wind",
                action: { showBreathing = true }
            ),
            .init(
                title: String(localized: "Relaxation"),
                // Corrective phrase (spec 2.2): in PMR the release phase is the
                // skill — tensing is only there to make the contrast findable.
                subtitle: String(localized: "Letting go is the part you train"),
                icon: "figure.mind.and.body",
                action: { showRelaxation = true }
            ),
            .init(
                title: String(localized: "Behavioral Activation"),
                subtitle: String(localized: "Coming back soon"),
                icon: "figure.walk"
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
}
