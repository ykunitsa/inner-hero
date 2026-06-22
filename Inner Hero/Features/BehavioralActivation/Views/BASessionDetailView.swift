import SwiftUI
import SwiftData

// MARK: - BASessionDetailView
// Opened from a LogRow tap in the Journal tab. Shows full session details read-only.

struct BASessionDetailView: View {
    let sessionId: UUID

    @Environment(\.modelContext) private var modelContext

    @Query private var sessions: [ActivationSession]
    @Query private var tasks: [ActivationTask]
    @Query private var categories: [ActivationCategory]

    private var session: ActivationSession? { sessions.first { $0.id == sessionId } }
    private var task: ActivationTask? {
        guard let s = session else { return nil }
        return tasks.first { $0.id == s.activityId }
    }
    private var category: ActivationCategory? {
        guard let t = task else { return nil }
        return categories.first { $0.id == t.categoryId }
    }

    var body: some View {
        Group {
            if let s = session, let t = task {
                content(session: s, task: t)
            } else {
                ContentUnavailableView(String(localized: "Entry not found"), systemImage: "questionmark.circle")
            }
        }
        .toolbar(.hidden, for: .tabBar)
    }

    @ViewBuilder
    private func content(session: ActivationSession, task: ActivationTask) -> some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                ActivityPill(task: task, category: category)
                    .padding(.top, Spacing.xxs)

                DeltaCard(moodBefore: session.moodBefore, moodAfter: session.moodAfter)

                detailsSection(session: session)

                if let barrier = session.barrierNote {
                    noteSection(title: String(localized: "What got in the way?"), text: barrier)
                }

                if let reflection = session.reflectionNote {
                    noteSection(title: String(localized: "How did it go?"), text: reflection)
                }

                Spacer(minLength: 80)
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.top, Spacing.sm)
        }
        .homeBackground()
        .navigationTitle(task.localizedTitle)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            runAgainButton(task: task)
        }
    }

    // MARK: - Sections

    private func detailsSection(session: ActivationSession) -> some View {
        VStack(spacing: 0) {
            SectionLabel(text: String(localized: "Details"))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Spacing.sm)
                .padding(.bottom, Spacing.xxs)

            VStack(spacing: 0) {
                if let completedAt = session.completedAt {
                    detailRow(label: String(localized: "Date & time"), value: completedAt.formatted(.dateTime.day().month().year().hour().minute()))
                    Divider().padding(.leading, Spacing.sm)
                } else if let plannedFor = session.plannedFor {
                    detailRow(label: String(localized: "Scheduled for"), value: plannedFor.formatted(.dateTime.day().month().year().hour().minute()))
                    Divider().padding(.leading, Spacing.sm)
                }

                if let minutes = session.actualMinutes {
                    detailRow(label: String(localized: "Duration"), value: String(format: String(localized: "%lld min"), Int64(minutes)))
                    Divider().padding(.leading, Spacing.sm)
                }

                detailRow(label: String(localized: "Status"), value: session.status.localizedName)
            }
            .cardStyle(cornerRadius: CornerRadius.md, padding: 0)
        }
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .appFont(.body)
                .foregroundStyle(TextColors.secondary)
            Spacer()
            Text(value)
                .appFont(.bodyMedium)
                .foregroundStyle(TextColors.primary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.sm)
    }

    private func noteSection(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            SectionLabel(text: title)
            Text(text)
                .appFont(.body)
                .foregroundStyle(TextColors.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(Spacing.sm)
        .cardStyle(cornerRadius: CornerRadius.md, padding: 0)
    }

    // MARK: - Run Again

    private func runAgainButton(task: ActivationTask) -> some View {
        NavigationLink(value: BARoute.sessionFlow(taskId: task.id)) {
            PrimaryButtonLabel(title: String(localized: "Run again"))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, Spacing.sm)
        .padding(.bottom, Spacing.sm)
        .background(.regularMaterial)
    }
}

// MARK: - SessionStatus display

extension SessionStatus {
    var localizedName: String {
        switch self {
        case .planned:    return String(localized: "Scheduled")
        case .inProgress: return String(localized: "In progress")
        case .completed:  return String(localized: "Completed")
        case .abandoned:  return String(localized: "Incomplete")
        case .skipped:    return String(localized: "Skipped")
        }
    }
}
