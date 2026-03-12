import SwiftUI
import SwiftData

struct EditActivationView: View {
    let activation: ActivityList
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String
    @State private var activities: [ActivityEditItem]
    @State private var showingError = false
    @State private var errorMessage = ""
    
    @FocusState private var focusedField: ActivationFormField?
    
    init(activation: ActivityList) {
        self.activation = activation
        _title = State(initialValue: activation.title)
        
        let items: [ActivityEditItem] = activation.activities.isEmpty
            ? [ActivityEditItem(text: "")]
            : activation.activities.map { ActivityEditItem(text: $0) }
        _activities = State(initialValue: items)
    }
    
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
            .navigationTitle("Edit list")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: toolbarContent)
            .scrollDismissesKeyboard(.interactively)
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private var basicInfoSection: some View {
        Section {
            TextField("List name", text: $title)
                .font(.body)
                .focused($focusedField, equals: .title)
                .accessibilityLabel("Activity list name")
        } header: {
            Text("Basic information")
                .font(.footnote)
                .fontWeight(.medium)
        }
    }
    
    private var activitiesSection: some View {
        Section {
            activitiesListView
        } header: {
            HStack {
                Text("Activities")
                    .font(.footnote)
                    .fontWeight(.medium)
                
                Spacer()
                
                Button {
                    addActivity()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.teal)
                }
                .buttonStyle(.plain)
                .frame(minWidth: TouchTarget.minimum, minHeight: TouchTarget.minimum)
                .accessibilityLabel("Add activity")
                .accessibilityHint("Adds an empty activity to the end of the list")
            }
        } footer: {
            Text("Hold the ☰ icon to reorder or swipe left to delete.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    private var activitiesListView: some View {
        ForEach($activities) { $item in
            if let index = activities.firstIndex(where: { $0.id == item.id }) {
                ActivityEditorRow(
                    item: $item,
                    index: index,
                    isRemovable: activities.count > 1,
                    focusState: $focusedField,
                    onDelete: { deleteActivity(at: IndexSet(integer: index)) }
                )
                .deleteDisabled(activities.count <= 1)
            }
        }
        .onMove(perform: moveActivity)
        .onDelete(perform: deleteActivity)
    }
    
    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") {
                dismiss()
            }
            .font(.body)
        }
        
        ToolbarItem(placement: .principal) {
            EditButton()
                .font(.body)
                .fontWeight(.medium)
        }
        
        ToolbarItem(placement: .confirmationAction) {
            Button("Save") {
                saveChanges()
            }
            .font(.body)
            .fontWeight(.semibold)
            .disabled(!canSave)
            .opacity(canSave ? 1.0 : 0.5)
            .accessibilityLabel(String(localized: "Save changes"))
            .accessibilityHint(canSave ? String(localized: "Saves the activity list and closes the editor") : String(localized: "Fill in all required fields"))
        }
        
        ToolbarItemGroup(placement: .keyboard) {
            Spacer()
            Button("Done") {
                focusedField = nil
            }
            .font(.headline)
        }
    }
    
    private func moveActivity(from source: IndexSet, to destination: Int) {
        HapticFeedback.impact(.light)
        activities.move(fromOffsets: source, toOffset: destination)
    }
    
    private func deleteActivity(at offsets: IndexSet) {
        guard activities.count > 1 else { return }
        let remainingCount = activities.count - offsets.count
        guard remainingCount >= 1 else { return }
        
        HapticFeedback.warning()
        
        withAnimation {
            activities.remove(atOffsets: offsets)
        }
    }
    
    private func addActivity() {
        let newItem = ActivityEditItem(text: "")
        activities.append(newItem)
        
        Task {
            try? await Task.sleep(for: .seconds(0.1))
            focusedField = .activity(newItem.id)
        }
        
        HapticFeedback.impact(.light)
    }
    
    private func saveChanges() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let validActivities = activities
            .map { $0.text.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        guard !trimmedTitle.isEmpty, !validActivities.isEmpty else {
            errorMessage = String(localized: "Enter name and add at least one activity")
            showingError = true
            return
        }
        
        activation.title = trimmedTitle
        activation.activities = validActivities
        
        do {
            try modelContext.save()
            HapticFeedback.success()
            dismiss()
        } catch {
            HapticFeedback.error()
            errorMessage = String(localized: "Failed to save changes.") + " \(error.localizedDescription)"
            showingError = true
        }
    }
}

#Preview {
    EditActivationView(
        activation: ActivityList(
            title: "Morning routine",
            activities: ["Warm-up", "Meditation"],
            isPredefined: false
        )
    )
    .modelContainer(for: ActivityList.self, inMemory: true)
}

