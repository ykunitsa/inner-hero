import SwiftUI
import SwiftData

// MARK: - Complete Session View

struct CompleteSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    
    let session: ExposureSessionResult
    let notes: String
    let onComplete: () -> Void
    
    @State private var anxietyAfter: Double = 5
    @State private var finalNotes: String = ""
    @State private var showError = false
    @State private var errorMessage = ""
    
    private enum FocusField: Hashable {
        case finalNotes
    }
    
    @FocusState private var focusedField: FocusField?
    
    private var dataManager: DataManager {
        DataManager(modelContext: modelContext)
    }
    
    private var screenBackgroundGradientColors: [Color] {
        if colorScheme == .dark {
            return [
                Color(red: 0.06, green: 0.07, blue: 0.09),
                Color(red: 0.10, green: 0.11, blue: 0.14)
            ]
        }
        
        return [
            Color(red: 0.95, green: 0.97, blue: 1.0),
            Color(red: 0.92, green: 0.95, blue: 0.98)
        ]
    }
    
    private var cardBackgroundColor: Color {
        if colorScheme == .dark {
            return Color(red: 0.14, green: 0.15, blue: 0.18)
        }
        
        return Color.white
    }
    
    private var cardShadowOpacity: Double {
        colorScheme == .dark ? Opacity.darkShadow : Opacity.lightShadow
    }
    
    private var editorBackgroundGradientColors: [Color] {
        if colorScheme == .dark {
            return [
                Color(red: 0.12, green: 0.13, blue: 0.16),
                Color(red: 0.09, green: 0.10, blue: 0.13)
            ]
        }
        
        return [
            Color(red: 0.98, green: 0.99, blue: 1.0),
            Color(red: 0.96, green: 0.97, blue: 0.99)
        ]
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    sessionSummaryCard
                    
                    praiseCard
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Label("Уровень тревоги после сеанса", systemImage: "gauge")
                            .font(.headline)
                            .foregroundStyle(TextColors.primary)
                        
                        Text("Оцените ваш уровень тревоги сейчас (0–10)")
                            .font(.subheadline)
                            .foregroundStyle(TextColors.secondary)
                        
                        VStack(spacing: 16) {
                            HStack {
                                Spacer()
                                Text("\(Int(anxietyAfter))")
                                    .font(.system(.title, design: .rounded))
                                    .fontWeight(.bold)
                                    .foregroundStyle(anxietyColor(for: Int(anxietyAfter)))
                                    .monospacedDigit()
                                Spacer()
                            }
                            
                            Slider(value: $anxietyAfter, in: 0...10, step: 1)
                                .tint(anxietyColor(for: Int(anxietyAfter)))
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: editorBackgroundGradientColors,
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                    }
                    .padding(.horizontal, 20)
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel("Уровень тревоги после сеанса")
                    
                    progressCard
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Опишите ваше состояние", systemImage: "note.text")
                            .font(.headline)
                            .foregroundStyle(TextColors.primary)
                        
                        Text("Что вы чувствуете сейчас? Какие мысли/ощущения были во время сеанса? Что помогло?")
                            .font(.subheadline)
                            .foregroundStyle(TextColors.secondary)
                        
                        TextEditor(text: $finalNotes)
                            .frame(minHeight: 100)
                            .focused($focusedField, equals: .finalNotes)
                            .scrollContentBackground(.hidden)
                            .padding(10)
                            .background(
                                LinearGradient(
                                    colors: editorBackgroundGradientColors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(cardBackgroundColor)
                            .shadow(color: Color.black.opacity(cardShadowOpacity), radius: 10, x: 0, y: 4)
                    )
                    .padding(.horizontal, 20)
                }
                .padding(.top, 20)
                .padding(.bottom, 32)
            }
            .background(
                LinearGradient(
                    colors: screenBackgroundGradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
                    }
                    .foregroundStyle(TextColors.toolbar)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        completeSession()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(TextColors.toolbar)
                    .accessibilityLabel("Сохранить результат сеанса")
                    .accessibilityHint("Дважды нажмите чтобы сохранить и завершить")
                }
                
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Готово") {
                        focusedField = nil
                    }
                }
            }
            .alert("Ошибка", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
        .onAppear {
            finalNotes = notes
        }
    }
    
    private var praiseCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Вы молодец!", systemImage: "sparkles")
                .font(.headline)
                .foregroundStyle(TextColors.primary)
            
            Text("Вы завершили сеанс — это уже важный шаг. Даже если тревога была высокой, вы тренировались оставаться рядом с ощущениями и двигаться вперёд.")
                .font(.body)
                .foregroundStyle(TextColors.secondary)
            
            VStack(alignment: .leading, spacing: 12) {
                PraiseTipRow(
                    iconSystemName: "checkmark.seal",
                    text: "Отметьте любой маленький прогресс — он накапливается."
                )
                
                PraiseTipRow(
                    iconSystemName: "heart.text.square",
                    text: "Запишите, что помогло (дыхание, фокус на задаче, поддерживающая мысль) — это пригодится в следующий раз."
                )
            }
            .font(.subheadline)
            .foregroundStyle(TextColors.secondary)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(cardBackgroundColor)
                .shadow(color: Color.black.opacity(cardShadowOpacity), radius: 10, x: 0, y: 4)
        )
        .padding(.horizontal, 20)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Похвала за выполнение сеанса")
        .accessibilityHint("Короткое поддерживающее сообщение и подсказки")
    }
    
    private var sessionSummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Результаты сеанса", systemImage: "chart.bar.fill")
                .font(.headline)
                .foregroundStyle(TextColors.primary)
            
            HStack(spacing: 16) {
                VStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .accessibilityHidden(true)
                    Text("\(session.completedStepIndices.count)")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(TextColors.primary)
                    Text("шагов")
                        .font(.caption)
                        .foregroundStyle(TextColors.secondary)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(session.completedStepIndices.count) шагов выполнено")
                
                Divider()
                
                VStack(spacing: 6) {
                    Image(systemName: "clock.fill")
                        .font(.title3)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .accessibilityHidden(true)
                    Text(formatTime(session.getTotalStepsTime()))
                        .font(.title3.weight(.bold))
                        .foregroundStyle(TextColors.primary)
                        .monospacedDigit()
                    Text("время")
                        .font(.caption)
                        .foregroundStyle(TextColors.secondary)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Время выполнения: \(formatTime(session.getTotalStepsTime()))")
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(cardBackgroundColor)
                .shadow(color: Color.black.opacity(cardShadowOpacity), radius: 10, x: 0, y: 4)
        )
        .padding(.horizontal, 20)
    }
    
    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Прогресс", systemImage: "chart.line.uptrend.xyaxis")
                .font(.headline)
                .foregroundStyle(TextColors.primary)
            
            HStack(spacing: 14) {
                progressGauge(title: "До", value: session.anxietyBefore)
                
                Image(systemName: "arrow.right")
                    .font(.caption)
                    .foregroundStyle(TextColors.secondary)
                    .padding(.horizontal, 2)
                    .accessibilityHidden(true)
                
                progressGauge(title: "После", value: Int(anxietyAfter))
                
                Spacer(minLength: 8)
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Изменение")
                        .font(.caption)
                        .foregroundStyle(TextColors.secondary)
                    
                    let change = session.anxietyBefore - Int(anxietyAfter)
                    let changeText = change == 0 ? "0" : "\(change > 0 ? "-" : "+")\(abs(change))"
                    
                    Text(changeText)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(change > 0 ? .green : (change < 0 ? .yellow : .gray))
                        .monospacedDigit()
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(cardBackgroundColor)
                .shadow(color: Color.black.opacity(cardShadowOpacity), radius: 10, x: 0, y: 4)
        )
        .padding(.horizontal, 20)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Прогресс тревоги")
        .accessibilityValue(accessibilityProgressValue)
    }

    private func progressGauge(title: String, value: Int) -> some View {
        VStack(spacing: 8) {
            Gauge(value: Double(value), in: 0...10) {
                EmptyView()
            } currentValueLabel: {
                Text("\(value)")
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundStyle(TextColors.primary)
                    .monospacedDigit()
            }
            .gaugeStyle(.accessoryCircular)
            .tint(anxietyColor(for: value))
            .frame(width: 58, height: 58)
            .accessibilityHidden(true)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(TextColors.secondary)
        }
        .frame(width: 72)
    }
    
    private var accessibilityProgressValue: String {
        let before = session.anxietyBefore
        let after = Int(anxietyAfter)
        let change = before - after
        let changeText = change == 0 ? "0" : "\(change > 0 ? "-" : "+")\(abs(change))"
        return "До: \(before) из 10, После: \(after) из 10, Изменение: \(changeText)"
    }
    
    private struct PraiseTipRow: View {
        let iconSystemName: String
        let text: String
        
        var body: some View {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: iconSystemName)
                    .frame(width: 22, alignment: .center)
                    .padding(.top, 1)
                    .accessibilityHidden(true)
                
                Text(text)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .accessibilityElement(children: .combine)
        }
    }
    
    private func anxietyColor(for value: Int) -> Color {
        switch value {
        case 0...3:
            return .green
        case 4...6:
            return .orange
        case 7...10:
            return .red
        default:
            return .gray
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func completeSession() {
        do {
            let combinedNotes = notes.isEmpty ? finalNotes : notes + "\n\n" + finalNotes
            try dataManager.completeSession(
                session,
                anxietyAfter: Int(anxietyAfter),
                notes: combinedNotes.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            onComplete()
        } catch {
            errorMessage = "Не удалось сохранить результат: \(error.localizedDescription)"
            showError = true
        }
    }
}
