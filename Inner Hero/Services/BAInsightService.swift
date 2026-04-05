import Foundation

enum BAInsightService {

    static func averageMoodDelta(for sessions: [BASession]) -> Double? {
        let deltas = sessions
            .filter { $0.status == .completed }
            .compactMap { $0.moodDelta }
        guard !deltas.isEmpty else { return nil }
        return Double(deltas.reduce(0, +)) / Double(deltas.count)
    }

    static func averageDeltaByValue(sessions: [BASession]) -> [LifeValue: Double] {
        let completed = sessions.filter { $0.status == .completed }

        var grouped: [LifeValue: [Int]] = [:]
        for session in completed {
            guard let delta = session.moodDelta,
                  let value = session.activity?.lifeValue else { continue }
            grouped[value, default: []].append(delta)
        }

        return grouped.compactMapValues { deltas in
            guard !deltas.isEmpty else { return nil }
            return Double(deltas.reduce(0, +)) / Double(deltas.count)
        }
    }

    static func topLifeValues(sessions: [BASession], limit: Int = 3) -> [(LifeValue, Double)] {
        averageDeltaByValue(sessions: sessions)
            .sorted { $0.value > $1.value }
            .prefix(limit)
            .map { ($0.key, $0.value) }
    }

    static func sessionsInLastDays(_ days: Int, from sessions: [BASession]) -> [BASession] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return sessions.filter { session in
            guard let completedAt = session.completedAt else { return false }
            return completedAt >= cutoff
        }
    }

    static func keyInsightText(sessions: [BASession]) -> String? {
        let lowMoodCompleted = sessions.filter {
            $0.moodBefore <= 4 && $0.status == .completed
        }
        let total = lowMoodCompleted.count
        let improved = lowMoodCompleted.filter { ($0.moodDelta ?? 0) > 0 }.count
        guard improved >= 3 else { return nil }
        return "In \(improved) out of \(total) cases, your mood improved even when it started at 4/10 or below."
    }
}
