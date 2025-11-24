//
//  EditExposureView.swift
//  Inner Hero
//
//  Created by Yauheni Kunitsa on 21.10.25.
//

import SwiftUI
import SwiftData

// MARK: - Helper View for Step Row
private struct StepEditRow: View {
    let index: Int
    let step: StepEditItem
    @Binding var steps: [StepEditItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // HIG: Drag handle с минимальным touch target 44x44pt
                Image(systemName: "line.3.horizontal")
                    .font(.body) // HIG: Semantic font вместо фиксированного размера
                    .foregroundStyle(.secondary)
                    .frame(minWidth: 44, minHeight: 44) // HIG: Минимальный touch target
                    .accessibilityLabel("Переместить шаг") // HIG: VoiceOver support
                
                // HIG: Caption для номера шага с semantic color
                Text("\(index + 1).")
                    .font(.callout) // HIG: Semantic font для номеров
                    .foregroundStyle(.secondary)
                    .frame(width: 28, alignment: .trailing)
                
                // HIG: TextField с автоматическим Dynamic Type
                TextField("Шаг", text: Binding(
                    get: {
                        guard let currentIndex = steps.firstIndex(where: { $0.id == step.id }),
                              steps.indices.contains(currentIndex) else { return "" }
                        return steps[currentIndex].text
                    },
                    set: { newValue in
                        guard let currentIndex = steps.firstIndex(where: { $0.id == step.id }),
                              steps.indices.contains(currentIndex) else { return }
                        steps[currentIndex].text = newValue
                    }
                ))
                .font(.body) // HIG: Body font для основного ввода
                .textFieldStyle(.plain) // HIG: Стандартный стиль для Form
                
                if steps.count > 1 {
                    // HIG: Destructive button с минимальным touch target
                    Button {
                        guard steps.count > 1,
                              let indexToRemove = steps.firstIndex(where: { $0.id == step.id }),
                              steps.indices.contains(indexToRemove) else { return }
                        withAnimation {
                            steps.remove(at: indexToRemove)
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3) // HIG: Достаточно крупная иконка
                            .foregroundStyle(.red, .red.opacity(0.15)) // HIG: Semantic destructive color
                    }
                    .buttonStyle(.plain)
                    .frame(minWidth: 44, minHeight: 44) // HIG: Минимальный touch target
                    .accessibilityLabel("Удалить шаг") // HIG: VoiceOver support
                }
            }
            
            // HIG: Spacing 12pt между основным контентом и таймером
            StepTimerControls(step: step, steps: $steps)
        }
        .padding(.vertical, 12) // HIG: Spacing кратный 4pt
    }
}

// MARK: - Helper View for Timer Controls
private struct StepTimerControls: View {
    let step: StepEditItem
    @Binding var steps: [StepEditItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) { // HIG: Spacing 12pt между элементами
            // HIG: Toggle с semantic font и automatic Dynamic Type
            Toggle("Таймер для этого шага", isOn: Binding(
                get: {
                    guard let currentIndex = steps.firstIndex(where: { $0.id == step.id }),
                          steps.indices.contains(currentIndex) else { return false }
                    return steps[currentIndex].hasTimer
                },
                set: { newValue in
                    guard let currentIndex = steps.firstIndex(where: { $0.id == step.id }),
                          steps.indices.contains(currentIndex) else { return }
                    steps[currentIndex].hasTimer = newValue
                }
            ))
            .font(.body) // HIG: Body font для основных toggles
            .tint(.teal) // HIG: Brand accent color
            
            if step.hasTimer {
                TimerDurationPicker(step: step, steps: $steps)
            }
        }
        .padding(.top, 4) // HIG: Минимальный отступ сверху
    }
}

// MARK: - Helper View for Timer Duration Picker
private struct TimerDurationPicker: View {
    let step: StepEditItem
    @Binding var steps: [StepEditItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) { // HIG: Spacing 12pt
            // HIG: Caption для метки с semantic color
            Text("Длительность")
                .font(.caption) // HIG: Caption для labels
                .fontWeight(.medium) // HIG: Medium weight для выделения
                .foregroundStyle(.secondary)
            
            HStack(spacing: 16) { // HIG: Spacing 16pt между пикерами
                // Minutes Picker
                VStack(spacing: 8) { // HIG: Spacing 8pt
                    Text("Минуты")
                        .font(.caption) // HIG: Caption для меток пикера
                        .foregroundStyle(.secondary)
                    
                    Picker("Минуты", selection: Binding(
                        get: {
                            guard let currentIndex = steps.firstIndex(where: { $0.id == step.id }),
                                  steps.indices.contains(currentIndex) else { return 0 }
                            return steps[currentIndex].timerMinutes
                        },
                        set: { newValue in
                            guard let currentIndex = steps.firstIndex(where: { $0.id == step.id }),
                                  steps.indices.contains(currentIndex) else { return }
                            steps[currentIndex].timerMinutes = newValue
                        }
                    )) {
                        ForEach(0..<60) { minute in
                            Text("\(minute)")
                                .font(.body) // HIG: Body font для значений
                                .tag(minute)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 80, height: 120) // HIG: Достаточная высота для удобства
                    .clipped()
                    .accessibilityLabel("Минуты таймера") // HIG: VoiceOver support
                }
                
                // HIG: Separator с semantic font и монопространством
                Text(":")
                    .font(.title2) // HIG: Semantic font для separator
                    .fontWeight(.semibold)
                    .padding(.top, 24) // HIG: Выравнивание по центру пикеров
                
                // Seconds Picker
                VStack(spacing: 8) { // HIG: Spacing 8pt
                    Text("Секунды")
                        .font(.caption) // HIG: Caption для меток пикера
                        .foregroundStyle(.secondary)
                    
                    Picker("Секунды", selection: Binding(
                        get: {
                            guard let currentIndex = steps.firstIndex(where: { $0.id == step.id }),
                                  steps.indices.contains(currentIndex) else { return 0 }
                            return steps[currentIndex].timerSeconds
                        },
                        set: { newValue in
                            guard let currentIndex = steps.firstIndex(where: { $0.id == step.id }),
                                  steps.indices.contains(currentIndex) else { return }
                            steps[currentIndex].timerSeconds = newValue
                        }
                    )) {
                        ForEach(0..<60) { second in
                            Text(String(format: "%02d", second))
                                .font(.body) // HIG: Body font для значений
                                .monospacedDigit() // HIG: Монопространство для цифр
                                .tag(second)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 80, height: 120) // HIG: Достаточная высота для удобства
                    .clipped()
                    .accessibilityLabel("Секунды таймера") // HIG: VoiceOver support
                }
            }
            
            // HIG: Итоговое время с semantic color и монопространством
            Text("Общее время: \(step.timerDuration) сек (\(step.timerMinutes):\(String(format: "%02d", step.timerSeconds)))")
                .font(.caption) // HIG: Caption для вспомогательной информации
                .fontWeight(.medium) // HIG: Medium для выделения
                .foregroundStyle(.green) // HIG: Green для успешного состояния
                .monospacedDigit() // HIG: Монопространство для чисел
        }
        .padding(.leading, 16) // HIG: Отступ 16pt для визуальной иерархии
    }
}

// MARK: - Main View
struct EditExposureView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var exposure: Exposure
    
    @State private var title: String
    @State private var exposureDescription: String
    @State private var steps: [StepEditItem]
    
    // HIG: Focus state для управления фокусом клавиатуры
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case title
        case description
    }
    
    init(exposure: Exposure) {
        self.exposure = exposure
        _title = State(initialValue: exposure.title)
        _exposureDescription = State(initialValue: exposure.exposureDescription)
        
        // Convert Step objects to StepEditItem for editing
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
            // HIG: Form для редактирования с automatic grouped style
            Form {
                basicInfoSection
                stepsSection
            }
            // HIG: Inline title для detail/edit screens
            .navigationTitle("Редактирование")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: toolbarContent)
            // HIG: Keyboard dismiss на scroll
            .scrollDismissesKeyboard(.interactively)
        }
    }
    
    private var basicInfoSection: some View {
        // HIG: Section с семантическим заголовком
        Section {
            // HIG: TextField с body font и focus state
            TextField("Название экспозиции", text: $title)
                .font(.body) // HIG: Body font для основного ввода
                .focused($focusedField, equals: .title)
                .textInputAutocapitalization(.sentences) // HIG: Автокапитализация предложений
            
            // HIG: TextEditor с минимальной высотой и placeholder
            ZStack(alignment: .topLeading) {
                // HIG: Placeholder с правильным позиционированием
                if exposureDescription.isEmpty {
                    Text("Описание ситуации, вызывающей тревогу")
                        .font(.body) // HIG: Body font для placeholder
                        .foregroundStyle(.tertiary) // HIG: Tertiary для placeholder
                        .padding(.top, 8)
                        .padding(.leading, 4)
                        .allowsHitTesting(false)
                }
                
                TextEditor(text: $exposureDescription)
                    .font(.body) // HIG: Body font для основного текста
                    .frame(minHeight: 100) // HIG: Достаточная высота для редактирования
                    .focused($focusedField, equals: .description)
                    .scrollContentBackground(.hidden) // HIG: Прозрачный фон для TextEditor в Form
            }
        } header: {
            // HIG: Section header с semantic font
            Text("Основная информация")
                .font(.footnote) // HIG: Footnote для section headers в Form
                .fontWeight(.medium)
        }
    }
    
    private var stepsSection: some View {
        Section {
            stepsListView
            addStepButton
        } header: {
            // HIG: Section header с semantic font
            Text("Шаги выполнения")
                .font(.footnote) // HIG: Footnote для section headers
                .fontWeight(.medium)
        } footer: {
            // HIG: Footer с caption font и tertiary color
            Text("Опишите последовательность действий. Каждый шаг может иметь свой таймер. Удерживайте иконку ☰ для изменения порядка или смахните влево для удаления.")
                .font(.caption) // HIG: Caption для footer text
                .foregroundStyle(.secondary)
        }
    }
    
    private var stepsListView: some View {
        ForEach(steps.indices, id: \.self) { index in
            StepEditRow(index: index, step: steps[index], steps: $steps)
                .deleteDisabled(steps.count <= 1)
        }
        .onMove(perform: moveStep)
        .onDelete(perform: deleteStep)
    }
    
    private var addStepButton: some View {
        // HIG: Button с Label и semantic styling
        Button {
            steps.append(StepEditItem(text: "", hasTimer: false, timerMinutes: 5, timerSeconds: 0))
        } label: {
            Label("Добавить шаг", systemImage: "plus.circle.fill")
                .font(.body) // HIG: Body font для кнопок
                .fontWeight(.medium) // HIG: Medium weight для выделения
        }
        .tint(.teal) // HIG: Brand accent color
        .frame(minHeight: 44) // HIG: Минимальный touch target
        .accessibilityLabel("Добавить новый шаг") // HIG: VoiceOver support
        .accessibilityHint("Добавляет пустой шаг в конец списка") // HIG: Contextual hint
    }
    
    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
        // HIG: Cancel button в cancellationAction placement
        ToolbarItem(placement: .cancellationAction) {
            Button("Отмена") {
                dismiss()
            }
            .font(.body) // HIG: Body font для toolbar buttons
        }
        
        // HIG: Edit button в principal placement
        ToolbarItem(placement: .principal) {
            EditButton()
                .font(.body) // HIG: Body font для toolbar buttons
                .fontWeight(.medium)
        }
        
        // HIG: Save button в confirmationAction placement
        ToolbarItem(placement: .confirmationAction) {
            Button("Сохранить") {
                saveChanges()
            }
            .font(.body) // HIG: Body font для toolbar buttons
            .fontWeight(.semibold) // HIG: Semibold для primary action
            .disabled(title.isEmpty || exposureDescription.isEmpty)
            // HIG: Визуальная индикация disabled состояния
            .opacity((title.isEmpty || exposureDescription.isEmpty) ? 0.5 : 1.0)
            .accessibilityLabel("Сохранить изменения") // HIG: VoiceOver support
            .accessibilityHint(title.isEmpty || exposureDescription.isEmpty ? "Заполните все обязательные поля" : "Сохраняет экспозицию и закрывает редактор")
        }
    }
    
    private func moveStep(from source: IndexSet, to destination: Int) {
        // HIG: Haptic feedback для reorder действия
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        steps.move(fromOffsets: source, toOffset: destination)
    }
    
    private func deleteStep(at offsets: IndexSet) {
        // Не удаляем последний шаг
        guard steps.count > 1 else { return }
        
        // Проверяем, что после удаления останется хотя бы один элемент
        let remainingCount = steps.count - offsets.count
        guard remainingCount >= 1 else { return }
        
        // HIG: Haptic feedback для destructive действия
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
        
        withAnimation {
            steps.remove(atOffsets: offsets)
        }
    }
    
    private func saveChanges() {
        // Фильтруем пустые шаги и создаем Step объекты
        let filteredSteps = steps
            .filter { !$0.text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty }
            .enumerated()
            .map { index, stepItem in
                Step(
                    text: stepItem.text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines),
                    hasTimer: stepItem.hasTimer,
                    timerDuration: stepItem.timerDuration,
                    order: index
                )
            }
        
        // Обновляем существующую экспозицию
        exposure.title = title
        exposure.exposureDescription = exposureDescription
        exposure.steps = filteredSteps
        
        do {
            try modelContext.save()
            
            // HIG: Haptic feedback для успешного сохранения
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            dismiss()
        } catch {
            // HIG: Haptic feedback для ошибки
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
            Step(text: "Первый шаг", hasTimer: false, timerDuration: 0, order: 0),
            Step(text: "Второй шаг с таймером", hasTimer: true, timerDuration: 300, order: 1),
            Step(text: "Третий финальный шаг", hasTimer: false, timerDuration: 0, order: 2)
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
