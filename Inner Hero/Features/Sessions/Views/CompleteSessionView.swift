import SwiftUI
import SwiftData

// MARK: - Complete Session View

struct CompleteSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let session: SessionResult
    let notes: String
    let onComplete: () -> Void
    
    @State private var anxietyAfter: Double = 5
    @State private var finalNotes: String = ""
    @State private var showError = false
    @State private var errorMessage = ""
    
    private var dataManager: DataManager {
        DataManager(modelContext: modelContext)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.teal)
                            .accessibilityHidden(true)
                        
                        Text("Завершение сеанса")
                            .font(.title3.weight(.semibold))
                    }
                    .padding(.top, 20)
                    
                    sessionSummaryCard
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Label("Уровень тревоги после сеанса", systemImage: "gauge")
                            .font(.headline)
                        
                        Text("Оцените ваш уровень тревоги сейчас (0–10)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
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
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color(.secondarySystemGroupedBackground))
                        )
                    }
                    .padding(.horizontal, 20)
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel("Уровень тревоги после сеанса")
                    
                    progressCard
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Дополнительные заметки", systemImage: "note.text")
                            .font(.headline)
                        
                        TextEditor(text: $finalNotes)
                            .frame(minHeight: 100)
                            .padding(10)
                            .background(Color(.tertiarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(.secondarySystemGroupedBackground))
                    )
                    .padding(.horizontal, 20)
                    
                    Button {
                        completeSession()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark")
                                .font(.subheadline)
                            Text("Сохранить результат")
                                .font(.headline)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.teal)
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                    .accessibilityLabel("Сохранить результат сеанса")
                    .accessibilityHint("Дважды нажмите чтобы сохранить и завершить")
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Завершение")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
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
    
    private var sessionSummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Результаты сеанса", systemImage: "chart.bar.fill")
                .font(.headline)
            
            HStack(spacing: 16) {
                VStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.teal)
                        .accessibilityHidden(true)
                    Text("\(session.completedStepIndices.count)")
                        .font(.title2.weight(.bold))
                    Text("шагов")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(session.completedStepIndices.count) шагов выполнено")
                
                Divider()
                
                VStack(spacing: 6) {
                    Image(systemName: "clock.fill")
                        .font(.title3)
                        .foregroundStyle(.teal)
                        .accessibilityHidden(true)
                    Text(formatTime(session.getTotalStepsTime()))
                        .font(.title3.weight(.bold))
                        .monospacedDigit()
                    Text("время")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Время выполнения: \(formatTime(session.getTotalStepsTime()))")
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
        )
        .padding(.horizontal, 20)
    }
    
    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Прогресс", systemImage: "chart.line.uptrend.xyaxis")
                .font(.headline)
            
            HStack(spacing: 12) {
                VStack(spacing: 4) {
                    Text("До")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(session.anxietyBefore)")
                        .font(.title2.weight(.bold))
                }
                
                Image(systemName: "arrow.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .accessibilityHidden(true)
                
                VStack(spacing: 4) {
                    Text("После")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(Int(anxietyAfter))")
                        .font(.title2.weight(.bold))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Изменение")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    let change = session.anxietyBefore - Int(anxietyAfter)
                    Text("\(change > 0 ? "-" : "+")\(abs(change))")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(change > 0 ? .green : (change < 0 ? .red : .gray))
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
        )
        .padding(.horizontal, 20)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Прогресс тревоги")
        .accessibilityValue("До: \(session.anxietyBefore), После: \(Int(anxietyAfter)), Изменение: \(session.anxietyBefore - Int(anxietyAfter))")
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
            dismiss()
            onComplete()
        } catch {
            errorMessage = "Не удалось сохранить результат: \(error.localizedDescription)"
            showError = true
        }
    }
}
