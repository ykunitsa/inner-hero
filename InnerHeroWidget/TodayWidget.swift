import SwiftUI
import WidgetKit

/// Spec §9: one thing, hard priority — open BA tail, then the schedule, then the
/// exposure entry. The priority itself lives in `WidgetState`, which is why it can
/// be unit-tested and why the two sizes cannot disagree about what is showing.
///
/// `systemMedium` exists for the text, not for more content. It never lists the day:
/// §9 says one thing, and a larger canvas does not change what the widget is for.
/// What it changes is that "Позвонить маме и договориться про выходные" fits.
struct TodayWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "InnerHeroTodayWidget", provider: TodayProvider()) { entry in
            WidgetTile(
                icon: entry.state.icon,
                title: entry.state.title,
                subtitle: entry.state.subtitle,
                tint: entry.state.tint,
                isWide: entry.isWide
            )
            .widgetURL(entry.state.deepLink.url)
            .containerBackground(AppColors.cardBackground, for: .widget)
        }
        .configurationDisplayName(String(localized: "Today"))
        .description(String(localized: "One thing that's waiting."))
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct TodayEntry: TimelineEntry {
    let date: Date
    let state: WidgetState
    var isWide = false
}

struct TodayProvider: TimelineProvider {
    func placeholder(in context: Context) -> TodayEntry {
        TodayEntry(date: Date(), state: .logExposure, isWide: context.family == .systemMedium)
    }

    func getSnapshot(in context: Context, completion: @escaping (TodayEntry) -> Void) {
        completion(entry(at: Date(), context: context))
    }

    /// One entry now, then one at every moment the content changes: a scheduled time
    /// passing, and midnight. No refresh interval — a widget waking on a timer to
    /// redraw the same words spends the system's budget saying nothing.
    func getTimeline(in context: Context, completion: @escaping (Timeline<TodayEntry>) -> Void) {
        let now = Date()
        let snapshot = WidgetSnapshotStore().read() ?? .empty
        let dates = [now] + WidgetState.refreshDates(snapshot: snapshot, now: now)
        let entries = dates.map { date in
            TodayEntry(
                date: date,
                state: WidgetState.resolve(snapshot: snapshot, now: date),
                isWide: context.family == .systemMedium
            )
        }
        // `.atEnd`: once the last known change has been drawn, ask for a new
        // timeline. Everything else arrives via `reloadAllTimelines` when the app
        // rewrites the snapshot.
        completion(Timeline(entries: entries, policy: .atEnd))
    }

    private func entry(at date: Date, context: Context) -> TodayEntry {
        let snapshot = WidgetSnapshotStore().read() ?? .empty
        return TodayEntry(
            date: date,
            state: WidgetState.resolve(snapshot: snapshot, now: date),
            isWide: context.family == .systemMedium
        )
    }
}

extension WidgetState {
    /// Breathing keeps the green it has everywhere else in the app; everything else
    /// takes the primary accent, exactly as the launcher rows do.
    var tint: Color {
        switch self {
        case .scheduled(let exercise, _) where exercise == .breathing: AppColors.positive
        case .tail, .scheduled, .logExposure: AppColors.primary
        }
    }
}
