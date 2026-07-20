import SwiftUI

/// The exercise launcher: four fixed rows (spec 2.2). Subtitles will reflect
/// state (`sessions == 0` → one corrective phrase, otherwise last-session
/// state) when the shell lands in §11.6. During the rebuild the rows light
/// up one by one as each exercise flow is rebuilt; the rest stay inactive
/// placeholders.
struct ExercisesView: View {
    @Binding var path: NavigationPath

    @State private var showPlannedExposure = false

    private struct LauncherRow: Identifiable {
        var id: String { title }
        let title: String
        let subtitle: String
        let icon: String
        var action: (() -> Void)? = nil
    }

    private var rows: [LauncherRow] {
        [
            .init(
                title: String(localized: "Exposures"),
                // Corrective phrase (spec 2.2): the exercise's success
                // criterion, not marketing.
                subtitle: String(localized: "Success is staying, not calming down"),
                icon: "leaf",
                // One tap from the row to the "before" screen — no menu
                // between icon and action (principle 1.2).
                action: { showPlannedExposure = true }
            ),
            .init(
                title: String(localized: "Breathing"),
                subtitle: String(localized: "Coming back soon"),
                icon: "wind"
            ),
            .init(
                title: String(localized: "Relaxation"),
                subtitle: String(localized: "Coming back soon"),
                icon: "figure.mind.and.body"
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
                VStack(spacing: Spacing.xs) {
                    ForEach(rows) { row in
                        launcherRow(row)
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
        }
    }

    @ViewBuilder
    private func launcherRow(_ row: LauncherRow) -> some View {
        if let action = row.action {
            Button(action: action) {
                launcherRowContent(row)
            }
            .buttonStyle(.plain)
        } else {
            launcherRowContent(row)
                .opacity(0.55)
        }
    }

    private func launcherRowContent(_ row: LauncherRow) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: row.icon)
                .font(.system(size: IconSize.glyph + 4, weight: .medium))
                .foregroundStyle(AppColors.primary)
                .frame(width: IconSize.hero, height: IconSize.hero)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                        .fill(AppColors.primary.opacity(Opacity.subtleBackground))
                )

            VStack(alignment: .leading, spacing: Spacing.xxxs) {
                Text(row.title)
                    .appFont(.h3)
                    .foregroundStyle(TextColors.primary)
                Text(row.subtitle)
                    .appFont(.small)
                    .foregroundStyle(TextColors.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.sm)
        .cardStyle(cornerRadius: CornerRadius.lg, padding: 0)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(row.title). \(row.subtitle)")
    }
}

#Preview {
    ExercisesView(path: .constant(NavigationPath()))
        .environment(ArticlesStore())
        .environment(NotificationManager())
}
