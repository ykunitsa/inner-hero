import SwiftUI
import SwiftData

struct StartSessionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let exposure: Exposure
    let onSessionCreated: (SessionResult) -> Void
    
    @State private var anxietyBefore: Double = 5
    @State private var showError = false
    @State private var errorMessage = ""
    
    private var dataManager: DataManager {
        DataManager(modelContext: modelContext)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    header
                    anxietySliderSection
                    startButton
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Новый сеанс")
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
    }
    
    private var header: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.mind.and.body")
                .font(.system(size: 60))
                .foregroundStyle(.teal)
            Text("Начать сеанс")
                .font(.title2.weight(.semibold))
            Text(exposure.title)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }
    
    private var anxietySliderSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Label("Уровень тревоги", systemImage: "gauge")
                .font(.headline)
                .foregroundStyle(.primary)
            
            Text("Оцените ваш текущий уровень тревоги до начала сеанса (0–10)")
                .font(.body)
                .foregroundStyle(.secondary)
            
            VStack(spacing: 20) {
                HStack {
                    Spacer()
                    Text("\(Int(anxietyBefore))")
                        .font(.system(.largeTitle, design: .rounded))
                        .fontWeight(.bold)
                        .monospacedDigit()
                        .foregroundStyle(anxietyColor(for: Int(anxietyBefore)))
                    Spacer()
                }
                
                VStack(spacing: 8) {
                    Slider(value: $anxietyBefore, in: 0...10, step: 1)
                        .tint(anxietyColor(for: Int(anxietyBefore)))
                    
                    HStack {
                        Text("0\nНет тревоги")
                            .font(.caption)
                            .multilineTextAlignment(.leading)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("5\nСредний")
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("10\nМаксимум")
                            .font(.caption)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Text(anxietyDescription(for: Int(anxietyBefore)))
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(.tertiarySystemBackground))
                    )
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
            )
        }
        .padding(.horizontal, 20)
    }
    
    private var startButton: some View {
        Button(action: startSession) {
            HStack(spacing: 12) {
                Image(systemName: "play.fill")
                    .font(.body)
                Text("Начать сеанс")
                    .font(.headline)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 56)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.teal)
                    .shadow(color: Color.teal.opacity(0.3), radius: 12, y: 6)
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .accessibilityLabel("Начать сеанс")
    }
    
    // MARK: - Helpers
    
    private func anxietyColor(for value: Int) -> Color {
        switch value {
        case 0...3: return .green
        case 4...6: return .orange
        case 7...10: return .red
        default: return .gray
        }
    }
    
    private func anxietyDescription(for value: Int) -> String {
        switch value {
        case 0: return "Полное спокойствие, нет тревоги"
        case 1...2: return "Очень низкий уровень тревоги"
        case 3...4: return "Легкая тревога, управляемая"
        case 5...6: return "Средний уровень тревоги, заметный дискомфорт"
        case 7...8: return "Высокая тревога, значительный дистресс"
        case 9: return "Очень высокая тревога, трудно терпеть"
        case 10: return "Экстремальная тревога, паника"
        default: return ""
        }
    }
    
    private func startSession() {
        do {
            let session = try dataManager.createSessionResult(
                for: exposure,
                anxietyBefore: Int(anxietyBefore)
            )
            dismiss()
            onSessionCreated(session)
        } catch {
            errorMessage = "Не удалось создать сеанс: \(error.localizedDescription)"
            showError = true
        }
    }
}
