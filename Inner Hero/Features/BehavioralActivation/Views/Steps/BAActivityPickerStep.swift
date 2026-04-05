import SwiftUI
import SwiftData

// MARK: - BAActivityPickerStep

struct BAActivityPickerStep: View {
    @Binding var selected: BAActivity?
    var onNext: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BAActivity.title) private var activities: [BAActivity]
    @Query(sort: \BASession.completedAt, order: .reverse) private var allSessions: [BASession]

    @State private var searchText = ""
    @State private var showingAddForm = false
    @State private var newTitle = ""
    @State private var newLifeValue: LifeValue = .connection

    // MARK: - Derived data

    private var recentActivities: [BAActivity] {
        var seen = Set<UUID>()
        var result: [BAActivity] = []
        for session in allSessions where session.completedAt != nil {
            guard let activity = session.activity,
                  !seen.contains(activity.id) else { continue }
            seen.insert(activity.id)
            result.append(activity)
            if result.count == 5 { break }
        }
        return result
    }

    private var groupedActivities: [(LifeValue, [BAActivity])] {
        let pool: [BAActivity]
        if searchText.isEmpty {
            let recentIDs = Set(recentActivities.map(\.id))
            pool = activities.filter { !recentIDs.contains($0.id) }
        } else {
            pool = activities.filter {
                $0.localizedTitle.localizedCaseInsensitiveContains(searchText)
            }
        }
        return LifeValue.allCases.compactMap { value in
            let matching = pool.filter { $0.lifeValue == value }
            return matching.isEmpty ? nil : (value, matching)
        }
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                searchField
                    .padding(.horizontal, Spacing.md)
                    .padding(.top, Spacing.sm)
                    .padding(.bottom, Spacing.xs)

                if searchText.isEmpty && !recentActivities.isEmpty {
                    sectionHeader(title: String(localized: "Recent"))

                    ForEach(recentActivities) { activity in
                        ActivityPickerRow(
                            activity: activity,
                            isSelected: selected?.id == activity.id,
                            onTap: { selectActivity(activity) }
                        )
                        .padding(.horizontal, Spacing.md)
                        .padding(.bottom, Spacing.xxxs)
                    }
                }

                ForEach(groupedActivities, id: \.0) { value, list in
                    sectionHeader(icon: value.systemIconName, title: value.localizedName)

                    ForEach(list) { activity in
                        ActivityPickerRow(
                            activity: activity,
                            isSelected: selected?.id == activity.id,
                            onTap: { selectActivity(activity) }
                        )
                        .padding(.horizontal, Spacing.md)
                        .padding(.bottom, Spacing.xxxs)
                    }
                }

                addOwnButton
                    .padding(.horizontal, Spacing.md)
                    .padding(.top, Spacing.xs)

                if showingAddForm {
                    addForm
                        .padding(.horizontal, Spacing.md)
                        .padding(.top, Spacing.xs)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                Spacer(minLength: Spacing.xxl)
            }
        }
        .animation(AppAnimation.spring, value: showingAddForm)
    }

    // MARK: - Search field

    private var searchField: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: IconSize.glyph))
                .foregroundStyle(TextColors.secondary)

            TextField(String(localized: "Search activities"), text: $searchText)
                .appFont(.body)

            if !searchText.isEmpty {
                Button { searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(TextColors.tertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Spacing.sm)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(AppColors.gray200, lineWidth: 1)
        )
    }

    // MARK: - Section header

    @ViewBuilder
    private func sectionHeader(icon: String? = nil, title: String) -> some View {
        HStack(spacing: Spacing.xxxs) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(TextColors.secondary)
            }
            Text(title)
                .appFont(.small)
                .foregroundStyle(TextColors.secondary)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.top, Spacing.sm)
        .padding(.bottom, Spacing.xxxs)
    }

    // MARK: - Add your own

    private var addOwnButton: some View {
        Button {
            withAnimation(AppAnimation.spring) {
                showingAddForm.toggle()
                if showingAddForm { newTitle = ""; newLifeValue = .connection }
            }
        } label: {
            HStack(spacing: Spacing.xxs) {
                Image(systemName: showingAddForm ? "minus.circle.fill" : "plus.circle.fill")
                    .font(.system(size: IconSize.glyph))
                    .foregroundStyle(AppColors.accent)
                Text(String(localized: "+ Add your own"))
                    .appFont(.bodyMedium)
                    .foregroundStyle(AppColors.accent)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Spacing.sm)
            .frame(height: TouchTarget.standard)
        }
        .buttonStyle(.plain)
    }

    private var addForm: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            TextField(String(localized: "Activity name"), text: $newTitle)
                .appFont(.body)
                .padding(Spacing.sm)
                .background(AppColors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .stroke(AppColors.gray200, lineWidth: 1)
                )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.xxs) {
                    ForEach(LifeValue.allCases) { value in
                        lifeValueChip(value)
                    }
                }
                .padding(.horizontal, Spacing.xxxs)
                .padding(.vertical, 2)
            }

            let trimmed = newTitle.trimmingCharacters(in: .whitespaces)
            Button(action: saveNewActivity) {
                Text(String(localized: "Save"))
                    .appFont(.buttonPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: TouchTarget.large)
                    .background(trimmed.isEmpty ? AppColors.gray300 : AppColors.accent)
                    .foregroundStyle(TextColors.onColor)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
            }
            .disabled(trimmed.isEmpty)
            .animation(AppAnimation.fast, value: trimmed.isEmpty)
        }
        .padding(Spacing.sm)
        .background(AppColors.accentLight.opacity(Opacity.softBackground))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(AppColors.accent.opacity(Opacity.subtleBorder), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func lifeValueChip(_ value: LifeValue) -> some View {
        let isSelected = newLifeValue == value
        Button {
            newLifeValue = value
            HapticFeedback.selection()
        } label: {
            HStack(spacing: Spacing.xxxs) {
                Image(systemName: value.systemIconName)
                    .font(.system(size: 12))
                Text(value.localizedName)
                    .appFont(.small)
            }
            .padding(.horizontal, Spacing.xs)
            .frame(height: 32)
            .background(isSelected ? AppColors.accent : AppColors.cardBackground)
            .foregroundStyle(isSelected ? TextColors.onColor : TextColors.secondary)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? AppColors.accent : AppColors.gray300, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .animation(AppAnimation.fast, value: isSelected)
    }

    // MARK: - Actions

    private func selectActivity(_ activity: BAActivity) {
        selected = activity
        HapticFeedback.selection()
        onNext()
    }

    private func saveNewActivity() {
        let trimmed = newTitle.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        let activity = BAActivity(title: trimmed, lifeValueRaw: newLifeValue.rawValue)
        modelContext.insert(activity)

        withAnimation(AppAnimation.spring) {
            showingAddForm = false
        }
        newTitle = ""

        selected = activity
        HapticFeedback.selection()
        onNext()
    }
}

// MARK: - ActivityPickerRow

struct ActivityPickerRow: View {
    let activity: BAActivity
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: activity.lifeValue.systemIconName)
                    .font(.system(size: IconSize.glyph))
                    .foregroundStyle(isSelected ? AppColors.positive : AppColors.gray400)
                    .frame(width: IconSize.inline, height: IconSize.inline)

                Text(activity.localizedTitle)
                    .appFont(.bodyMedium)
                    .foregroundStyle(TextColors.primary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppColors.positive)
                }
            }
            .padding(.horizontal, Spacing.sm)
            .frame(minHeight: TouchTarget.standard)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(isSelected ? AppColors.positiveLight : AppColors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(
                        isSelected ? AppColors.positive.opacity(Opacity.emphasizedBorder) : AppColors.gray200,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
        .animation(AppAnimation.fast, value: isSelected)
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var selected: BAActivity? = nil
    BAActivityPickerStep(selected: $selected, onNext: {})
        .modelContainer(for: [BASession.self, BAActivity.self], inMemory: true)
}
