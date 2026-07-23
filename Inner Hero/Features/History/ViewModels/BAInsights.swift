import Foundation

/// "Что работает" (spec §6): what the BA log says about the gap between what the
/// user expected of an activity and how it actually went.
///
/// Everything here is an observation about the past. Nothing suggests what to do
/// next, picks an activity, or reorders the store — the app is an executor, not
/// an advisor (§1.1), and the rule that fires elsewhere is the only thing in the
/// app allowed to propose anything (§1.8).
nonisolated enum BAInsights {

    /// How many rated activities of one kind before the app says anything about
    /// it. Below this a "7 of 8" is noise wearing the clothes of a finding.
    static let minimumRatings = 3

    // MARK: Types

    struct ActivityRow: Identifiable {
        let id: String
        let title: String
        /// Activities that were done *and* rated — the only ones comparable
        /// against a forecast.
        let rated: Int
        let beatForecast: Int
    }

    struct Insight {
        let title: String
        let beatForecast: Int
        let rated: Int
    }

    // MARK: Forecast → expected rating

    /// The forecast chips (§6) mapped onto the 0–10 rating scale so the two can
    /// be compared at all.
    ///
    /// Deliberately conservative: each value sits at the *top* of what that chip
    /// promises, so "better than expected" means clearly better, not a rounding
    /// artefact. Getting a 6 after saying "maybe" is not a discovery.
    static func expectedPleasure(_ forecast: BAForecast) -> Int {
        switch forecast {
        case .definitely: 8
        case .maybe: 6
        case .unlikely: 3
        case .notAtAll: 1
        }
    }

    // MARK: Aggregation

    /// One row per activity, newest-independent — order comes from the sort
    /// below, never from the order entries happen to arrive in.
    ///
    /// Only entries that were done, rated, and forecast count: without a
    /// forecast there is nothing to beat, and a forecast recorded after the fact
    /// would be exactly the hindsight the app refuses to collect (§1.6).
    static func rows(_ entries: [BALogEntry]) -> [ActivityRow] {
        let comparable = entries.filter {
            $0.outcome == .done && $0.pleasure != nil && $0.forecast != nil
        }

        let grouped = Dictionary(grouping: comparable) { entry in
            // The store row when it still exists, the title otherwise: a
            // deleted activity keeps its history instead of splitting it.
            entry.activityID?.uuidString ?? "title:\(entry.activityTitle)"
        }

        return grouped
            .compactMap { key, entries -> ActivityRow? in
                guard let title = entries.first?.activityTitle else { return nil }
                let beat = entries.filter { entry in
                    guard let pleasure = entry.pleasure, let forecast = entry.forecast else {
                        return false
                    }
                    return pleasure > expectedPleasure(forecast)
                }.count

                return ActivityRow(
                    id: key,
                    title: title,
                    rated: entries.count,
                    beatForecast: beat
                )
            }
            .sorted {
                // Most surprising first, then by volume, then alphabetically so
                // the table never reshuffles between identical data sets.
                if $0.beatForecast != $1.beatForecast { return $0.beatForecast > $1.beatForecast }
                if $0.rated != $1.rated { return $0.rated > $1.rated }
                return $0.title < $1.title
            }
    }

    // MARK: The insight

    /// The single card (§6). Nil unless one activity has enough ratings *and*
    /// beat its forecast more often than not — a finding the user could not have
    /// read off the table themselves is the only thing worth a card.
    static func insight(_ rows: [ActivityRow]) -> Insight? {
        guard let candidate = rows.first(where: {
            $0.rated >= minimumRatings && $0.beatForecast * 2 > $0.rated
        }) else { return nil }

        return Insight(
            title: candidate.title,
            beatForecast: candidate.beatForecast,
            rated: candidate.rated
        )
    }

    /// The closing line (§6): the same comparison across everything at once.
    /// Nil while nothing has been rated — a "0 of 0" says nothing.
    static func summary(_ rows: [ActivityRow]) -> (beatForecast: Int, rated: Int)? {
        let rated = rows.reduce(0) { $0 + $1.rated }
        guard rated > 0 else { return nil }
        return (rows.reduce(0) { $0 + $1.beatForecast }, rated)
    }
}
