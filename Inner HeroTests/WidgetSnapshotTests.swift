import Foundation
import SwiftData
import Testing

@testable import Inner_Hero

/// §11.7 — what the app hands to its widgets, and what it refuses to hand over.
@Suite("Widget snapshot")
struct WidgetSnapshotTests {

    private static func calendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        calendar.firstWeekday = 2
        return calendar
    }

    private static func context() throws -> ModelContext {
        let container = try ModelContainer(
            for: ScheduleItem.self, BreathingSessionEntry.self, PMRSessionEntry.self,
            BAActivity.self, BALogEntry.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    // MARK: Storage

    @Test("A snapshot survives the trip through the shared container")
    func roundTrip() throws {
        let defaults = UserDefaults(suiteName: "widget.snapshot.tests")!
        defer { defaults.removePersistentDomain(forName: "widget.snapshot.tests") }

        let store = WidgetSnapshotStore(defaults: defaults)
        let snapshot = WidgetSnapshot(
            openTailTitle: "Walk to the park",
            items: [WidgetSnapshot.Item(
                exerciseRaw: ScheduledExercise.breathing.rawValue,
                timeText: "18:00", hour: 18, minute: 0,
                recurrenceRaw: ScheduleRecurrence.weekly.rawValue,
                weekdays: [2, 4], monthDay: 1, onceDate: nil
            )],
            subtitles: ["breathing": "Box · 10 min"]
        )

        store.write(snapshot)

        #expect(store.read() == snapshot)
    }

    @Test("Without a shared container, reading is empty rather than fatal")
    func missingContainerIsAState() {
        #expect(WidgetSnapshotStore(defaults: nil).read() == nil)
    }

    // MARK: Building

    @Test("The schedule travels with the fields the rule needs")
    func scheduleTravelsRaw() throws {
        let context = try Self.context()
        context.insert(ScheduleItem(
            exercise: .relaxation, recurrence: .monthly, hour: 21, minute: 30, monthDay: 31
        ))

        let snapshot = WidgetSnapshotBuilder.build(
            schedule: try context.fetch(FetchDescriptor<ScheduleItem>()),
            breathing: [], pmr: [], activation: [],
            isLocked: false, calendar: Self.calendar()
        )

        #expect(snapshot.items.count == 1)
        #expect(snapshot.items.first?.recurrence == .monthly)
        #expect(snapshot.items.first?.monthDay == 31)
        #expect(snapshot.items.first?.hour == 21)
    }

    @Test("A disabled entry is absent, exactly as it is absent from the day list")
    func disabledEntriesAreOmitted() throws {
        let context = try Self.context()
        context.insert(ScheduleItem(
            exercise: .breathing, recurrence: .weekly, hour: 18, minute: 0, isEnabled: false
        ))

        let snapshot = WidgetSnapshotBuilder.build(
            schedule: try context.fetch(FetchDescriptor<ScheduleItem>()),
            breathing: [], pmr: [], activation: [],
            isLocked: false, calendar: Self.calendar()
        )

        #expect(snapshot.items.isEmpty)
    }

    @Test("With no sessions there is no ladder position — the tile falls back to its phrase")
    func zeroSessionsHaveNoPosition() {
        let snapshot = WidgetSnapshotBuilder.build(
            schedule: [], breathing: [], pmr: [], activation: [],
            isLocked: false, calendar: Self.calendar()
        )

        #expect(snapshot.subtitle(for: .breathing) == nil)
        #expect(snapshot.subtitle(for: .relaxation) == nil)
    }

    @Test("The open tail travels; a closed one does not")
    func onlyTheOpenTailTravels() throws {
        let context = try Self.context()
        let answered = BALogEntry(
            createdAt: Date(), activityID: nil, activityTitle: "Dishes",
            effort: .easy, energy: .little, forecast: nil
        )
        answered.outcomeRaw = BAOutcome.done.rawValue
        let open = BALogEntry(
            createdAt: Date(), activityID: nil, activityTitle: "Walk to the park",
            effort: .easy, energy: .little, forecast: nil
        )
        context.insert(answered)
        context.insert(open)

        let snapshot = WidgetSnapshotBuilder.build(
            schedule: [], breathing: [], pmr: [],
            activation: try context.fetch(FetchDescriptor<BALogEntry>()),
            isLocked: false, calendar: Self.calendar()
        )

        #expect(snapshot.openTailTitle == "Walk to the park")
    }

    // MARK: Redaction

    @Test("Under App Lock the shared container never receives the content at all")
    func lockRedactsOnWrite() throws {
        let context = try Self.context()
        context.insert(ScheduleItem(exercise: .breathing, recurrence: .weekly, hour: 18, minute: 0))
        context.insert(BALogEntry(
            createdAt: Date(), activityID: nil, activityTitle: "Call mum",
            effort: .easy, energy: .little, forecast: nil
        ))

        let snapshot = WidgetSnapshotBuilder.build(
            schedule: try context.fetch(FetchDescriptor<ScheduleItem>()),
            breathing: [], pmr: [],
            activation: try context.fetch(FetchDescriptor<BALogEntry>()),
            isLocked: true, calendar: Self.calendar()
        )

        #expect(snapshot.isRedacted)
        #expect(snapshot.openTailTitle == nil)
        #expect(snapshot.items.isEmpty)
        #expect(snapshot.subtitles.isEmpty)
    }

    @Test("A redacted snapshot resolves to the entry that reveals nothing")
    func redactedResolvesToExposure() {
        let state = WidgetState.resolve(
            snapshot: WidgetSnapshot(isRedacted: true), calendar: Self.calendar()
        )

        #expect(state == .logExposure)
    }
}
