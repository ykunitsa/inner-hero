import SwiftUI
import SwiftData

struct CreateExposureView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var exposureDescription = ""
    @State private var steps: [StepEditItem] = [
        StepEditItem(text: "", hasTimer: false, timerMinutes: 5, timerSeconds: 0)
    ]
    
    @FocusState private var focusedField: ExposureFormField?
    
    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Basic Information Section
                
                Section {
                    TextField(String(localized: "Exposure name"), text: $title)
                        .font(.body)
                        .focused($focusedField, equals: .title)
                        .accessibilityLabel(String(localized: "Exposure name"))
                    
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $exposureDescription)
                            .font(.body)
                            .frame(minHeight: 80)
                            .focused($focusedField, equals: .description)
                            .scrollContentBackground(.hidden)
                            .accessibilityLabel(String(localized: "Exposure description"))
                        
                        if exposureDescription.isEmpty {
                            Text("Description of the anxiety-provoking situation")
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .padding(.top, Spacing.xxs)
                                .padding(.leading, Spacing.xxxs)
                                .allowsHitTesting(false)
                                .accessibilityHidden(true)
                        }
                    }
                } header: {
                    Text("Basic information")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                } footer: {
                    Text(String(localized: "Give a short name and describe the situation that causes anxiety"))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                
                // MARK: - Steps Section
                
                Section {
                    ForEach($steps) { $step in
                        if let index = steps.firstIndex(where: { $0.id == step.id }) {
                            StepEditorRow(
                                step: $step,
                                index: index,
                                isRemovable: steps.count > 1,
                                focusState: $focusedField,
                                onDelete: { deleteStep(at: index) }
                            )
                        }
                    }
                } header: {
                    HStack {
                        Text("Steps")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        Button {
                            addStep()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .foregroundStyle(.primary)
                        }
                        .buttonStyle(.plain)
                        .frame(minWidth: 44, minHeight: 44)
                        .accessibilityLabel(String(localized: "Add step"))
                        .accessibilityHint(String(localized: "Adds an empty step to the end of the list"))
                    }
                } footer: {
                    Text("Describe the sequence of actions. Each step can have its own timer.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle(String(localized: "New exposure"))
            .navigationBarTitleDisplayMode(.inline)
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityLabel("Cancel")
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveExposure()
                    }
                    .disabled(title.isEmpty || exposureDescription.isEmpty)
                    .opacity((title.isEmpty || exposureDescription.isEmpty) ? 0.5 : 1.0)
                    .accessibilityLabel(String(localized: "Save exposure"))
                    .accessibilityHint(title.isEmpty ? String(localized: "Unavailable. Enter a name") : (exposureDescription.isEmpty ? String(localized: "Unavailable. Enter a description") : String(localized: "Double tap to save")))
                }
                
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        focusedField = nil
                    }
                    .font(.headline)
                }
            }
        }
        .onAppear {
            focusedField = .title
        }
    }
    
    // MARK: - Helper Functions
    
    private func addStep() {
        let newStep = StepEditItem(text: "", hasTimer: false, timerMinutes: 5, timerSeconds: 0)
        steps.append(newStep)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            focusedField = .step(newStep.id)
        }
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    private func deleteStep(at index: Int) {
        guard steps.count > 1 else { return }
        guard index < steps.count else { return }
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            steps.remove(at: index)
        }
        
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    private func saveExposure() {
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
        
        let newExposure = Exposure(
            title: title,
            exposureDescription: exposureDescription,
            steps: filteredSteps
        )
        
        modelContext.insert(newExposure)
        
        do {
            try modelContext.save()
            
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            dismiss()
        } catch {
            print("Error saving: \(error)")
            
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        }
    }
}

// MARK: - Preview

#Preview {
    CreateExposureView()
        .modelContainer(for: Exposure.self, inMemory: true)
}
