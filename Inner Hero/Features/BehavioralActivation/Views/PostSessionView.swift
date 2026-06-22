import SwiftUI
import SwiftData

// MARK: - PostSessionView (Step 3 of 3)
// Records mood after, computes delta, saves the session.
// If moodBefore is nil, first asks for retrospective "before" rating (Spec §8.1).

struct PostSessionView: View {
    let sessionId: UUID
    var embeddedInFlow: Bool = false
    @Binding var saveRequested: Bool
    @Binding var showingSchedule: Bool
    let onFinished: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(BehavioralActivationViewModel.self) private var vm

    @Query private var sessions: [ActivationSession]
    @Query private var tasks: [ActivationTask]

    @State private var moodAfter: Int? = nil
    @State private var retroMoodBefore: Int? = nil
    @State private var reflectionText: String = ""

    private var session: ActivationSession? { sessions.first { $0.id == sessionId } }
    private var task: ActivationTask? {
        guard let s = session else { return nil }
        return tasks.first { $0.id == s.activityId }
    }
    private var effectiveMoodBefore: Int? {
        session?.moodBefore ?? retroMoodBefore
    }

    var body: some View {
        Group {
            if let t = task, let s = session {
                mainContent(task: t, session: s)
            } else {
                ContentUnavailableView(String(localized: "Session not found"), systemImage: "questionmark.circle")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .pageBackground()
            }
        }
        .navigationBarBackButtonHidden(true)
        .onChange(of: saveRequested) { _, requested in
            guard requested, let t = task, let s = session else {
                saveRequested = false
                return
            }
            saveSession(task: t, session: s)
            saveRequested = false
        }
    }

    // MARK: - Content

    @ViewBuilder
    private func mainContent(task: ActivationTask, session: ActivationSession) -> some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                completionHeader(task: task, session: session)

                DeltaCard(moodBefore: effectiveMoodBefore, moodAfter: moodAfter)

                if session.moodBefore == nil {
                    retroMoodSection
                }

                moodAfterSection
                reflectionSection

                Spacer(minLength: Spacing.xxl)
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.top, Spacing.sm)
        }
        .modifier(PostFlowBackground(embedded: embeddedInFlow))
        .modifier(PostScheduleSheetModifier(embedded: embeddedInFlow, showingSchedule: $showingSchedule, task: task))
    }

    // MARK: - Sections

    private func completionHeader(task: ActivationTask, session: ActivationSession) -> some View {
        VStack(spacing: Spacing.xxs) {
            ZStack {
                Circle()
                    .fill(AppColors.positive.opacity(Opacity.mediumBackground))
                    .frame(width: IconSize.hero, height: IconSize.hero)
                Image(systemName: "checkmark")
                    .font(.system(size: IconSize.inline, weight: .bold))
                    .foregroundStyle(AppColors.positive)
            }

            Text(String(localized: "Activity completed"))
                .appFont(.h2)
                .foregroundStyle(TextColors.primary)

            let subtitle = subtitleText(task: task, session: session)
            Text(subtitle)
                .appFont(.body)
                .foregroundStyle(TextColors.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.sm)
    }

    private func subtitleText(task: ActivationTask, session: ActivationSession) -> String {
        var parts = [task.localizedTitle]
        if let minutes = session.actualMinutes {
            parts.append(String(format: String(localized: "%lld min"), Int64(minutes)))
        }
        return parts.joined(separator: " · ")
    }

    private var retroMoodSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            VStack(alignment: .leading, spacing: Spacing.xxxs) {
                Text(String(localized: "How did you feel beforehand?"))
                    .appFont(.h3)
                    .foregroundStyle(TextColors.primary)
                Text(String(localized: "Try to remember how you felt before you started."))
                    .appFont(.small)
                    .foregroundStyle(TextColors.secondary)
            }
            MoodEmojiSlider(selectedMood: $retroMoodBefore)
        }
        .padding(Spacing.sm)
        .cardStyle(cornerRadius: CornerRadius.md, padding: 0)
    }

    private var moodAfterSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(String(localized: "Mood now"))
                .appFont(.h3)
                .foregroundStyle(TextColors.primary)
            MoodEmojiSlider(selectedMood: $moodAfter)
        }
        .padding(Spacing.sm)
        .cardStyle(cornerRadius: CornerRadius.md, padding: 0)
    }

    private var reflectionSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text(String(localized: "How did it go?"))
                .appFont(.bodyMedium)
                .foregroundStyle(TextColors.secondary)

            AppTextEditor(
                text: $reflectionText,
                placeholder: String(localized: "Hard to start, but it got easier…"),
                minHeight: 70,
                fillColor: AppColors.gray100
            )
        }
        .padding(Spacing.sm)
        .cardStyle(cornerRadius: CornerRadius.md, padding: 0)
    }

    // MARK: - Save

    private func saveSession(task: ActivationTask, session: ActivationSession) {
        let finalMoodBefore = effectiveMoodBefore
        let finalMoodAfter = moodAfter

        if let b = finalMoodBefore, session.moodBefore == nil {
            session.moodBefore = b
        }
        session.moodAfter = finalMoodAfter
        if let before = finalMoodBefore, let after = finalMoodAfter {
            session.moodDelta = after - before
        } else {
            session.moodDelta = nil
        }
        session.reflectionNote = reflectionText.isEmpty ? nil : reflectionText
        session.status = .completed
        session.completedAt = Date()

        if session.actualMinutes == nil, let startedAt = session.startedAt {
            session.actualMinutes = max(0, Int(Date().timeIntervalSince(startedAt) / 60))
        }

        try? modelContext.save()
        HapticFeedback.success()

        vm.selectedTab = 1
        onFinished()
    }
}

// MARK: - Background

private struct PostFlowBackground: ViewModifier {
    let embedded: Bool

    func body(content: Content) -> some View {
        if embedded {
            content
        } else {
            content.homeBackground()
        }
    }
}

private struct PostScheduleSheetModifier: ViewModifier {
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
