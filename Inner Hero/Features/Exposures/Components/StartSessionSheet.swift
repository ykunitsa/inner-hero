import SwiftUI
import SwiftData

struct StartSessionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    
    let exposure: Exposure
    let onSessionCreated: (ExposureSessionResult) -> Void
    
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
                .padding(.bottom, 20)
            }
            .background(TopMeshGradientBackground())
            .navigationTitle("Новый сеанс")
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
    }
    
    private var header: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.mind.and.body")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .cyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Text("Начать сеанс")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(TextColors.primary)
            Text(exposure.title)
                .font(.body)
                .foregroundStyle(TextColors.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
        .padding(.horizontal, 20)
    }
    
    private var anxietySliderSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Label("Уровень тревоги", systemImage: "gauge")
                .font(.headline)
                .foregroundStyle(TextColors.primary)
            
            Text("Оцените ваш текущий уровень тревоги до начала сеанса (0–10)")
                .font(.body)
                .foregroundStyle(TextColors.secondary)
            
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
                            .foregroundStyle(TextColors.secondary)
                        Spacer()
                        Text("5\nСредний")
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(TextColors.secondary)
                        Spacer()
                        Text("10\nМаксимум")
                            .font(.caption)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(TextColors.secondary)
                    }
                }
                
                Text(anxietyDescription(for: Int(anxietyBefore)))
                    .font(.body)
                    .foregroundStyle(TextColors.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
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
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.thinMaterial)
                .shadow(
                    color: .black.opacity(colorScheme == .dark ? 0.35 : 0.06),
                    radius: 10,
                    x: 0,
                    y: 4
                )
        )
        .padding(.horizontal, 20)
    }
    
    private var startButton: some View {
        Button(action: startSession) {
            HStack(spacing: 8) {
                Image(systemName: "play.fill")
                    .font(.body)
                Text("Начать сеанс")
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
