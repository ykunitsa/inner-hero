import SwiftUI

struct StepEditorRow: View {
    @Binding var step: StepEditItem
    let index: Int
    let isRemovable: Bool
    let showsReorderHandle: Bool
    let focusState: FocusState<ExposureFormField?>.Binding
    let onDelete: () -> Void
    
    init(
        step: Binding<StepEditItem>,
        index: Int,
        isRemovable: Bool,
        showsReorderHandle: Bool = false,
        focusState: FocusState<ExposureFormField?>.Binding,
        onDelete: @escaping () -> Void
    ) {
        self._step = step
        self.index = index
        self.isRemovable = isRemovable
        self.showsReorderHandle = showsReorderHandle
        self.focusState = focusState
        self.onDelete = onDelete
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            stepHeader
            timerSection
        }
        .padding(.vertical, Spacing.xxs)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: step.hasTimer)
    }
    
    private var stepHeader: some View {
        HStack(spacing: Spacing.xxs) {
            if showsReorderHandle {
                Image(systemName: "line.3.horizontal")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(minWidth: 44, minHeight: 44)
                    .accessibilityLabel("Переместить шаг")
            }
            
            Text("\(index + 1).")
                .font(.body.weight(.medium))
                .foregroundStyle(.secondary)
                .frame(width: 28, alignment: .trailing)
                .accessibilityHidden(true)
            
            TextField("Шаг \(index + 1)", text: $step.text)
                .font(.body)
                .focused(focusState, equals: .step(step.id))
                .accessibilityLabel("Шаг \(index + 1)")
            
            if isRemovable {
                Button(role: .destructive, action: onDelete) {
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
    }
    
    private var timerSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Toggle("Таймер для этого шага", isOn: $step.hasTimer)
                .font(.subheadline)
                .frame(minHeight: 44)
                .accessibilityLabel("Таймер для шага \(index + 1)")
            
            if step.hasTimer {
                StepTimerControlsView(step: $step)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.top, Spacing.xxxs)
    }
}

private struct StepTimerControlsView: View {
    @Binding var step: StepEditItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text("Длительность")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            
            HStack(spacing: Spacing.sm) {
                durationPicker(title: "Минуты", range: 0..<60, selection: $step.timerMinutes)
                
                Text(":")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.top, Spacing.md)
                
                durationPicker(title: "Секунды", range: 0..<60, selection: $step.timerSeconds, padded: true)
            }
            
            HStack(spacing: Spacing.xxxs) {
                Image(systemName: "clock.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
                    .accessibilityHidden(true)
                
                Text("Общее время: \(formattedDuration)")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.green)
            }
            .padding(.top, Spacing.xxxs)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Общее время: \(formattedDuration)")
        }
        .padding(Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                .fill(Color(.systemGray6))
        )
    }
    
    private func durationPicker(
        title: String,
        range: Range<Int>,
        selection: Binding<Int>,
        padded: Bool = false
    ) -> some View {
        VStack(spacing: Spacing.xxxs) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            
            Picker(title, selection: selection) {
                ForEach(range, id: \.self) { value in
                    if padded {
                        Text(String(format: "%02d", value))
                            .font(.body)
                            .monospacedDigit()
                            .tag(value)
                    } else {
                        Text("\(value)")
                            .font(.body)
                            .tag(value)
                    }
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 80, height: 100)
            .clipped()
        }
    }
    
    private var formattedDuration: String {
        let totalSeconds = step.timerDuration
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        
        if minutes > 0 && seconds > 0 {
            return "\(minutes) мин \(seconds) сек"
        } else if minutes > 0 {
            return "\(minutes) мин"
        } else {
            return "\(seconds) сек"
        }
    }
}
