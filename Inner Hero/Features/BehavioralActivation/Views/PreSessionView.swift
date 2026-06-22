import SwiftUI
import SwiftData

// MARK: - PreSessionView (Step 1 of 3)
// Captures mood before and optional barrier note, then creates the ActivationSession.

struct PreSessionView: View {
    let taskId: UUID
    /// Parent sets `true` from the bottom pill to create a session and advance.
    @Binding var startFromParentPill: Bool
    @Binding var showingSchedule: Bool
    /// When embedded in `BASessionFlowView`, backgrounds and chrome are owned by the container.
    var embeddedInFlow: Bool = false
    let onSessionCreated: (UUID) -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(NotificationManager.self) private var notificationManager

    @Query private var tasks: [ActivationTask]
    @Query private var categories: [ActivationCategory]
    @Query private var sessions: [ActivationSession]

    @State private var selectedMood: Int? = nil
    @State private var barrierText: String = ""

    private var task: ActivationTask? { tasks.first { $0.id == taskId } }
    private var category: ActivationCategory? {
        guard let t = task else { return nil }
        return categories.first { $0.id == t.categoryId }
    }

    var body: some View {
        Group {
            if let t = task {
                content(task: t)
            } else {
                ContentUnavailableView(String(localized: "Activity not found"), systemImage: "questionmark.circle")
            }
        }
        .navigationBarBackButtonHidden(true)
        .onChange(of: startFromParentPill) { _, isRequested in
            guard isRequested, let t = task else {
                startFromParentPill = false
                return
            }
            startSession(task: t)
            startFromParentPill = false
        }
    }

    @ViewBuilder
    private func content(task: ActivationTask) -> some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                ActivityPill(task: task, category: category)
                    .padding(.top, Spacing.xxs)

                moodSection
                barrierSection

                Spacer(minLength: Spacing.xxl)
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.top, Spacing.sm)
        }
        .modifier(PreFlowBackground(embedded: embeddedInFlow))
        .modifier(PreScheduleSheetModifier(embedded: embeddedInFlow, showingSchedule: $showingSchedule, task: task))
    }

    // MARK: - Mood Section

    private var moodSection: some View {
        VStack(alignment: .center, spacing: Spacing.sm) {
            Text(String(localized: "How do you feel right now?"))
                .appFont(.h2)
                .foregroundStyle(TextColors.primary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            MoodEmojiSlider(selectedMood: $selectedMood)
        }
    }

    // MARK: - Barrier Section

    private var barrierSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text(String(localized: "What's making it hard to start?"))
                .appFont(.bodyMedium)
                .foregroundStyle(TextColors.secondary)

            AppTextEditor(
                text: $barrierText,
                placeholder: String(localized: "Low energy, tired…"),
                minHeight: 70,
                fillColor: AppColors.cardBackground
            )
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Actions

    private func startSession(task: ActivationTask) {
        let now = Date()

        // Fulfil (consume) a due one-time planned session for this task so planned entries
        // don't dangle in the journal. Recurring plans live on ExerciseAssignment and are left intact.
        if let plannedDue = sessions.first(where: { isDueOneTimePlan($0, task: task, now: now) }) {
            let plannedId = plannedDue.id
            modelContext.delete(plannedDue)
            Task { await notificationManager.cancelActivationReminders(id: plannedId) }
        }

        let session = ActivationSession(
            activityId: task.id,
            status: .inProgress,
            moodBefore: selectedMood,
            barrierNote: barrierText.isEmpty ? nil : barrierText,
            startedAt: now
        )
        modelContext.insert(session)
        do {
            try modelContext.save()
        } catch {
            print("Failed to start BA session: \(error)")
        }
        onSessionCreated(session.id)
    }

    private func isDueOneTimePlan(_ session: ActivationSession, task: ActivationTask, now: Date) -> Bool {
        guard session.activityId == task.id,
              session.status == .planned,
              session.assignmentId == nil,
              let plannedFor = session.plannedFor else { return false }
        return Calendar.current.isDateInToday(plannedFor) || plannedFor <= now
    }
}

// MARK: - Background

private struct PreFlowBackground: ViewModifier {
    let embedded: Bool

    func body(content: Content) -> some View {
        if embedded {
            content
        } else {
            content.homeBackground()
        }
    }
}

private struct PreScheduleSheetModifier: ViewModifier {
    let embedded: Bool
    @Binding var showingSchedule: Bool
    let task: ActivationTask

    func body(content: Content) -> some View {
        if embedded {
            content
        } else {
            content
                .sheet(isPresented: $showingSchedule) {
                    SchedulePickerSheet(task: task)
                        .presentationDetents([.medium, .large])
                        .presentationDragIndicator(.visible)
                }
        }
    }
}
