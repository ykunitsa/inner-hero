import SwiftUI
import SwiftData

// MARK: - Complete Session View

struct CompleteSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let session: ExposureSessionResult
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
                            .font(.system(size: 56))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.green, .green.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .accessibilityHidden(true)
                        
                        Text("Завершение сеанса")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(TextColors.primary)
                    }
                    .padding(.top, 20)
                    
                    sessionSummaryCard
                    
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
                                        colors: [
                                            Color(red: 0.98, green: 0.99, blue: 1.0),
                                            Color(red: 0.96, green: 0.97, blue: 0.99)
                                        ],
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
                        Label("Дополнительные заметки", systemImage: "note.text")
                            .font(.headline)
                            .foregroundStyle(TextColors.primary)
                        
                        TextEditor(text: $finalNotes)
                            .frame(minHeight: 100)
                            .padding(10)
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.98, green: 0.99, blue: 1.0),
                                        Color(red: 0.96, green: 0.97, blue: 0.99)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                    )
                    .padding(.horizontal, 20)
                    
                    Button {
                        completeSession()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark")
                                .font(.body)
                            Text("Сохранить результат")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [.blue, .cyan],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                    .accessibilityLabel("Сохранить результат сеанса")
                    .accessibilityHint("Дважды нажмите чтобы сохранить и завершить")
                }
            }
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.95, green: 0.97, blue: 1.0),
                        Color(red: 0.92, green: 0.95, blue: 0.98)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Завершение")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
                    }
                    .foregroundStyle(TextColors.toolbar)
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
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
        .padding(.horizontal, 20)
    }
    
    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Прогресс", systemImage: "chart.line.uptrend.xyaxis")
                .font(.headline)
                .foregroundStyle(TextColors.primary)
            
            HStack(spacing: 12) {
                VStack(spacing: 4) {
                    Text("До")
                        .font(.caption)
                        .foregroundStyle(TextColors.secondary)
                    Text("\(session.anxietyBefore)")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(TextColors.primary)
                }
                
                Image(systemName: "arrow.right")
                    .font(.caption)
                    .foregroundStyle(TextColors.secondary)
                    .padding(.horizontal, 8)
                    .accessibilityHidden(true)
                
                VStack(spacing: 4) {
                    Text("После")
                        .font(.caption)
                        .foregroundStyle(TextColors.secondary)
                    Text("\(Int(anxietyAfter))")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(TextColors.primary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Изменение")
                        .font(.caption)
                        .foregroundStyle(TextColors.secondary)
                    let change = session.anxietyBefore - Int(anxietyAfter)
                    Text("\(change > 0 ? "-" : "+")\(abs(change))")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(change > 0 ? .green : (change < 0 ? .red : .gray))
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
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
