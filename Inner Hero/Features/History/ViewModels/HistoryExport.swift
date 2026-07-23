import Foundation

/// JSON export of every log in the app (spec §2.3.5).
///
/// Snapshot structs rather than making the `@Model` types `Codable`: the models
/// are free to change shape during the rebuild, and an export format that moves
/// with them would silently break whatever a therapist opened it with. This is
/// the one place where a second representation of the data is the point.
///
/// The file never leaves the device on its own — it is handed to the system
/// share sheet and goes wherever the user sends it (§1.9).
nonisolated enum HistoryExport {

    struct Payload: Codable {
        let exportedAt: Date
        let exposures: [Exposure]
        let breathing: [Breathing]
        let relaxation: [Relaxation]
        let activation: [Activation]
    }

    struct Exposure: Codable {
        let createdAt: Date
        let kind: String
        let situation: String
        let activity: String?
        let anxiety: Int?
        let behavior: String?
        let safetyBehaviors: [String]
        let note: String?
        let fearedOutcome: String?
        let confidence: String?
        let expectedAnxiety: Int?
        let targetDurationSeconds: Int?
        let actualDurationSeconds: Int?
        let predictionOutcome: String?
    }

    struct Breathing: Codable {
        let createdAt: Date
        let pattern: String
        let plannedDurationSeconds: Int
        let actualDurationSeconds: Int?
        let didRelax: Bool?
        let wasPaused: Bool
        let note: String?
    }

    struct Relaxation: Codable {
        let createdAt: Date
        let step: String
        let plannedDurationSeconds: Int
        let actualDurationSeconds: Int?
        let groupsCompleted: Int
        let didRelax: Bool?
        let note: String?
    }

    struct Activation: Codable {
        let createdAt: Date
        let activityTitle: String
        let effort: String
        let energy: String
        let forecast: String?
        let outcome: String?
        let answeredAt: Date?
        let pleasure: Int?
        let mastery: Int?
        let note: String?
    }

    /// - Parameter now: injected so the exported timestamp is reproducible in
    ///   tests; nothing here reads the clock on its own.
    static func payload(
        exposures: [ExposureLogEntry],
        breathing: [BreathingSessionEntry],
        relaxation: [PMRSessionEntry],
        activation: [BALogEntry],
        now: Date = Date()
    ) -> Payload {
        Payload(
            exportedAt: now,
            exposures: exposures.sorted { $0.createdAt < $1.createdAt }.map {
                Exposure(
                    createdAt: $0.createdAt,
                    // Spelled out rather than a bare bool: whoever opens this
                    // file has not read the spec.
                    kind: $0.isPlanned ? "planned" : "situational",
                    situation: $0.situation,
                    activity: $0.activity,
                    anxiety: $0.anxiety,
                    behavior: $0.behaviorRaw,
                    safetyBehaviors: $0.safetyBehaviors,
                    note: $0.note,
                    fearedOutcome: $0.fearedOutcome,
                    confidence: $0.confidenceRaw,
                    expectedAnxiety: $0.expectedAnxiety,
                    targetDurationSeconds: $0.targetDurationSeconds,
                    actualDurationSeconds: $0.actualDurationSeconds,
                    predictionOutcome: $0.predictionOutcomeRaw
                )
            },
            breathing: breathing.sorted { $0.createdAt < $1.createdAt }.map {
                Breathing(
                    createdAt: $0.createdAt,
                    pattern: $0.patternRaw,
                    plannedDurationSeconds: $0.plannedDurationSeconds,
                    actualDurationSeconds: $0.actualDurationSeconds,
                    didRelax: $0.didRelax,
                    wasPaused: $0.wasPaused,
                    note: $0.note
                )
            },
            relaxation: relaxation.sorted { $0.createdAt < $1.createdAt }.map {
                Relaxation(
                    createdAt: $0.createdAt,
                    step: $0.stepRaw,
                    plannedDurationSeconds: $0.plannedDurationSeconds,
                    actualDurationSeconds: $0.actualDurationSeconds,
                    groupsCompleted: $0.groupsCompleted,
                    didRelax: $0.didRelax,
                    note: $0.note
                )
            },
            activation: activation.sorted { $0.createdAt < $1.createdAt }.map {
                Activation(
                    createdAt: $0.createdAt,
                    activityTitle: $0.activityTitle,
                    effort: $0.effortRaw,
                    energy: $0.energyRaw,
                    forecast: $0.forecastRaw,
                    outcome: $0.outcomeRaw,
                    answeredAt: $0.answeredAt,
                    pleasure: $0.pleasure,
                    mastery: $0.mastery,
                    note: $0.note
                )
            }
        )
    }

    static func data(for payload: Payload) throws -> Data {
        let encoder = JSONEncoder()
        // Readable on purpose: the file is meant to be opened by a person, and
        // ISO dates survive being pasted into a spreadsheet.
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(payload)
    }
}
