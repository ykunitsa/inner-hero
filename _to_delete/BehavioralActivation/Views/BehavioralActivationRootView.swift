import SwiftUI
import SwiftData

// MARK: - BehavioralActivationRootView
//
// This view is pushed onto the outer NavigationStack (e.g. ExercisesView).
// It must NOT create its own NavigationStack — nested stacks are unsupported.
//
// Navigation architecture:
//   • Session flow (PreSession → ActiveSession → PostSession) → `BASessionFlowView` via `BARoute.sessionFlow`
//   • Session detail (journal tap) → `BARoute.sessionDetail`

struct BehavioralActivationRootView: View {
    @State private var vm = BehavioralActivationViewModel()

    var body: some View {
        BehavioralActivationMainView(vm: vm)
            // `navigationDestination` content is not always a descendant of a later `.environment(vm)`;
            // pass the observable explicitly so pushed flows see `BehavioralActivationViewModel`.
            .navigationDestination(for: BARoute.self) { route in
                switch route {
                case .sessionDetail(let sessionId):
                    BASessionDetailView(sessionId: sessionId)
                        .environment(vm)
                case .sessionFlow(let taskId):
                    BASessionFlowView(taskId: taskId)
                        .environment(vm)
                }
            }
            .environment(vm)
    }
}

// MARK: - BehavioralActivationMainView

private struct BehavioralActivationMainView: View {
    let vm: BehavioralActivationViewModel

    @Environment(\.modelContext) private var modelContext
    @Environment(\.navigationRouter) private var navigationRouter
    @Environment(\.currentAppTab) private var currentAppTab

    @Query(sort: \ActivationTask.sortOrder) private var allTasks: [ActivationTask]
    @Query(sort: \ActivationCategory.sortOrder) private var categories: [ActivationCategory]
    @Query(sort: \ActivationSession.createdAt, order: .reverse) private var allSessions: [ActivationSession]

    var body: some View {
        Group {
            if vm.selectedTab == 0 {
                ActivitiesTabView(
                    vm: vm,
                    tasks: allTasks,
                    categories: categories,
                    sessions: allSessions
                )
                .transition(.opacity)
            } else {
                JournalTabView(
                    vm: vm,
                    tasks: allTasks,
                    categories: categories,
                    sessions: allSessions
                )
                .transition(.opacity)
            }
        }
        .animation(AppAnimation.standard, value: vm.selectedTab)
        .homeBackground()
        .navigationTitle(String(localized: "Behavioral activation"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    vm.showingCreateActivity = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: IconSize.glyph, weight: .semibold))
                }
                .accessibilityLabel(String(localized: "Add activity"))
            }
        }
        .onAppear {
            vm.checkInterruptedSession(allSessions, context: modelContext)
        }
        .sheet(isPresented: Binding(
            get: { vm.showingCreateActivity },
            set: { vm.showingCreateActivity = $0 }
        )) {
            CreateActivitySheet()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .confirmationDialog(
            String(localized: "You didn't finish your activity"),
            isPresented: Binding(
                get: { vm.showingCrashRecovery },
                set: { vm.showingCrashRecovery = $0 }
            ),
            titleVisibility: .visible
        ) {
            if let session = vm.interruptedSession {
                Button(String(localized: "Continue")) {
                    if let task = allTasks.first(where: { $0.id == session.activityId }) {
                        vm.pendingSessionFlowResume = .atActive(sessionId: session.id)
                        navigationRouter?.append(value: BARoute.sessionFlow(taskId: task.id), to: currentAppTab)
                    }
                    vm.interruptedSession = nil
                }
                Button(String(localized: "Finish")) {
                    if let task = allTasks.first(where: { $0.id == session.activityId }) {
                        vm.pendingSessionFlowResume = .atPost(sessionId: session.id)
                        navigationRouter?.append(value: BARoute.sessionFlow(taskId: task.id), to: currentAppTab)
                    }
                    vm.interruptedSession = nil
                }
                Button(String(localized: "Abandon"), role: .destructive) {
                    session.status = .abandoned
                    try? modelContext.save()
                    vm.interruptedSession = nil
                }
            }
        }
    }
}

// MARK: - ActivitiesTabView

private struct ActivitiesTabView: View {
    @Bindable var vm: BehavioralActivationViewModel
    let tasks: [ActivationTask]
    let categories: [ActivationCategory]
    let sessions: [ActivationSession]

    @Environment(\.navigationRouter) private var navigationRouter
    @Environment(\.currentAppTab) private var currentAppTab

    private enum RoulettePhase: Equatable {
        case idle
        case spinning
        case revealing
    }

    @State private var roulettePhase: RoulettePhase = .idle
    @State private var spinDisplayName = ""
    /// Pop-in scale for the reveal phase (1 = rest).
    @State private var revealScale: CGFloat = 1
    /// Drives the slot-machine animation; cancelled when the tab disappears so it can't
    /// mutate state or navigate after the view is gone.
    @State private var rouletteTask: Task<Void, Never>?

    private var filtered: [ActivationTask] { vm.filteredTasks(tasks) }

    private var plannedToday: [(session: ActivationSession, task: ActivationTask)] {
        sessions
            .filter { s in
                s.status == .planned &&
                (s.plannedFor.map { Calendar.current.isDateInToday($0) } ?? false)
            }
            .compactMap { s in
                tasks.first { $0.id == s.activityId }.map { (session: s, task: $0) }
            }
    }

    private func category(for task: ActivationTask) -> ActivationCategory? {
        categories.first { $0.id == task.categoryId }
    }

    private var groupedByCategory: [(category: ActivationCategory, tasks: [ActivationTask])] {
        categories.compactMap { cat in
            let inCat = filtered.filter { $0.categoryId == cat.id }
            return inCat.isEmpty ? nil : (category: cat, tasks: inCat)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xxs) {
                searchFilterBar
                    .padding(.horizontal, Spacing.sm)

                if filtered.isEmpty && (vm.hasActiveFilters || !vm.searchText.isEmpty) {
                    emptyState
                } else {
                    taskListContent
                }
            }
            .padding(.top, Spacing.sm)
            .padding(.bottom, Spacing.xxl)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            TopTabBar(
                tabs: [
                    String(localized: "Activities"),
                    String(localized: "Journal"),
                ],
                selection: $vm.selectedTab
            )
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
        }
        .overlay(alignment: .bottom) {
            if vm.showingRandomEmptyToast {
                randomEmptyToast
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + InteractionTiming.toastAutoDismiss) {
                            withAnimation(AppAnimation.standard) {
                                vm.showingRandomEmptyToast = false
                            }
                        }
                    }
            }
        }
        .animation(AppAnimation.standard, value: vm.showingRandomEmptyToast)
        .onDisappear { rouletteTask?.cancel() }
    }

    // MARK: - Search / Filter bar

    /// Selection count for the type filter pill (0 = default “all”, 1 = any other mode).
    private var typeFilterSelectionCount: Int {
        (!vm.filterPleasure && !vm.filterMastery) ? 0 : 1
    }

    private var searchFilterBar: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.xxs) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(TextColors.tertiary)
                    .font(.system(size: IconSize.fieldGlyph, weight: .regular))

                TextField(String(localized: "Search activities…"), text: Binding(
                    get: { vm.searchText },
                    set: { vm.searchText = $0 }
                ))
                .appFont(.body)

                if !vm.searchText.isEmpty {
                    Button {
                        vm.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(AppColors.gray400)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(String(localized: "Clear search"))
                }
            }
            .padding(.horizontal, Spacing.sm)
            .frame(minHeight: TouchTarget.minimum)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous)
                    .fill(AppColors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous)
                    .strokeBorder(AppColors.gray200, lineWidth: BorderWidth.hairline)
            )

            HStack(spacing: Spacing.xxs) {
                categoryFilterMenu
                typeFilterMenu
                effortFilterMenu
            }
        }
    }

    private var categoryFilterMenu: some View {
        Menu {
            Button {
                vm.filterCategoryIds = []
            } label: {
                filterMenuRow(
                    String(localized: "All"),
                    isOn: vm.filterCategoryIds.isEmpty
                )
            }
            Divider()
            ForEach(categories) { cat in
                Button {
                    toggleFilterCategory(cat.id)
                } label: {
                    filterMenuRow(
                        cat.localizedTitle,
                        isOn: vm.filterCategoryIds.contains(cat.id)
                    )
                }
            }
        } label: {
            FilterPillMenuLabel(
                title: String(localized: "Category"),
                selectedCount: vm.filterCategoryIds.count
            )
        }
        .buttonStyle(.plain)
    }

    private var typeFilterMenu: some View {
        Menu {
            Button {
                vm.filterPleasure = false
                vm.filterMastery = false
            } label: {
                filterMenuRow(String(localized: "All"), isOn: !vm.filterPleasure && !vm.filterMastery)
            }
            Button {
                vm.filterPleasure = true
                vm.filterMastery = false
            } label: {
                filterMenuRow(String(localized: "Pleasure"), isOn: vm.filterPleasure && !vm.filterMastery)
            }
            Button {
                vm.filterPleasure = false
                vm.filterMastery = true
            } label: {
                filterMenuRow(String(localized: "Mastery"), isOn: !vm.filterPleasure && vm.filterMastery)
            }
            Button {
                vm.filterPleasure = true
                vm.filterMastery = true
            } label: {
                filterMenuRow(String(localized: "P & M"), isOn: vm.filterPleasure && vm.filterMastery)
            }
        } label: {
            FilterPillMenuLabel(
                title: String(localized: "Type"),
                selectedCount: typeFilterSelectionCount
            )
        }
        .buttonStyle(.plain)
    }

    private var effortFilterMenu: some View {
        Menu {
            Button {
                vm.filterEffortLevels = []
            } label: {
                filterMenuRow(String(localized: "All"), isOn: vm.filterEffortLevels.isEmpty)
            }
            Divider()
            ForEach(EffortLevel.allCases, id: \.self) { level in
                Button {
                    toggleFilterEffort(level)
                } label: {
                    filterMenuRow(level.localizedName, isOn: vm.filterEffortLevels.contains(level))
                }
            }
        } label: {
            FilterPillMenuLabel(
                title: String(localized: "Effort"),
                selectedCount: vm.filterEffortLevels.count
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func filterMenuRow(_ title: String, isOn: Bool) -> some View {
        HStack {
            Text(title)
                .appFont(isOn ? .bodyMedium : .body)
            Spacer(minLength: Spacing.xxs)
            if isOn {
                Image(systemName: "checkmark")
                    .font(.system(size: IconSize.glyph, weight: .semibold))
            }
        }
    }

    private func toggleFilterCategory(_ id: UUID) {
        if vm.filterCategoryIds.contains(id) {
            vm.filterCategoryIds.remove(id)
        } else {
            vm.filterCategoryIds.insert(id)
        }
    }

    private func toggleFilterEffort(_ level: EffortLevel) {
        if vm.filterEffortLevels.contains(level) {
            vm.filterEffortLevels.remove(level)
        } else {
            vm.filterEffortLevels.insert(level)
        }
    }

    // MARK: - Task List

    private var taskListContent: some View {
        LazyVStack(alignment: .leading, spacing: 0) {
            randomCard
                .padding(.horizontal, Spacing.sm)
                .padding(.top, Spacing.xxs)
                .padding(.bottom, Spacing.xs)

            if !plannedToday.isEmpty {
                SectionLabel(text: String(localized: "Scheduled"))
                    .padding(.horizontal, Spacing.sm)
                    .padding(.bottom, Spacing.xxs)

                VStack(spacing: Spacing.xxs) {
                    ForEach(plannedToday, id: \.session.id) { pair in
                        NavigationLink(value: BARoute.sessionFlow(taskId: pair.task.id)) {
                            ActivityRow(
                                task: pair.task,
                                category: category(for: pair.task),
                                plannedTime: pair.session.plannedFor
                            )
                        }
                        .buttonStyle(.plain)
                        .cardStyle(cornerRadius: CornerRadius.lg, padding: 0)
                    }
                }
                .padding(.horizontal, Spacing.sm)
                .padding(.bottom, Spacing.sm)
            }

            ForEach(groupedByCategory, id: \.category.id) { group in
                SectionLabel(text: group.category.localizedTitle)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.bottom, Spacing.xxs)

                VStack(spacing: Spacing.xxs) {
                    ForEach(group.tasks) { task in
                        NavigationLink(value: BARoute.sessionFlow(taskId: task.id)) {
                            ActivityRow(task: task, category: group.category)
                        }
                        .buttonStyle(.plain)
                        .cardStyle(cornerRadius: CornerRadius.lg, padding: 0)
                    }
                }
                .padding(.horizontal, Spacing.sm)
                .padding(.bottom, Spacing.sm)
            }
        }
    }

    private var randomCard: some View {
        Button {
            guard roulettePhase == .idle else { return }
            let result = vm.smartRandom(from: tasks, recentSessions: sessions)
            guard let task = result.task else {
                withAnimation(AppAnimation.standard) { vm.showingRandomEmptyToast = true }
                return
            }
            if result.ignoredFilters {
                withAnimation(AppAnimation.standard) { vm.showingRandomEmptyToast = true }
            }
            startRoulette(selectedTask: task)
        } label: {
            Group {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: randomRouletteIconName)
                        .font(.system(size: IconSize.glyph, weight: .medium))
                        .foregroundStyle(TextColors.onColor)
                        .iconContainer(
                            size: IconSize.card,
                            backgroundColor: Color.white.opacity(Opacity.mediumBackground),
                            cornerRadius: CornerRadius.sm
                        )
                        .contentTransition(.symbolEffect(.replace))

                    VStack(alignment: .leading, spacing: Spacing.tight) {
                        ZStack(alignment: .leading) {
                            if roulettePhase == .idle {
                                Text(String(localized: "Random activity"))
                                    .appFont(.h3)
                                    .foregroundStyle(TextColors.onColor)
                                    .transition(.opacity)
                            } else if roulettePhase == .spinning {
                                Text(spinDisplayName)
                                    .appFont(.h3)
                                    .foregroundStyle(TextColors.onColor)
                                    .lineLimit(1)
                                    .id(spinDisplayName)
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .top).combined(with: .opacity),
                                        removal: .move(edge: .bottom).combined(with: .opacity)
                                    ))
                            } else {
                                Text(spinDisplayName)
                                    .appFont(.h3)
                                    .foregroundStyle(TextColors.onColor)
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.88)
                                    .scaleEffect(revealScale)
                                    .shadow(
                                        color: Color.white.opacity(0.35),
                                        radius: 8
                                    )
                            }
                        }
                        .clipped()
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Text(randomRouletteSubtitle)
                            .appFont(.small)
                            .foregroundStyle(TextColors.onColorSecondary)
                            .animation(AppAnimation.standard, value: roulettePhase)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .heroCardStyle(color: AppColors.black, padding: Spacing.sm)
        }
        .buttonStyle(.plain)
        // Avoid `.disabled` here — it grays out the label; we only need to ignore taps while spinning/revealing.
        .allowsHitTesting(roulettePhase == .idle)
        .animation(AppAnimation.standard, value: roulettePhase)
        .accessibilityLabel(String(localized: "Random activity"))
    }

    private var randomRouletteIconName: String {
        switch roulettePhase {
        case .idle: return "shuffle"
        case .spinning: return "dice.fill"
        case .revealing: return "checkmark.circle.fill"
        }
    }

    private var randomRouletteSubtitle: String {
        switch roulettePhase {
        case .idle:
            return String(localized: "We'll pick one that fits")
        case .spinning:
            return String(localized: "Finding an activity…")
        case .revealing:
            return String(localized: "Here's your pick")
        }
    }

    private func startRoulette(selectedTask: ActivationTask) {
        let allNames = tasks.map { $0.localizedTitle }
        guard !allNames.isEmpty else {
            navigationRouter?.append(value: BARoute.sessionFlow(taskId: selectedTask.id), to: currentAppTab)
            return
        }

        HapticFeedback.selection()
        revealScale = 1
        withAnimation(AppAnimation.fast) { roulettePhase = .spinning }
        spinDisplayName = allNames.randomElement() ?? selectedTask.localizedTitle

        // 9 dummy frames + 1 landing frame; delays slow down over time (slot-machine deceleration)
        var names: [String] = (0..<9).map { _ in allNames.randomElement() ?? selectedTask.localizedTitle }
        names.append(selectedTask.localizedTitle)
        let delays: [TimeInterval] = [
            InteractionTiming.rouletteFrame, 0.08, 0.09, 0.10, 0.13, 0.17, 0.23, 0.32, 0.44, 0.55,
        ]

        rouletteTask?.cancel()
        rouletteTask = Task { @MainActor in
            for (i, name) in names.enumerated() {
                let delay = i < delays.count ? delays[i] : (delays.last ?? InteractionTiming.rouletteFrame)
                try? await Task.sleep(for: .seconds(delay))
                if Task.isCancelled { return }
                withAnimation(AppAnimation.tick) {
                    spinDisplayName = name
                }
                HapticFeedback.selection()
            }
            HapticFeedback.impact(.medium)
            try? await Task.sleep(for: .seconds(InteractionTiming.rouletteSettle))
            if Task.isCancelled { return }

            revealScale = 0.88
            withAnimation(AppAnimation.standard) {
                roulettePhase = .revealing
            }
            withAnimation(.spring(response: 0.52, dampingFraction: 0.68)) {
                revealScale = 1.0
            }
            HapticFeedback.selection()

            try? await Task.sleep(for: .seconds(InteractionTiming.rouletteReveal))
            if Task.isCancelled { return }

            roulettePhase = .idle
            navigationRouter?.append(value: BARoute.sessionFlow(taskId: selectedTask.id), to: currentAppTab)
        }
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: IconSize.emptyState, weight: .regular))
                .foregroundStyle(AppColors.gray300)
            Text(String(localized: "Nothing found"))
                .appFont(.h3)
                .foregroundStyle(TextColors.secondary)
            Button(String(localized: "Reset filters")) {
                vm.resetFilters()
            }
            .appFont(.bodyMedium)
            .foregroundStyle(AppColors.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.emptyStateVertical)
    }

    private var randomEmptyToast: some View {
        HStack(spacing: Spacing.xxs) {
            Text(String(localized: "No activities match. Clear filters and try again?"))
                .appFont(.small)
                .foregroundStyle(TextColors.onColor)
            Spacer()
            Button(String(localized: "Yes")) {
                vm.resetFilters()
                vm.showingRandomEmptyToast = false
                if let task = vm.smartRandom(from: tasks, recentSessions: sessions).task {
                    navigationRouter?.append(value: BARoute.sessionFlow(taskId: task.id), to: currentAppTab)
                }
            }
            .appFont(.smallMedium)
            .foregroundStyle(AppColors.primaryLight)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.sm)
        .background(Capsule().fill(AppColors.black))
        .padding(.horizontal, Spacing.sm)
        .padding(.bottom, Spacing.sm)
    }
}

// MARK: - JournalTabView

private struct JournalTabView: View {
    @Bindable var vm: BehavioralActivationViewModel
    let tasks: [ActivationTask]
    let categories: [ActivationCategory]
    let sessions: [ActivationSession]

    private var analytics: BehavioralActivationViewModel.JournalAnalytics {
        vm.analytics(from: sessions)
    }

    private var planned: [ActivationSession] {
        sessions.filter { $0.status == .planned }
            .sorted { ($0.plannedFor ?? .distantPast) < ($1.plannedFor ?? .distantPast) }
    }

    private var completedToday: [ActivationSession] {
        sessions.filter { s in
            (s.status == .completed || s.status == .abandoned) &&
            (s.completedAt.map { Calendar.current.isDateInToday($0) } ?? false)
        }
    }

    private var completedYesterday: [ActivationSession] {
        sessions.filter { s in
            (s.status == .completed || s.status == .abandoned) &&
            (s.completedAt.map { Calendar.current.isDateInYesterday($0) } ?? false)
        }
    }

    private var completedEarlier: [ActivationSession] {
        sessions.filter { s in
            guard s.status == .completed || s.status == .abandoned else { return false }
            guard let completedAt = s.completedAt else { return false }
            return !Calendar.current.isDateInToday(completedAt) && !Calendar.current.isDateInYesterday(completedAt)
        }
    }

    private func task(for session: ActivationSession) -> ActivationTask? {
        tasks.first { $0.id == session.activityId }
    }
    private func category(for session: ActivationSession) -> ActivationCategory? {
        guard let t = task(for: session) else { return nil }
        return categories.first { $0.id == t.categoryId }
    }

    private var journalIsEmpty: Bool {
        sessions.filter { $0.status == .completed || $0.status == .abandoned }.isEmpty && planned.isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                journalStatsRow
                    .padding(.horizontal, Spacing.sm)
                    .padding(.top, Spacing.sm)
                    .padding(.bottom, Spacing.xs)

                if journalIsEmpty {
                    emptyJournalState
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.emptyStateVertical)
                } else {
                    journalSectionsContent
                }
            }
            .padding(.bottom, Spacing.xxl)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            TopTabBar(
                tabs: [
                    String(localized: "Activities"),
                    String(localized: "Journal"),
                ],
                selection: $vm.selectedTab
            )
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
        }
    }

    // MARK: - Stats (red hero card — same language as `HomeView.heroCard`)

    private var journalStatsRow: some View {
        HStack(spacing: 0) {
            journalHeroStatItem(
                icon: "checkmark.circle.fill",
                value: "\(analytics.totalCompleted)",
                label: String(localized: "Completed"),
                iconTint: Color.white.opacity(0.92),
                valueTint: TextColors.onColor
            )
            journalHeroDivider
            journalHeroStatItem(
                icon: "arrow.up.arrow.down.circle.fill",
                value: journalDeltaValueText,
                label: String(localized: "Avg. delta"),
                iconTint: Color.white.opacity(0.92),
                valueTint: TextColors.onColor
            )
            journalHeroDivider
            journalHeroStatItem(
                icon: "face.smiling.inverse",
                value: journalBeforeAfterValueText,
                label: String(localized: "Before → after"),
                iconTint: Color.white.opacity(0.92),
                valueTint: TextColors.onColor
            )
        }
        .padding(.vertical, Spacing.xxs)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.xl, style: .continuous)
                .fill(AppColors.primary)
        )
        .accessibilityElement(children: .contain)
    }

    private var journalHeroDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.22))
            .frame(width: BorderWidth.hairline, height: 40)
    }

    private var journalDeltaValueText: String {
        guard let delta = analytics.averageDelta else { return "—" }
        let prefix = delta >= 0 ? "+" : ""
        return String(format: "\(prefix)%.1f", delta)
    }

    private var journalBeforeAfterValueText: String {
        guard let before = analytics.averageMoodBefore, let after = analytics.averageMoodAfter else {
            return "—"
        }
        return "\(Int(before.rounded()))→\(Int(after.rounded()))"
    }

    private func journalHeroStatItem(icon: String, value: String, label: String, iconTint: Color, valueTint: Color) -> some View {
        VStack(spacing: Spacing.xxxs) {
            HStack(spacing: Spacing.xxxs) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(iconTint)
                Text(value)
                    .appFont(.h2)
                    .foregroundStyle(valueTint)
                    .monospacedDigit()
                    .minimumScaleFactor(ContentScaling.statMinimum)
                    .lineLimit(1)
            }
            Text(label)
                .appFont(.small)
                .foregroundStyle(TextColors.onColorSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.sm)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(value) \(label)")
    }

    // MARK: - Sections (card stack like Activities tab)

    @ViewBuilder
    private var journalSectionsContent: some View {
        if !planned.isEmpty {
            SectionLabel(text: String(localized: "Scheduled"))
                .padding(.horizontal, Spacing.sm)
                .padding(.bottom, Spacing.xxs)

            VStack(spacing: Spacing.xxs) {
                ForEach(planned) { session in
                    scheduledSessionCard(session: session)
                }
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.bottom, Spacing.sm)
        }

        if !completedToday.isEmpty {
            SectionLabel(text: String(localized: "Today"))
                .padding(.horizontal, Spacing.sm)
                .padding(.bottom, Spacing.xxs)

            VStack(spacing: Spacing.xxs) {
                ForEach(completedToday) { session in
                    logRowCard(session: session)
                }
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.bottom, Spacing.sm)
        }

        if !completedYesterday.isEmpty {
            SectionLabel(text: String(localized: "Yesterday"))
                .padding(.horizontal, Spacing.sm)
                .padding(.bottom, Spacing.xxs)

            VStack(spacing: Spacing.xxs) {
                ForEach(completedYesterday) { session in
                    logRowCard(session: session)
                }
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.bottom, Spacing.sm)
        }

        if !completedEarlier.isEmpty {
            SectionLabel(text: String(localized: "Earlier"))
                .padding(.horizontal, Spacing.sm)
                .padding(.bottom, Spacing.xxs)

            VStack(spacing: Spacing.xxs) {
                ForEach(completedEarlier) { session in
                    logRowCard(session: session)
                }
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.bottom, Spacing.sm)
        }
    }

    @ViewBuilder
    private func scheduledSessionCard(session: ActivationSession) -> some View {
        if let t = task(for: session) {
            NavigationLink(value: BARoute.sessionFlow(taskId: t.id)) {
                HStack(alignment: .center, spacing: Spacing.sm) {
                    ActivityRow(
                        task: t,
                        category: category(for: session),
                        plannedTime: session.plannedFor
                    )

                    Image(systemName: "play.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: TouchTarget.minimum, height: TouchTarget.minimum)
                        .background(Circle().fill(AppColors.black))
                        .padding(.trailing, Spacing.sm)
                }
                .accessibilityLabel(String(localized: "Start"))
            }
            .buttonStyle(.plain)
            .cardStyle(cornerRadius: CornerRadius.lg, padding: 0)
        } else {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "calendar")
                    .font(.system(size: IconSize.glyph, weight: .medium))
                    .foregroundStyle(AppColors.gray400)
                    .iconContainer(
                        size: IconSize.card,
                        backgroundColor: AppColors.gray200,
                        cornerRadius: CornerRadius.sm
                    )
                VStack(alignment: .leading, spacing: Spacing.xxxs) {
                    Text("—")
                        .appFont(.h3)
                        .foregroundStyle(TextColors.primary)
                    if let plannedFor = session.plannedFor {
                        Text(plannedFor.formatted(.dateTime.weekday(.abbreviated).day().hour().minute()))
                            .appFont(.small)
                            .foregroundStyle(TextColors.secondary)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(.vertical, Spacing.xs)
            .padding(.horizontal, Spacing.sm)
            .cardStyle(cornerRadius: CornerRadius.lg, padding: 0)
        }
    }

    private func logRowCard(session: ActivationSession) -> some View {
        NavigationLink(value: BARoute.sessionDetail(sessionId: session.id)) {
            LogRow(session: session, task: task(for: session), category: category(for: session))
        }
        .buttonStyle(.plain)
        .cardStyle(cornerRadius: CornerRadius.lg, padding: 0)
    }

    private var emptyJournalState: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "book.closed")
                .font(.system(size: IconSize.emptyState, weight: .regular))
                .foregroundStyle(AppColors.gray300)
            Text(String(localized: "Journal is empty"))
                .appFont(.h3)
                .foregroundStyle(TextColors.secondary)
            Text(String(localized: "Complete an activity and it will show up here."))
                .appFont(.body)
                .foregroundStyle(TextColors.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.lg)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        BehavioralActivationRootView()
    }
    .modelContainer(for: [ActivationCategory.self, ActivationTask.self, ActivationSession.self, ExerciseAssignment.self])
}
