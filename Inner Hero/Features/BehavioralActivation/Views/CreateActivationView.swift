import SwiftUI
import SwiftData

struct CreateActivationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String = ""
    @State private var activities: [ActivityEditItem] = [
        ActivityEditItem(text: "")
    ]
    @State private var showingError = false
    @State private var errorMessage = ""
    
    @FocusState private var focusedField: ActivationFormField?
    
    private var canSave: Bool {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedTitle.isEmpty && activities.contains(where: { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
    }
    
    var body: some View {
        NavigationStack {
            Form {
                basicInfoSection
                activitiesSection
            }
            .navigationTitle("Новый список активностей")
            .navigationBarTitleDisplayMode(.inline)
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
                    }
                    .foregroundStyle(TextColors.toolbar)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        saveActivation()
                    }
                    .disabled(!canSave)
                    .opacity(canSave ? 1.0 : 0.5)
                }
                
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Готово") {
                        focusedField = nil
                    }
                    .font(.headline)
                }
            }
            .alert("Ошибка", isPresented: $showingError) {
                Button("ОК", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
        .onAppear {
            focusedField = .title
        }
    }
    
    private var basicInfoSection: some View {
        Section {
            TextField("Название списка", text: $title)
                .font(.body)
                .focused($focusedField, equals: .title)
                .accessibilityLabel("Название списка активностей")
        } header: {
            Text("Основная информация")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
        } footer: {
            Text("Дайте короткое название вашему списку активностей")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
    
    private var activitiesSection: some View {
        Section {
            ForEach($activities) { $item in
                if let index = activities.firstIndex(where: { $0.id == item.id }) {
                    ActivityEditorRow(
                        item: $item,
                        index: index,
                        isRemovable: activities.count > 1,
                        focusState: $focusedField,
                        onDelete: { deleteActivity(at: index) }
                    )
                }
            }
        } header: {
            HStack {
                Text("Активности")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Button {
                    addActivity()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.primary)
                }
                .buttonStyle(.plain)
                .frame(minWidth: TouchTarget.minimum, minHeight: TouchTarget.minimum)
                .accessibilityLabel("Добавить активность")
                .accessibilityHint("Добавляет пустую активность в конец списка")
            }
        } footer: {
            Text("Добавьте одну или несколько активностей. Пустые строки не сохраняются.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
    
    private func addActivity() {
        let newItem = ActivityEditItem(text: "")
        activities.append(newItem)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            focusedField = .activity(newItem.id)
        }
        
        HapticFeedback.impact(.light)
    }
    
    private func deleteActivity(at index: Int) {
        guard activities.count > 1 else { return }
        guard index < activities.count else { return }
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            activities.remove(at: index)
        }
        
        HapticFeedback.impact(.medium)
    }
    
    private func saveActivation() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let validActivities = activities
            .map { $0.text.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        guard !trimmedTitle.isEmpty, !validActivities.isEmpty else {
            errorMessage = "Введите название и добавьте хотя бы одну активность"
            showingError = true
            return
        }
        
        let activation = ActivityList(
            title: trimmedTitle,
            activities: validActivities,
            isPredefined: false
        )
        
        modelContext.insert(activation)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = "Не удалось сохранить: \(error.localizedDescription)"
            showingError = true
        }
    }
}

#Preview {
    CreateActivationView()
        .modelContainer(for: ActivityList.self, inMemory: true)
}

