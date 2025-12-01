import SwiftUI
import SwiftData

struct SessionView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Exposure.createdAt, order: .reverse) private var exposures: [Exposure]
    
    @State private var selectedExposure: Exposure?
    @State private var anxietyBefore: Double = 5
    @State private var showingActiveSession = false
    @State private var currentSession: SessionResult?
    @State private var showError = false
    @State private var errorMessage = ""
    
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    private var dataManager: DataManager {
        DataManager(modelContext: modelContext)
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if exposures.isEmpty {
                    emptyStateView
                } else {
                    startSessionForm
                }
            }
            .navigationTitle("Сеанс")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(isPresented: $showingActiveSession) {
                if let session = currentSession, let exposure = selectedExposure {
                    ActiveSessionView(session: session, exposure: exposure)
                }
            }
            .alert("Ошибка", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Subviews
    
    private var emptyStateView: some View {
        ContentUnavailableView(
            "Нет экспозиций",
            systemImage: "play.circle",
            description: Text("Создайте экспозицию на вкладке \"Экспозиции\"")
        )
    }
    
    private var startSessionForm: some View {
        ScrollView {
            VStack(spacing: 32) {
                formHeader
                
                VStack(spacing: 24) {
                    exposureSelectionSection
                    
                    Divider()
                        .padding(.horizontal, 20)
                    
                    anxietyBeforeSection
                }
                
                startSessionButton
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
    
    // MARK: - Form Components
    
    private var formHeader: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.mind.and.body")
                .font(.system(size: 64))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.blue)
                .accessibilityHidden(true)
            
            Text("Начать новый сеанс")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
        }
        .padding(.top, 24)
    }
    
    private var exposureSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Выберите экспозицию", systemImage: "list.bullet.clipboard")
                .font(.headline)
                .foregroundStyle(.primary)
            
            if let selected = selectedExposure {
                exposureCard(selected)
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
            
            exposureSelectionMenu
        }
        .padding(.horizontal, 20)
    }
    
    private var exposureSelectionMenu: some View {
        Menu {
            ForEach(exposures) { exposure in
                Button {
                    selectExposure(exposure)
                } label: {
                    HStack {
                        Text(exposure.title)
                        if exposure.id == selectedExposure?.id {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            exposureSelectionMenuLabel
        }
        .frame(minHeight: 44)
        .accessibilityLabel("Выбор экспозиции")
        .accessibilityHint(selectedExposure == nil ? "Выберите экспозицию для начала сеанса" : "Текущая экспозиция: \(selectedExposure?.title ?? "")")
    }
    
    private var exposureSelectionMenuLabel: some View {
        HStack {
            Text(selectedExposure == nil ? "Выбрать экспозицию" : "Изменить выбор")
                .font(.body)
                .foregroundStyle(selectedExposure == nil ? Color.secondary : Color.blue)
            Spacer()
            Image(systemName: "chevron.down")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    
    private func selectExposure(_ exposure: Exposure) {
        withAnimation(reduceMotion ? .none : .easeInOut(duration: 0.3)) {
            selectedExposure = exposure
        }
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
    
    private var anxietyBeforeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
                        Label("Уровень тревоги (0–10)", systemImage: "gauge.with.dots.needle.33percent")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        Text("Оцените ваш текущий уровень тревоги до начала сеанса")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        VStack(spacing: 20) {
                            HStack {
                                Spacer()
                                Text("\(Int(anxietyBefore))")
                                    .font(.system(.largeTitle, design: .rounded))
                                    .fontWeight(.bold)
                                    .monospacedDigit()
                                    .foregroundStyle(anxietyColor(for: Int(anxietyBefore)))
                                    .accessibilityLabel("Уровень тревоги: \(Int(anxietyBefore)) из 10")
                                Spacer()
                            }
                            .padding(.vertical, 12)
                            
                            VStack(spacing: 8) {
                                Slider(value: $anxietyBefore, in: 0...10, step: 1)
                                    .tint(anxietyColor(for: Int(anxietyBefore)))
                                    .accessibilityLabel("Уровень тревоги")
                                    .accessibilityValue("\(Int(anxietyBefore)) из 10")
                                    .onChange(of: anxietyBefore) { _, _ in
                                        let generator = UISelectionFeedbackGenerator()
                                        generator.selectionChanged()
                                    }
                                
                                HStack {
                                    Text("0\nНет тревоги")
                                        .font(.caption2)
                                        .multilineTextAlignment(.leading)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text("5\nСредний\nуровень")
                                        .font(.caption2)
                                        .multilineTextAlignment(.center)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text("10\nМаксимум")
                                        .font(.caption2)
                                        .multilineTextAlignment(.trailing)
                                        .foregroundStyle(.secondary)
                                }
                                .accessibilityHidden(true)
                            }
                            
                            Text(anxietyDescription(for: Int(anxietyBefore)))
                                .font(.callout)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                                .background(Color(.tertiarySystemGroupedBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                .accessibilityLabel("Описание уровня тревоги: \(anxietyDescription(for: Int(anxietyBefore)))")
                        }
                        .padding(20)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .padding(.horizontal, 20)
    }
    
    private var startSessionButton: some View {
        Button {
                    startSession()
                } label: {
                    Label("Начать сеанс", systemImage: "play.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .controlSize(.large)
                .disabled(selectedExposure == nil)
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
                .accessibilityHint(selectedExposure == nil ? "Сначала выберите экспозицию" : "Начать сеанс с экспозицией \(selectedExposure?.title ?? "")")
    }
    
    // MARK: - Helper Views
    
    private func exposureCard(_ exposure: Exposure) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exposure.title)
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    Text(exposure.exposureDescription)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                Spacer()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.blue.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.blue.opacity(0.3), lineWidth: 1.5)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Выбранная экспозиция: \(exposure.title). \(exposure.exposureDescription)")
    }
    
    // MARK: - Helper Functions
    
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
    
    private func anxietyDescription(for value: Int) -> String {
        switch value {
        case 0:
            return "Полное спокойствие, нет тревоги"
        case 1...2:
            return "Очень низкий уровень тревоги"
        case 3...4:
            return "Легкая тревога, управляемая"
        case 5...6:
            return "Средний уровень тревоги, заметный дискомфорт"
        case 7...8:
            return "Высокая тревога, значительный дистресс"
        case 9:
            return "Очень высокая тревога, трудно терпеть"
        case 10:
            return "Экстремальная тревога, паника"
        default:
            return ""
        }
    }
    
    private func startSession() {
        guard let exposure = selectedExposure else { return }
        
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        do {
            let session = try dataManager.createSessionResult(
                for: exposure,
                anxietyBefore: Int(anxietyBefore)
            )
            currentSession = session
            showingActiveSession = true
        } catch {
            let errorGenerator = UINotificationFeedbackGenerator()
            errorGenerator.notificationOccurred(.error)
            
            errorMessage = "Не удалось создать сеанс: \(error.localizedDescription)"
            showError = true
        }
    }
}

// MARK: - Custom Label Style

struct TrailingIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.title
            configuration.icon
        }
    }
}

extension LabelStyle where Self == TrailingIconLabelStyle {
    static var trailingIcon: TrailingIconLabelStyle { TrailingIconLabelStyle() }
}

// MARK: - Preview

#Preview {
    SessionView()
        .modelContainer(for: Exposure.self, inMemory: true)
}
