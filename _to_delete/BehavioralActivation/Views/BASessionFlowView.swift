import SwiftUI
import SwiftData
import Combine

// MARK: - BASessionFlowView

/// Single pushed screen: Pre → Active → Post with Grounding-style header + `SessionFlowBottomPill`.
struct BASessionFlowView: View {
    let taskId: UUID

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Environment(BehavioralActivationViewModel.self) private var vm
    @Environment(NotificationManager.self) private var notificationManager

    @Query private var allTasks: [ActivationTask]
    @Query private var sessions: [ActivationSession]

    private enum FlowPhase: Equatable {
        case pre
        case active(UUID)
        case post(UUID)
    }

    @State private var phase: FlowPhase = .pre

    @State private var requestPreStart = false
    @State private var requestActiveComplete = false
    @State private var requestPostSave = false

    @State private var showingSchedule = false

    // Active-step timer / pause (single source of truth for pill + `BAActiveSessionView`)
    @State private var activeNow = Date()
    @State private var activeIsPaused = false
    @State private var activePauseStart: Date?
    @State private var activeTotalPaused: TimeInterval = 0
    @State private var activeTicker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var task: ActivationTask? { allTasks.first { $0.id == taskId } }

    private var stepIndex: Int {
        switch phase {
        case .pre: return 1
        case .active: return 2
        case .post: return 3
        }
    }

    private var navigationTitle: String {
        task?.localizedTitle ?? String(localized: "Behavioral activation")
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    AppColors.accentLight.opacity(0.5),
                    AppColors.gray100
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                stepHeader
                    .padding(.horizontal, Spacing.sm)
                    .padding(.top, Spacing.sm)

                Group {
                    switch phase {
                    case .pre:
                        PreSessionView(
                            taskId: taskId,
                            startFromParentPill: $requestPreStart,
                            showingSchedule: $showingSchedule,
                            embeddedInFlow: true,
                            onSessionCreated: { sessionId in
                                withAnimation(AppAnimation.standard) {
                                    phase = .active(sessionId)
                                }
                                HapticFeedback.selection()
                            }
                        )
                    case .active(let sessionId):
                        if let session = sessions.first(where: { $0.id == sessionId }) {
                            BAActiveSessionView(
                                sessionId: sessionId,
                                embeddedInFlow: true,
                                elapsed: effectiveElapsed(for: session),
                                requestCompleteFromPill: $requestActiveComplete,
                                onMovedToPost: {
                                    withAnimation(AppAnimation.standard) {
                                        phase = .post(sessionId)
                                    }
                                    HapticFeedback.selection()
                                }
                            )
                        } else {
                            ContentUnavailableView(
                                String(localized: "Session not found"),
                                systemImage: "questionmark.circle"
                            )
                        }
                    case .post(let sessionId):
                        PostSessionView(
                            sessionId: sessionId,
                            embeddedInFlow: true,
                            saveRequested: $requestPostSave,
                            showingSchedule: $showingSchedule,
                            onFinished: {
                                dismiss()
                            }
                        )
                    }
                }
                .frame(maxHeight: .infinity)

                bottomPill
                    .padding(.horizontal, Spacing.sm)
                    .padding(.bottom, Spacing.sm)
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if case .pre = phase {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        showingSchedule = true
                    } label: {
                        Image(systemName: "calendar")
                            .font(.system(size: IconSize.glyph, weight: .semibold))
                            .foregroundStyle(TextColors.primary)
                    }
                    .accessibilityLabel(String(localized: "Schedule for later"))

                    FlowToolbarCircleCloseButton {
                        dismiss()
                    }
                }
            } else if case .active(let sessionId) = phase {
                ToolbarItem(placement: .topBarTrailing) {
                    FlowToolbarCircleCloseButton {
                        discardActiveSessionAndDismiss(sessionId: sessionId)
                    }
                }
            } else if case .post(let sessionId) = phase {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        showingSchedule = true
                    } label: {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: IconSize.glyph, weight: .semibold))
                            .foregroundStyle(TextColors.primary)
                    }
                    .accessibilityLabel(String(localized: "Add to schedule"))

                    FlowToolbarCircleCloseButton {
                        abandonPostSessionAndDismiss(sessionId: sessionId)
                    }
                }
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .sheet(isPresented: $showingSchedule) {
            if let t = task {
                SchedulePickerSheet(task: t)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
        .onAppear {
            applyPendingResume()
        }
        .onDisappear {
            // Stop the 1s ticker so it can't keep firing after the flow is gone.
            activeTicker.upstream.connect().cancel()
        }
        .onReceive(activeTicker) { date in
            guard case .active = phase, !activeIsPaused else { return }
            activeNow = date
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active, !activeIsPaused, case .active = phase {
                activeNow = Date()
            }
        }
        .onChange(of: phase) { _, newPhase in
            if case .active = newPhase {
                activeNow = Date()
                activeIsPaused = false
                activePauseStart = nil
                activeTotalPaused = 0
            }
        }
    }

    // MARK: - Step Header

    private var stepHeader: some View {
        VStack(spacing: Spacing.xxs) {
            HStack {
                Text(String(format: String(localized: "Step %lld of 3"), Int64(stepIndex)))
                    .appFont(.smallMedium)
                    .foregroundStyle(TextColors.secondary)
                Spacer()
            }
            StepProgressBar(current: stepIndex, total: 3, color: AppColors.accent)
        }
    }

    // MARK: - Bottom Pill

    @ViewBuilder
    private var bottomPill: some View {
        switch phase {
        case .pre:
            SessionFlowBottomPill {
                Button { } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: IconSize.glyph, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.25))
                        .frame(maxWidth: .infinity)
                        .frame(height: TouchTarget.minimum)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(true)
                .accessibilityLabel(String(localized: "Previous step"))
            } center: {
                Color.clear
                    .accessibilityHidden(true)
            } right: {
                Button {
                    requestPreStart = true
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: IconSize.glyph, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: TouchTarget.minimum)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(String(localized: "Start activity"))
            }

        case .active(let sessionId):
            SessionFlowBottomPill {
                Button {
                    deleteSessionAndGoToPre(sessionId: sessionId)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: IconSize.glyph, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: TouchTarget.minimum)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(String(localized: "Previous step"))
            } center: {
                SessionPlayPauseCircleButton(isPlaying: !activeIsPaused, action: toggleActivePause)
                    .frame(maxWidth: .infinity)
                    .accessibilityHidden(true)
            } right: {
                Button {
                    requestActiveComplete = true
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: IconSize.glyph, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: TouchTarget.minimum)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(String(localized: "Complete activity"))
            }

        case .post:
            SessionFlowBottomPill {
                Button { } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: IconSize.glyph, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.25))
                        .frame(maxWidth: .infinity)
                        .frame(height: TouchTarget.minimum)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(true)
                .accessibilityLabel(String(localized: "Previous step"))
            } center: {
                Color.clear
                    .accessibilityHidden(true)
            } right: {
                Button {
                    requestPostSave = true
                } label: {
                    VStack(spacing: 2) {
                        Image(systemName: "flag.checkered")
                            .font(.system(size: 17, weight: .regular))
                            .foregroundStyle(.white)
                        Text(String(localized: "Save"))
                            .appFont(.smallMedium)
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: TouchTarget.minimum)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(String(localized: "Save session"))
            }
        }
    }

    // MARK: - Resume & Helpers

    private func applyPendingResume() {
        guard let resume = vm.consumePendingSessionFlowResume() else { return }
        switch resume {
        case .atActive(let sessionId):
            phase = .active(sessionId)
        case .atPost(let sessionId):
            phase = .post(sessionId)
        }
    }

    private func deleteSessionAndGoToPre(sessionId: UUID) {
        guard let s = sessions.first(where: { $0.id == sessionId }) else {
            phase = .pre
            return
        }
        modelContext.delete(s)
        try? modelContext.save()
        phase = .pre
        HapticFeedback.selection()
    }

    private func effectiveElapsed(for session: ActivationSession) -> TimeInterval {
        guard let startedAt = session.startedAt else { return 0 }
        let raw = (activeIsPaused ? (activePauseStart ?? activeNow) : activeNow).timeIntervalSince(startedAt)
        return max(0, raw - activeTotalPaused)
    }

    private func toggleActivePause() {
        if activeIsPaused {
            if let activePauseStart {
                activeTotalPaused += Date().timeIntervalSince(activePauseStart)
            }
            activePauseStart = nil
            activeIsPaused = false
        } else {
            activePauseStart = Date()
            activeIsPaused = true
        }
        HapticFeedback.selection()
    }

    private func discardActiveSessionAndDismiss(sessionId: UUID) {
        Task { await notificationManager.cancelActivationReminders(id: sessionId) }
        guard let s = sessions.first(where: { $0.id == sessionId }) else {
            dismiss()
            return
        }
        modelContext.delete(s)
        try? modelContext.save()
        HapticFeedback.selection()
        dismiss()
    }

    private func abandonPostSessionAndDismiss(sessionId: UUID) {
        Task { await notificationManager.cancelActivationReminders(id: sessionId) }
        guard let s = sessions.first(where: { $0.id == sessionId }) else {
            dismiss()
            return
        }
        s.status = .abandoned
        try? modelContext.save()
        HapticFeedback.selection()
        dismiss()
    }
}

// MARK: - Toolbar close (circular hit target, no fill)

private struct FlowToolbarCircleCloseButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(TextColors.primary)
                .frame(width: 36, height: 36)
        }
        .buttonStyle(.plain)
        .frame(minWidth: TouchTarget.minimum, minHeight: TouchTarget.minimum)
        .contentShape(Circle())
        .accessibilityLabel(String(localized: "Close"))
    }
}
