import SwiftUI
import WidgetKit

// MARK: - Log an exposure

/// Spec §3's widget: the button that is always the same.
///
/// It shows no state, and that is deliberate twice over. A ratio like "16 июля ·
/// 6 из 7 не ушёл" does not help anyone decide to press this — the decision is made
/// by something that happened in the world, not by readiness. And that line is the
/// contents of the log, which App Lock exists to hide, so showing it would mean
/// inventing a second state for a widget whose whole value is being one state.
///
/// Consequently this is the only widget that reads nothing at all. It works with the
/// group container missing, with the app never opened, and under the lock.
struct LogExposureWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "InnerHeroLogExposureWidget", provider: ConstantProvider()) { _ in
            WidgetTile(
                icon: "pencil",
                title: String(localized: "Log an exposure"),
                subtitle: String(localized: "If it happened")
            )
            .widgetURL(DeepLink.logExposure.url)
            .containerBackground(AppColors.cardBackground, for: .widget)
        }
        .configurationDisplayName(String(localized: "Log an exposure"))
        .description(String(localized: "Opens the situational form."))
        .supportedFamilies([.systemSmall])
    }
}

struct ConstantEntry: TimelineEntry {
    let date: Date
}

struct ConstantProvider: TimelineProvider {
    func placeholder(in context: Context) -> ConstantEntry { ConstantEntry(date: Date()) }

    func getSnapshot(in context: Context, completion: @escaping (ConstantEntry) -> Void) {
        completion(ConstantEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ConstantEntry>) -> Void) {
        // Nothing here ever changes, so nothing is ever scheduled.
        completion(Timeline(entries: [ConstantEntry(date: Date())], policy: .never))
    }
}

// MARK: - Breathing

struct BreathingWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: "InnerHeroBreathingWidget",
            provider: ExerciseTileProvider(exercise: .breathing)
        ) { entry in
            exerciseTile(entry, tint: AppColors.positive)
        }
        .configurationDisplayName(ScheduledExercise.breathing.title)
        .description(String(localized: "Opens a breathing session."))
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - Relaxation

struct RelaxationWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: "InnerHeroRelaxationWidget",
            provider: ExerciseTileProvider(exercise: .relaxation)
        ) { entry in
            exerciseTile(entry, tint: AppColors.primary)
        }
        .configurationDisplayName(ScheduledExercise.relaxation.title)
        .description(String(localized: "Opens a PMR session."))
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - Shared

@ViewBuilder
private func exerciseTile(_ entry: ExerciseEntry, tint: Color) -> some View {
    WidgetTile(
        icon: entry.exercise.icon,
        title: entry.exercise.title,
        subtitle: entry.subtitle,
        tint: tint
    )
    .widgetURL(DeepLink.exercise(entry.exercise).url)
    .containerBackground(AppColors.cardBackground, for: .widget)
}

struct ExerciseEntry: TimelineEntry {
    let date: Date
    let exercise: ScheduledExercise
    let subtitle: String?
}

/// The ladder position of one exercise, or its corrective phrase while
/// `sessions == 0` — the §1.7 rule, applied to the home screen by the same code
/// that applies it to the launcher tile.
struct ExerciseTileProvider: TimelineProvider {
    let exercise: ScheduledExercise

    func placeholder(in context: Context) -> ExerciseEntry {
        ExerciseEntry(date: Date(), exercise: exercise, subtitle: exercise.correctivePhrase)
    }

    func getSnapshot(in context: Context, completion: @escaping (ExerciseEntry) -> Void) {
        completion(entry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ExerciseEntry>) -> Void) {
        // A ladder position changes when a session is logged, and the app reloads
        // the timelines when it writes that. There is no moment in time this widget
        // has to wake up for — which is exactly why the positions are stored without
        // a relative day.
        completion(Timeline(entries: [entry()], policy: .never))
    }

    private func entry() -> ExerciseEntry {
        let snapshot = WidgetSnapshotStore().read() ?? .empty
        return ExerciseEntry(
            date: Date(),
            exercise: exercise,
            // Under App Lock the snapshot carries no positions at all, and the tile
            // shows the exercise's name alone.
            subtitle: snapshot.isRedacted
                ? nil
                : (snapshot.subtitle(for: exercise) ?? exercise.correctivePhrase)
        )
    }
}
