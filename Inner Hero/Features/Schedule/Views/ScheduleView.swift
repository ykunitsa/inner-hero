import SwiftData
import SwiftUI
import UserNotifications

/// The schedule tab (spec §2.1, §1.10): everything the user has put on their own
/// schedule, and the only place it is edited.
///
/// The division of labour with Today is deliberate — Today answers *what is on
/// today* and leads into the exercise, this screen answers *what is set up at all*
/// and leads into the editor. Neither shows the other's answer.
struct ScheduleView: View {
    @Binding var path: NavigationPath

    @Environment(\.modelContext) private var modelContext
    @Environment(NotificationManager.self) private var notificationManager

    @Query private var items: [ScheduleItem]

    @State private var viewModel = ScheduleViewModel()
    @State private var showEditor = false
    @State private var showSaveError = false
    @State private var authorizationStatus: UNAuthorizationStatus?

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if items.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
            .homeBackground()
            .navigationTitle(String(localized: "Schedule"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.beginAdd()
                        showEditor = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel(String(localized: "Add to schedule"))
                }
            }
            .navigationDestination(for: AppRoute.self) { route in
                AppRouteView(route: route)
            }
            // Editing commits on the way out, by either exit — this is a setting,
            // not a session, and there is nothing here to lose (codex §4). A *new*
            // entry is the exception: swiping the sheet away before "Done" creates
            // nothing, because nothing existed yet to preserve.
            .sheet(isPresented: $showEditor, onDismiss: editorDismissed) {
                ScheduleItemEditor(viewModel: viewModel)
            }
            .alert(
                String(localized: "Couldn't save"),
                isPresented: $showSaveError
            ) {
                Button(String(localized: "OK"), role: .cancel) {}
            } message: {
                Text(String(localized: "Try again in a moment."))
            }
            .task {
                removeSpent()
                try? viewModel.healDuplicateTokens(items, in: modelContext)
                await refreshAuthorizationStatus()
                await ScheduleReminderService.sync(currentItems(), via: notificationManager)
            }
        }
    }

    // MARK: - List

    private var list: some View {
        List {
            ForEach(viewModel.sections(items), id: \.section) { group in
                Section {
                    ForEach(group.items) { item in
                        row(item)
                    }
                    .onDelete { offsets in
                        delete(offsets.map { group.items[$0] })
                    }
                    .listRowBackground(AppColors.cardBackground)
                } header: {
                    SectionLabel(text: group.section.title)
                }
            }

            if isDenied {
                Section {
                    deniedNotice
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    private var isDenied: Bool { authorizationStatus == .denied }

    /// The honest state of a promise the app cannot keep on its own — one line and
    /// a way to fix it. Not a banner, not a second permission prompt: the day list
    /// and this screen work fully without notifications (plan decision 8).
    private var deniedNotice: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text(String(localized: "Reminders are off in iOS Settings"))
                .appFont(.small)
                .foregroundStyle(TextColors.secondary)
                .fixedSize(horizontal: false, vertical: true)

            // The literal, not `UIApplication.openSettingsURLString`: importing
            // UIKit for one constant would be a third exception to the no-UIKit
            // rule (CLAUDE.md), and the constant's value is exactly this.
            if let url = URL(string: "app-settings:") {
                Link(destination: url) {
                    Text(String(localized: "Open Settings"))
                        .appFont(.small)
                        .foregroundStyle(AppColors.accent)
                        .frame(minHeight: TouchTarget.minimum, alignment: .leading)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func row(_ item: ScheduleItem) -> some View {
        HStack(spacing: Spacing.xs) {
            Button {
                viewModel.beginEdit(item)
                showEditor = true
            } label: {
                HStack(spacing: Spacing.xs) {
                    if let exercise = item.exercise {
                        Image(systemName: exercise.icon)
                            .font(.system(size: IconSize.glyph, weight: .medium))
                            .foregroundStyle(AppColors.primary)
                            .iconContainer(
                                size: IconSize.card,
                                backgroundColor: AppColors.primary.opacity(Opacity.subtleBackground),
                                cornerRadius: CornerRadius.sm
                            )
                            .accessibilityHidden(true)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.exercise?.title ?? "")
                            .appFont(.bodyMedium)
                            .foregroundStyle(TextColors.primary)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(viewModel.meta(for: item))
                            .appFont(.small)
                            // A disabled entry keeps its time on screen, only
                            // quieter — the switch means "not this week", not
                            // "forget when".
                            .foregroundStyle(item.isEnabled ? TextColors.secondary : TextColors.tertiary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(item.exercise?.title ?? ""), \(viewModel.meta(for: item))")
            .accessibilityHint(String(localized: "Opens the editor"))

            Toggle("", isOn: enabledBinding(for: item))
                .labelsHidden()
                .accessibilityLabel(String(localized: "Reminder"))
        }
    }

    /// Quiet, and with a way forward — not a poster explaining why schedules are
    /// good (§1.3). Reachable on a fresh install and by deleting everything, and
    /// both are fine states to be in.
    private var emptyState: some View {
        VStack(spacing: Spacing.xs) {
            Text(String(localized: "What you set for yourself will show up here."))
                .appFont(.body)
                .foregroundStyle(TextColors.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                viewModel.beginAdd()
                showEditor = true
            } label: {
                Text(String(localized: "Add to schedule"))
                    .appFont(.body)
                    .foregroundStyle(AppColors.accent)
                    .frame(minHeight: TouchTarget.minimum)
            }
            .buttonStyle(.plain)

            if isDenied {
                deniedNotice
                    .padding(.top, Spacing.md)
            }
        }
        .padding(.horizontal, Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Actions

    private func enabledBinding(for item: ScheduleItem) -> Binding<Bool> {
        Binding(
            get: { item.isEnabled },
            set: { newValue in
                do {
                    try viewModel.setEnabled(newValue, for: item, in: modelContext)
                    // Switching one on is as much a first reminder as saving one.
                    resync(askingPermission: newValue)
                } catch {
                    HapticFeedback.error()
                    showSaveError = true
                }
            }
        )
    }

    /// The editor saved on its own if "Done" was pressed; this covers the swipe-away
    /// path, which commits an **edit** and creates nothing new (see the editor).
    /// Either way the queue has to catch up.
    private func editorDismissed() {
        if viewModel.isEditing {
            do {
                try viewModel.save(in: modelContext)
            } catch {
                HapticFeedback.error()
                showSaveError = true
            }
        }
        resync(askingPermission: true)
    }

    private func delete(_ items: [ScheduleItem]) {
        do {
            for item in items {
                try viewModel.delete(item, in: modelContext)
            }
            resync()
        } catch {
            HapticFeedback.error()
            showSaveError = true
        }
    }

    /// One-off entries whose day has passed leave silently (plan decision 6).
    private func removeSpent() {
        try? viewModel.removeSpent(items, in: modelContext)
    }

    // MARK: - Reminders

    /// Clears the schedule's reminders and lays them out again from what is now in
    /// the store — read fresh rather than from `items`, which is the snapshot this
    /// view rendered with and does not yet include the change that triggered this.
    ///
    /// Permission is asked here and nowhere else: the moment someone has just set
    /// something up is the only moment the question makes sense. Already-decided
    /// permissions resolve without showing anything.
    private func resync(askingPermission: Bool = false) {
        Task {
            if askingPermission,
               await notificationManager.checkAuthorizationStatus() == .notDetermined {
                _ = await notificationManager.requestAuthorization()
            }
            await ScheduleReminderService.sync(currentItems(), via: notificationManager)
            await refreshAuthorizationStatus()
        }
    }

    private func currentItems() -> [ScheduleItem] {
        (try? modelContext.fetch(FetchDescriptor<ScheduleItem>())) ?? []
    }

    private func refreshAuthorizationStatus() async {
        authorizationStatus = await notificationManager.checkAuthorizationStatus()
    }
}

#Preview {
    ScheduleView(path: .constant(NavigationPath()))
        .environment(ArticlesStore())
        .environment(NotificationManager())
        .modelContainer(for: [ScheduleItem.self], inMemory: true)
}
