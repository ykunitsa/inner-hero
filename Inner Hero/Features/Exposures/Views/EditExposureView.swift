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
            .navigationTitle("Редактирование")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: toolbarContent)
            .scrollDismissesKeyboard(.interactively)
        }
    }
    
    private var basicInfoSection: some View {
        Section {
            TextField("Название экспозиции", text: $title)
                .font(.body)
                .focused($focusedField, equals: .title)
                .textInputAutocapitalization(.sentences)
            
            ZStack(alignment: .topLeading) {
                if exposureDescription.isEmpty {
                    Text("Описание ситуации, вызывающей тревогу")
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
            Text("Основная информация")
                .font(.footnote)
                .fontWeight(.medium)
        }
    }
    
    private var stepsSection: some View {
        Section {
            stepsListView
        } header: {
            HStack {
                Text("Шаги выполнения")
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
                .accessibilityLabel("Добавить шаг")
                .accessibilityHint("Добавляет пустой шаг в конец списка")
            }
        } footer: {
            Text("Опишите последовательность действий. Каждый шаг может иметь свой таймер. Удерживайте иконку ☰ для изменения порядка или смахните влево для удаления.")
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
            Button("Отмена") {
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
            Button("Сохранить") {
                saveChanges()
            }
            .font(.body)
            .fontWeight(.semibold)
            .disabled(title.isEmpty || exposureDescription.isEmpty)
            .opacity((title.isEmpty || exposureDescription.isEmpty) ? 0.5 : 1.0)
            .accessibilityLabel("Сохранить изменения")
            .accessibilityHint(title.isEmpty || exposureDescription.isEmpty ? "Заполните все обязательные поля" : "Сохраняет экспозицию и закрывает редактор")
        }
    }
    
    private func moveStep(from source: IndexSet, to destination: Int) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        steps.move(fromOffsets: source, toOffset: destination)
    }
    
    private func deleteStep(at offsets: IndexSet) {
        guard steps.count > 1 else { return }
        
        let remainingCount = steps.count - offsets.count
        guard remainingCount >= 1 else { return }
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
        
        withAnimation {
            steps.remove(atOffsets: offsets)
        }
    }
    
    private func addStep() {
        let newStep = StepEditItem(text: "", hasTimer: false, timerMinutes: 5, timerSeconds: 0)
        steps.append(newStep)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            focusedField = .step(newStep.id)
        }
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
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
            
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            dismiss()
        } catch {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
            
            print("Ошибка сохранения: \(error)")
        }
    }
}

#Preview("Edit Exposure") {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Exposure.self, configurations: config)
        
        let sampleSteps = [
            ExposureStep(text: "Первый шаг", hasTimer: false, timerDuration: 0, order: 0),
            ExposureStep(text: "Второй шаг с таймером", hasTimer: true, timerDuration: 300, order: 1),
            ExposureStep(text: "Третий финальный шаг", hasTimer: false, timerDuration: 0, order: 2)
        ]
        
        let sampleExposure = Exposure(
            title: "Пример экспозиции для редактирования",
            exposureDescription: "Описание тестовой экспозиции с несколькими шагами и таймерами",
            steps: sampleSteps
        )
        container.mainContext.insert(sampleExposure)
        
        return EditExposureView(exposure: sampleExposure)
            .modelContainer(container)
    } catch {
        return Text("Failed to create preview: \(error.localizedDescription)")
    }
}
