import SwiftUI
import SwiftData

struct EditExposureView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var exposure: Exposure
    
    @State private var title: String
    @State private var exposureDescription: String
    @State private var steps: [StepEditItem]
    
    @FocusState private var focusedField: ExposureFormField?
    
    init(exposure: Exposure) {
        self.exposure = exposure
        _title = State(initialValue: exposure.title)
        _exposureDescription = State(initialValue: exposure.exposureDescription)
        
        // Convert SwiftData Step objects to StepEditItem for editing
        let stepItems: [StepEditItem] = exposure.steps.isEmpty 
            ? [StepEditItem(text: "", hasTimer: false, timerMinutes: 5, timerSeconds: 0)]
            : exposure.steps.map { step in
                StepEditItem(
                    text: step.text,
                    hasTimer: step.hasTimer,
                    timerMinutes: step.timerDuration / 60,
                    timerSeconds: step.timerDuration % 60
                )
            }
        _steps = State(initialValue: stepItems)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                basicInfoSection
                stepsSection
            }
            .navigationTitle(String(localized: "Edit"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: toolbarContent)
            .scrollDismissesKeyboard(.interactively)
        }
    }
    
    private var basicInfoSection: some View {
        Section {
            TextField(String(localized: "Exposure name"), text: $title)
                .font(.body)
                .focused($focusedField, equals: .title)
                .textInputAutocapitalization(.sentences)
            
            ZStack(alignment: .topLeading) {
                if exposureDescription.isEmpty {
                    Text("Description of the anxiety-provoking situation")
                        .font(.body)
                        .foregroundStyle(.tertiary)
                        .padding(.top, 8)
                        .padding(.leading, 4)
                        .allowsHitTesting(false)
                }
                
                TextEditor(text: $exposureDescription)
                    .font(.body)
                    .frame(minHeight: 100)
                    .focused($focusedField, equals: .description)
                    .scrollContentBackground(.hidden)
            }
        } header: {
            Text("Basic information")
                .font(.footnote)
                .fontWeight(.medium)
        }
    }
    
    private var stepsSection: some View {
        Section {
            stepsListView
        } header: {
            HStack {
                Text("Steps")
                    .font(.footnote)
                    .fontWeight(.medium)
                
                Spacer()
                
                Button {
                    addStep()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.teal)
                }
                .buttonStyle(.plain)
                .frame(minWidth: 44, minHeight: 44)
                .accessibilityLabel(String(localized: "Add step"))
                .accessibilityHint(String(localized: "Adds an empty step to the end of the list"))
            }
        } footer: {
            Text("Describe the sequence of actions. Each step can have its own timer. Hold the ☰ icon to reorder or swipe left to delete.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    private var stepsListView: some View {
        ForEach(steps.indices, id: \.self) { index in
            StepEditorRow(
                step: $steps[index],
                index: index,
                isRemovable: steps.count > 1,
                showsReorderHandle: true,
                focusState: $focusedField,
                onDelete: { deleteStep(at: IndexSet(integer: index)) }
            )
            .deleteDisabled(steps.count <= 1)
        }
        .onMove(perform: moveStep)
        .onDelete(perform: deleteStep)
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
            .disabled(title.isEmpty || exposureDescription.isEmpty)
            .opacity((title.isEmpty || exposureDescription.isEmpty) ? 0.5 : 1.0)
            .accessibilityLabel(String(localized: "Save changes"))
            .accessibilityHint(title.isEmpty || exposureDescription.isEmpty ? String(localized: "Fill in all required fields") : String(localized: "Saves the exposure and closes the editor"))
        }
    }
    
    private func moveStep(from source: IndexSet, to destination: Int) {
        HapticFeedback.light()
        steps.move(fromOffsets: source, toOffset: destination)
    }
    
    private func deleteStep(at offsets: IndexSet) {
        guard steps.count > 1 else { return }
        
        let remainingCount = steps.count - offsets.count
        guard remainingCount >= 1 else { return }
        
        HapticFeedback.warning()
        
        withAnimation {
            steps.remove(atOffsets: offsets)
        }
    }
    
    private func addStep() {
        let newStep = StepEditItem(text: "", hasTimer: false, timerMinutes: 5, timerSeconds: 0)
        steps.append(newStep)
        
        Task {
            try? await Task.sleep(for: .seconds(0.1))
            focusedField = .step(newStep.id)
        }
        
        HapticFeedback.light()
    }
    
    private func saveChanges() {
        let filteredSteps = steps
            .filter { !$0.text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty }
            .enumerated()
            .map { index, stepItem in
                ExposureStep(
                    text: stepItem.text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines),
                    hasTimer: stepItem.hasTimer,
                    timerDuration: stepItem.timerDuration,
                    order: index
                )
            }
        
        exposure.title = title
        exposure.exposureDescription = exposureDescription
        exposure.steps = filteredSteps
        
        do {
            try modelContext.save()
            
            HapticFeedback.success()
            
            dismiss()
        } catch {
            HapticFeedback.error()
            
            print("Error saving: \(error)")
        }
    }
}

#Preview("Edit Exposure") {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Exposure.self, configurations: config)
        
        let sampleSteps = [
            ExposureStep(text: String(localized: "First step"), hasTimer: false, timerDuration: 0, order: 0),
            ExposureStep(text: String(localized: "Second step with timer"), hasTimer: true, timerDuration: 300, order: 1),
            ExposureStep(text: String(localized: "Third final step"), hasTimer: false, timerDuration: 0, order: 2)
        ]
        
        let sampleExposure = Exposure(
            title: String(localized: "Sample exposure for editing"),
            exposureDescription: String(localized: "Description of a sample exposure with several steps and timers"),
            steps: sampleSteps
        )
        container.mainContext.insert(sampleExposure)
        
        return EditExposureView(exposure: sampleExposure)
            .modelContainer(container)
    } catch {
        return Text("Failed to create preview: \(error.localizedDescription)")
    }
}
