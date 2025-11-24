//
//  CreateExposureView.swift
//  Inner Hero
//
//  Created by Yauheni Kunitsa on 21.10.25.
//  Redesigned according to Apple HIG and Design Guidelines
//

import SwiftUI
import SwiftData

// MARK: - Step Edit Item

// HIG: Shared helper for editing steps in both Create and Edit views
struct StepEditItem: Identifiable {
    let id = UUID()
    var text: String
    var hasTimer: Bool
    var timerMinutes: Int
    var timerSeconds: Int
    
    var timerDuration: Int {
        timerMinutes * 60 + timerSeconds
    }
}

// MARK: - Create Exposure View

struct CreateExposureView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var exposureDescription = ""
    @State private var steps: [StepEditItem] = [StepEditItem(text: "", hasTimer: false, timerMinutes: 5, timerSeconds: 0)]
    
    // HIG: FocusState для управления клавиатурой
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case title
        case description
        case step(UUID)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Basic Information Section
                
                // HIG: Section с semantic header style
                Section {
                    // HIG: TextField с Dynamic Type support
                    TextField("Название экспозиции", text: $title)
                        .font(.body)
                        .focused($focusedField, equals: .title)
                        // HIG: Accessibility label для VoiceOver
                        .accessibilityLabel("Название экспозиции")
                    
                    // HIG: TextEditor с правильным spacing и placeholder
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $exposureDescription)
                            .font(.body)
                            .frame(minHeight: 80)
                            .focused($focusedField, equals: .description)
                            .accessibilityLabel("Описание экспозиции")
                        
                        if exposureDescription.isEmpty {
                            // HIG: Placeholder с semantic color
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
                    // HIG: Section header с .caption + .medium вместо uppercase
                    Text("Основная информация")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                } footer: {
                    // HIG: Footer с .footnote для пояснений
                    Text("Дайте короткое название и опишите ситуацию, которая вызывает тревогу")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                
                // MARK: - Steps Section
                
                Section {
                    ForEach(steps) { step in
                        if let index = steps.firstIndex(where: { $0.id == step.id }) {
                            stepRow(step: step, index: index)
                        }
                    }
                    
                    // HIG: Add step button с минимальным touch target 44pt
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
                    // HIG: Section header
                    Text("Шаги выполнения")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                } footer: {
                    // HIG: Footer с подсказкой
                    Text("Опишите последовательность действий. Каждый шаг может иметь свой таймер.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            // HIG: .inline для detail screens
            .navigationTitle("Новая экспозиция")
            .navigationBarTitleDisplayMode(.inline)
            // HIG: Scroll dismisses keyboard для удобства
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    // HIG: Secondary button для отмены
                    Button("Отмена") {
                        dismiss()
                    }
                    .accessibilityLabel("Отмена")
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    // HIG: Primary button для подтверждения
                    Button("Сохранить") {
                        saveExposure()
                    }
                    .disabled(title.isEmpty || exposureDescription.isEmpty)
                    // HIG: Visual feedback для disabled state
                    .opacity((title.isEmpty || exposureDescription.isEmpty) ? 0.5 : 1.0)
                    .accessibilityLabel("Сохранить экспозицию")
                    .accessibilityHint(title.isEmpty ? "Недоступно. Введите название" : (exposureDescription.isEmpty ? "Недоступно. Введите описание" : "Дважды нажмите чтобы сохранить"))
                }
                
                // HIG: Keyboard toolbar для удобного закрытия
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Готово") {
                        focusedField = nil
                    }
                    .font(.headline)
                }
            }
        }
        // HIG: Auto-focus на первое поле
        .onAppear {
            focusedField = .title
        }
    }
    
    // MARK: - Step Row Component
    
    // HIG: Extracted component для читаемости и переиспользования
    @ViewBuilder
    private func stepRow(step: StepEditItem, index: Int) -> some View {
        // HIG: VStack с правильным spacing из системы
        VStack(alignment: .leading, spacing: Spacing.xs) {
            // MARK: Step Text Input
            
            HStack(spacing: Spacing.xxs) {
                // HIG: Step number indicator
                Text("\(index + 1).")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .frame(width: 28, alignment: .trailing)
                    .accessibilityHidden(true)
                
                // HIG: TextField с Dynamic Type
                TextField("Шаг \(index + 1)", text: $steps[index].text)
                    .font(.body)
                    .focused($focusedField, equals: .step(step.id))
                    .accessibilityLabel("Шаг \(index + 1)")
                
                // HIG: Delete button с минимальным touch target
                if steps.count > 1 {
                    Button(role: .destructive) {
                        deleteStep(at: index)
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
                    .accessibilityLabel("Удалить шаг \(index + 1)")
                }
            }
            
            // MARK: Timer Controls
            
            // HIG: VStack для вертикальной группировки связанных элементов
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                // HIG: Toggle с минимальным touch target
                Toggle("Таймер для этого шага", isOn: $steps[index].hasTimer)
                    .font(.subheadline)
                    .frame(minHeight: 44)
                    .accessibilityLabel("Таймер для шага \(index + 1)")
                
                if steps[index].hasTimer {
                    timerControls(for: index)
                        // HIG: Transition для плавного появления
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.top, Spacing.xxxs)
        }
        // HIG: Row padding для достаточного пространства
        .padding(.vertical, Spacing.xxs)
        // HIG: Spring animation для естественного движения
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: steps[index].hasTimer)
    }
    
    // MARK: - Timer Controls Component
    
    // HIG: Extracted timer controls для читаемости
    @ViewBuilder
    private func timerControls(for index: Int) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            // HIG: Label с .caption для metadata
            Text("Длительность")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            
            // HIG: Time picker в HStack
            HStack(spacing: Spacing.sm) {
                // Minutes Picker
                VStack(spacing: Spacing.xxxs) {
                    Text("Минуты")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    Picker("Минуты", selection: $steps[index].timerMinutes) {
                        ForEach(0..<60) { minute in
                            Text("\(minute)")
                                .font(.body)
                                .tag(minute)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 80, height: 100)
                    .clipped()
                    .accessibilityLabel("Минуты для шага \(index + 1)")
                }
                
                // HIG: Separator с Dynamic Type
                Text(":")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.top, Spacing.md)
                
                // Seconds Picker
                VStack(spacing: Spacing.xxxs) {
                    Text("Секунды")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    Picker("Секунды", selection: $steps[index].timerSeconds) {
                        ForEach(0..<60) { second in
                            Text(String(format: "%02d", second))
                                .font(.body)
                                .monospacedDigit()
                                .tag(second)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 80, height: 100)
                    .clipped()
                    .accessibilityLabel("Секунды для шага \(index + 1)")
                }
            }
            
            // HIG: Total time display с functional color
            HStack(spacing: Spacing.xxxs) {
                Image(systemName: "clock.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
                    .accessibilityHidden(true)
                
                Text("Общее время: \(formatDuration(steps[index].timerDuration))")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.green)
            }
            .padding(.top, Spacing.xxxs)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Общее время: \(formatDuration(steps[index].timerDuration))")
        }
        // HIG: Card-like padding для визуального группирования
        .padding(Spacing.sm)
        .background(
            // HIG: .continuous style для smooth corners
            RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                .fill(Color(.systemGray6))
        )
    }
    
    // MARK: - Helper Functions
    
    private func addStep() {
        let newStep = StepEditItem(text: "", hasTimer: false, timerMinutes: 5, timerSeconds: 0)
        steps.append(newStep)
        
        // HIG: Auto-focus на новый шаг для удобства
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            focusedField = .step(newStep.id)
        }
        
        // HIG: Haptic feedback для подтверждения действия
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    private func deleteStep(at index: Int) {
        guard index < steps.count else { return }
        
        // HIG: Spring animation для удаления
        _ = withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            steps.remove(at: index)
        }
        
        // HIG: Haptic feedback для подтверждения удаления
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    private func saveExposure() {
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
        
        let newExposure = Exposure(
            title: title,
            exposureDescription: exposureDescription,
            steps: filteredSteps
        )
        
        modelContext.insert(newExposure)
        
        do {
            try modelContext.save()
            
            // HIG: Success haptic при сохранении
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            dismiss()
        } catch {
            print("Ошибка сохранения: \(error)")
            
            // HIG: Error haptic при ошибке
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        }
    }
    
    // HIG: Format duration для читаемого отображения времени
    private func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        
        if minutes > 0 && remainingSeconds > 0 {
            return "\(minutes) мин \(remainingSeconds) сек"
        } else if minutes > 0 {
            return "\(minutes) мин"
        } else {
            return "\(remainingSeconds) сек"
        }
    }
}

// MARK: - Preview

#Preview {
    CreateExposureView()
        .modelContainer(for: Exposure.self, inMemory: true)
}
