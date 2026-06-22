import SwiftUI
import SwiftData

// MARK: - CreateActivitySheet
// Sheet for creating a custom (non-preset) ActivationTask.

struct CreateActivitySheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \ActivationCategory.sortOrder) private var categories: [ActivationCategory]
    @Query private var tasks: [ActivationTask]

    @State private var title: String = ""
    @State private var hint: String = ""
    @State private var selectedCategoryId: UUID?
    @State private var pleasureTag: Bool = false
    @State private var masteryTag: Bool = false
    @State private var effortLevel: EffortLevel = .low
    @State private var suggestedMinutesText: String = ""

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && selectedCategoryId != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(String(localized: "e.g. Take a 10–15 minute walk"), text: $title)
                } header: {
                    Text(String(localized: "Activity name"))
                }

                Section {
                    ForEach(categories) { cat in
                        Button {
                            selectedCategoryId = cat.id
                        } label: {
                            HStack {
                                Image(systemName: cat.sfSymbol)
                                    .foregroundStyle(
                                        Color(hex: cat.colorHex) ?? AppColors.accent
                                    )
                                    .frame(width: 24)
                                Text(cat.localizedTitle)
                                    .foregroundStyle(TextColors.primary)
                                Spacer()
                                if selectedCategoryId == cat.id {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(AppColors.primary)
                                        .font(.system(size: 14, weight: .semibold))
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text(String(localized: "Category"))
                }

                Section {
                    TextField(String(localized: "Pace doesn't matter"), text: $hint)
                } header: {
                    Text(String(localized: "Hint (optional)"))
                }

                Section {
                    Picker(String(localized: "Effort"), selection: $effortLevel) {
                        ForEach(EffortLevel.allCases, id: \.self) { level in
                            Text(level.localizedName).tag(level)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text(String(localized: "Effort level"))
                }

                Section {
                    Toggle(String(localized: "P — pleasure"), isOn: $pleasureTag)
                    Toggle(String(localized: "M — mastery"), isOn: $masteryTag)
                } header: {
                    Text(String(localized: "Tags"))
                }

                Section {
                    TextField(String(localized: "Leave empty for flexible timing"), text: $suggestedMinutesText)
                        .keyboardType(.numberPad)
                } header: {
                    Text(String(localized: "Suggested duration (min)"))
                }
            }
            .navigationTitle(String(localized: "New activity"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "Save")) { save() }
                        .disabled(!canSave)
                }
            }
        }
    }

    private func save() {
        guard let catId = selectedCategoryId else { return }
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedHint = hint.trimmingCharacters(in: .whitespacesAndNewlines)

        let existingMax = tasks
            .filter { $0.categoryId == catId }
            .map { $0.sortOrder }
            .max() ?? -1

        let task = ActivationTask(
            categoryId: catId,
            title: trimmedTitle,
            hint: trimmedHint.isEmpty ? nil : trimmedHint,
            pleasureTag: pleasureTag,
            masteryTag: masteryTag,
            effortLevel: effortLevel,
            suggestedMinutes: Int(suggestedMinutesText),
            sfSymbol: "checkmark.circle",
            isPreset: false,
            isHiddenByUser: false,
            sortOrder: existingMax + 1
        )
        modelContext.insert(task)
        try? modelContext.save()
        dismiss()
    }
}
