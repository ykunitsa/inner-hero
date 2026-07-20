import Foundation
import Observation
import SwiftData

/// Logic of the planned exposure flow (spec §3, §11.2): the "before"
/// prediction block, the hidden-random-end session, and the "after" fact
/// screen. One entry travels through all three stages: it is inserted into
/// the store at "Start" (principle 1.6 made physical — the prediction exists
/// before the session; principle 1.5 — killing the app mid-session leaves a
/// truthful partial record), and the "after" stage only fills in fact columns.
@Observable @MainActor
final class PlannedExposureFlowViewModel {

    enum Stage {
        case before
        case during
        case after
    }

    /// What the session clock owes the UI at a given moment.
    /// The last 5 seconds are a haptic countdown (one tick per second),
    /// `sessionEnd` is the distinct final signal.
    enum EndSignal {
        case countdownTick
        case sessionEnd
    }

    // MARK: Constants

    nonisolated static let rangeBounds = 1...20
    nonisolated static let defaultRangeMinMinutes = 3
    nonisolated static let defaultRangeMaxMinutes = 8
    nonisolated static let defaultIntensity = 5
    /// Seconds of haptic countdown before the end.
    nonisolated static let countdownSeconds = 5

    // MARK: Stage

    private(set) var stage: Stage = .before

    // MARK: "Before" state

    var activity = ""
    var fearedOutcome = ""
    /// Seeded, unlike the two text fields: the scale is a slider, and a slider
    /// always points somewhere. `fiftyFifty` and not one of the ends — the
    /// default has to be the option that claims the least, because this field
    /// feeds the "predictions that didn't come true" share (spec §5). Same
    /// reasoning as `defaultIntensity` starting mid-scale.
    ///
    /// Consequence worth knowing: a user who skips the question still records
    /// "fifty-fifty". Telling that apart from a deliberate answer would need a
    /// separate "field was touched" flag, which does not exist.
    var confidence: PredictionConfidence = .fiftyFifty
    var expectedAnxiety = PlannedExposureFlowViewModel.defaultIntensity
    var rangeMinMinutes = PlannedExposureFlowViewModel.defaultRangeMinMinutes
    var rangeMaxMinutes = PlannedExposureFlowViewModel.defaultRangeMaxMinutes

    private(set) var activitySuggestions: [String] = []
    private(set) var safetyBehaviorOptions: [String] = []

    // MARK: Session state

    private(set) var entry: ExposureLogEntry?
    private(set) var startedAt: Date?
    private(set) var targetDuration: TimeInterval = 0
    private var firedTickSeconds: Set<Int> = []
    private var endSignalFired = false

    // MARK: "After" state

    var predictionOutcome: PredictionOutcome?
    var actualSituation = ""
    var behavior: ExposureBehavior?
    var selectedSafetyBehaviors: Set<String> = []
    var isNothingSelected = false
    var overallDifficulty = PlannedExposureFlowViewModel.defaultIntensity

    private var generator: any RandomNumberGenerator

    init(generator: any RandomNumberGenerator = SystemRandomNumberGenerator()) {
        self.generator = generator
    }

    // MARK: Configuration

    func configure(history entries: [ExposureLogEntry]) {
        activitySuggestions = SituationalExposureFormViewModel.situationSuggestions(from: entries)
        safetyBehaviorOptions = SituationalExposureFormViewModel.safetyBehaviorOptions(history: entries)
        // Smart default (codex §2): the last used range carries over.
        if let lastPlanned = entries
            .filter({ $0.isPlanned })
            .max(by: { $0.createdAt < $1.createdAt }),
            let minSeconds = lastPlanned.plannedMinSeconds,
            let maxSeconds = lastPlanned.plannedMaxSeconds {
            let lower = Self.rangeBounds.lowerBound
            let upper = Self.rangeBounds.upperBound
            rangeMinMinutes = min(max(minSeconds / 60, lower), upper - 1)
            rangeMaxMinutes = min(max(maxSeconds / 60, rangeMinMinutes + 1), upper)
        }
    }

    // MARK: "Before" intents

    func applySuggestion(_ text: String) {
        activity = text
    }

    var trimmedActivity: String {
        activity.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedFearedOutcome: String {
        fearedOutcome.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Only the two written parts of the prediction are required — confidence,
    /// the time range and expected anxiety all come seeded.
    var canStart: Bool {
        !trimmedActivity.isEmpty && !trimmedFearedOutcome.isEmpty
    }

    /// Anything worth protecting from an accidental close on "before".
    /// Confidence is deliberately not counted: it is seeded, so counting it
    /// would make an untouched form prompt "Discard this entry?" on close.
    var hasBeforeDraft: Bool {
        !trimmedActivity.isEmpty || !trimmedFearedOutcome.isEmpty
    }

    /// Uniform pick inside [min, max] — the user must not be able to predict
    /// the end (spec §3), so the value is never shown.
    nonisolated static func randomTargetSeconds(
        minSeconds: Int,
        maxSeconds: Int,
        using generator: inout any RandomNumberGenerator
    ) -> Int {
        Int.random(in: min(minSeconds, maxSeconds)...max(minSeconds, maxSeconds), using: &generator)
    }

    /// Inserts the entry with the prediction block and starts the session.
    func startSession(in context: ModelContext, now: Date = Date()) throws {
        guard canStart, entry == nil else { return }
        let minSeconds = rangeMinMinutes * 60
        let maxSeconds = rangeMaxMinutes * 60
        let target = Self.randomTargetSeconds(
            minSeconds: minSeconds,
            maxSeconds: maxSeconds,
            using: &generator
        )
        let newEntry = ExposureLogEntry(
            plannedAt: now,
            activity: trimmedActivity,
            fearedOutcome: trimmedFearedOutcome,
            confidence: confidence,
            expectedAnxiety: expectedAnxiety,
            plannedMinSeconds: minSeconds,
            plannedMaxSeconds: maxSeconds,
            targetDurationSeconds: target
        )
        context.insert(newEntry)
        try context.save()

        entry = newEntry
        startedAt = now
        targetDuration = TimeInterval(target)
        // Pre-fill "what actually happened" with the PREDICTION, not the plan.
        // The field sits right under "did it come true" (spec §3), so it is
        // the counterpart of the fear, not of the activity name: the user
        // edits "I'll leave in two minutes" into what really happened. Seeded
        // with the activity it answered a question nobody asked.
        actualSituation = trimmedFearedOutcome
        stage = .during
    }

    // MARK: Session clock

    func elapsed(now: Date) -> TimeInterval {
        guard let startedAt else { return 0 }
        return max(now.timeIntervalSince(startedAt), 0)
    }

    nonisolated static func formatElapsed(_ interval: TimeInterval) -> String {
        let total = max(Int(interval), 0)
        return String(format: "%02d:%02d", total / 60, total % 60)
    }

    /// Polled by the view (~4×/second). Returns at most one due signal per
    /// call and remembers what already fired, so a return from background
    /// produces a single catch-up tick, not a burst.
    func dueSignal(now: Date) -> EndSignal? {
        guard stage == .during, startedAt != nil else { return nil }
        let remaining = targetDuration - elapsed(now: now)
        if remaining <= 0 {
            guard !endSignalFired else { return nil }
            endSignalFired = true
            return .sessionEnd
        }
        let secondsLeft = Int(remaining.rounded(.up))
        guard secondsLeft <= Self.countdownSeconds, !firedTickSeconds.contains(secondsLeft) else {
            return nil
        }
        firedTickSeconds.formUnion(secondsLeft...Self.countdownSeconds)
        return .countdownTick
    }

    // MARK: Session end

    /// The vibration said "done": the fact duration is the planned target.
    func completeSession(in context: ModelContext, now: Date = Date()) {
        guard stage == .during, let entry else { return }
        entry.actualDurationSeconds = Int(targetDuration)
        try? context.save()
        stage = .after
    }

    /// "Finish early" — saves the fact, never discards (principle 1.5).
    func finishEarly(in context: ModelContext, now: Date = Date()) {
        guard stage == .during, let entry else { return }
        entry.actualDurationSeconds = min(Int(elapsed(now: now)), Int(targetDuration))
        try? context.save()
        stage = .after
    }

    // MARK: "After" intents (safety block mirrors the situational form)

    func toggleNothing() {
        isNothingSelected.toggle()
        if isNothingSelected {
            selectedSafetyBehaviors.removeAll()
        }
    }

    func toggleSafetyBehavior(_ text: String) {
        if selectedSafetyBehaviors.contains(text) {
            selectedSafetyBehaviors.remove(text)
        } else {
            selectedSafetyBehaviors.insert(text)
            isNothingSelected = false
        }
    }

    @discardableResult
    func addCustomSafetyBehavior(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        if !safetyBehaviorOptions.contains(trimmed) {
            safetyBehaviorOptions.append(trimmed)
        }
        selectedSafetyBehaviors.insert(trimmed)
        isNothingSelected = false
        return true
    }

    var isSafetyAnswered: Bool {
        isNothingSelected || !selectedSafetyBehaviors.isEmpty
    }

    var trimmedActualSituation: String {
        actualSituation.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var canSaveAfter: Bool {
        predictionOutcome != nil
            && !trimmedActualSituation.isEmpty
            && behavior != nil
            && isSafetyAnswered
    }

    /// Writes the fact block. The prediction block is never touched here
    /// (principle 1.6).
    func saveAfter(in context: ModelContext) throws {
        guard canSaveAfter, let entry else { return }
        applyAfterFields(to: entry)
        try context.save()
    }

    /// Closing the "after" screen keeps whatever is filled — the entry with
    /// its prediction and duration is already data (principle 1.5).
    func savePartial(in context: ModelContext) throws {
        guard let entry else { return }
        applyAfterFields(to: entry)
        try context.save()
    }

    private func applyAfterFields(to entry: ExposureLogEntry) {
        entry.predictionOutcomeRaw = predictionOutcome?.rawValue
        if !trimmedActualSituation.isEmpty {
            entry.situation = trimmedActualSituation
        }
        entry.behaviorRaw = behavior?.rawValue
        if isSafetyAnswered {
            entry.safetyBehaviors = isNothingSelected
                ? []
                : safetyBehaviorOptions.filter(selectedSafetyBehaviors.contains)
            // Keep the on-screen chip order in the stored array (see above).
        }
        if behavior != nil || predictionOutcome != nil {
            entry.anxiety = overallDifficulty
        }
    }
}
