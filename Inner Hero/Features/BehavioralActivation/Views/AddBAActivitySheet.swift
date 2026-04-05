import SwiftUI
import SwiftData

struct AddBAActivitySheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var selectedLifeValue: LifeValue = .connection

    @FocusState private var titleFocused: Bool

    private var trimmed: String { title.trimmingCharacters(in: .whitespaces) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    titleField
                    lifeValuePicker
                }
                .padding(Spacing.sm)
            }
            .homeBackground()
            .navigationTitle(String(localized: "New activity"))
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { titleFocused = true }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "Save")) { save() }
                        .disabled(trimmed.isEmpty)
                }
            }
        }
    }

    // MARK: - Title Field

    private var titleField: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text(String(localized: "Activity Name"))
                .appFont(.smallMedium)
                .foregroundStyle(TextColors.secondary)

            TextField(String(localized: "e.g. Morning walk"), text: $title)
                .appFont(.body)
                .focused($titleFocused)
                .padding(Spacing.sm)
                .background(AppColors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                        .strokeBorder(AppColors.gray200, lineWidth: 1)
                )
        }
    }

    // MARK: - Life Value Picker

    private var lifeValuePicker: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(String(localized: "Life Value"))
                .appFont(.smallMedium)
                .foregroundStyle(TextColors.secondary)

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: Spacing.xxs
            ) {
                ForEach(LifeValue.allCases) { value in
                    lifeValueChip(value)
                }
            }
        }
    }

    @ViewBuilder
    private func lifeValueChip(_ value: LifeValue) -> some View {
        let isSelected = selectedLifeValue == value
        Button {
            selectedLifeValue = value
            HapticFeedback.selection()
        } label: {
            HStack(spacing: Spacing.xxxs) {
                Image(systemName: value.systemIconName)
                    .font(.system(size: IconSize.glyph))
                Text(value.localizedName)
                    .appFont(.small)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.xs)
            .background(isSelected ? AppColors.positive : AppColors.cardBackground)
            .foregroundStyle(isSelected ? TextColors.onColor : TextColors.secondary)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                    .strokeBorder(
                        isSelected ? AppColors.positive : AppColors.gray200,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
        .animation(AppAnimation.fast, value: isSelected)
    }

    // MARK: - Actions

    private func save() {
        let activity = BAActivity(
            title: trimmed,
            lifeValueRaw: selectedLifeValue.rawValue,
            predefinedKey: nil,
            createdAt: Date()
        )
        modelContext.insert(activity)
        HapticFeedback.selection()
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    AddBAActivitySheet()
        .modelContainer(for: [BAActivity.self, BASession.self], inMemory: true)
}
