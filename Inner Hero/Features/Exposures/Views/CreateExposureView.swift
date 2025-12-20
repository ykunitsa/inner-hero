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
                    TextField("Название экспозиции", text: $title)
                        .font(.body)
                        .focused($focusedField, equals: .title)
                        .accessibilityLabel("Название экспозиции")
                    
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $exposureDescription)
                            .font(.body)
                            .frame(minHeight: 80)
                            .focused($focusedField, equals: .description)
                            .accessibilityLabel("Описание экспозиции")
                        
                        if exposureDescription.isEmpty {
                            Text("Описание ситуации, вызывающей тревогу")
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .padding(.top, Spacing.xxs)
                                .padding(.leading, Spacing.xxxs)
                                .allowsHitTesting(false)
                                .accessibilityHidden(true)
                        }
                    }
                } header: {
                    Text("Основная информация")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                } footer: {
                    Text("Дайте короткое название и опишите ситуацию, которая вызывает тревогу")
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
                    
                    Button {
                        addStep()
                    } label: {
                        Label("Добавить шаг", systemImage: "plus.circle.fill")
                            .font(.headline)
                            .foregroundStyle(.teal)
                    }
                    .frame(minHeight: 44)
                    .accessibilityLabel("Добавить шаг")
                    .accessibilityHint("Дважды нажмите чтобы добавить новый шаг")
                } header: {
                    Text("Шаги выполнения")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                } footer: {
                    Text("Опишите последовательность действий. Каждый шаг может иметь свой таймер.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Новая экспозиция")
            .navigationBarTitleDisplayMode(.inline)
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
                    }
                    .accessibilityLabel("Отмена")
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        saveExposure()
                    }
                    .disabled(title.isEmpty || exposureDescription.isEmpty)
                    .opacity((title.isEmpty || exposureDescription.isEmpty) ? 0.5 : 1.0)
                    .accessibilityLabel("Сохранить экспозицию")
                    .accessibilityHint(title.isEmpty ? "Недоступно. Введите название" : (exposureDescription.isEmpty ? "Недоступно. Введите описание" : "Дважды нажмите чтобы сохранить"))
                }
                
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Готово") {
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
        guard index < steps.count else { return }
        
        _ = withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
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
            print("Ошибка сохранения: \(error)")
            
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
