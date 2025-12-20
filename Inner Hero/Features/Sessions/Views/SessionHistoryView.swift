import SwiftUI
import SwiftData

struct SessionHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    let exposure: Exposure
    
    @State private var sessions: [ExposureSessionResult] = []
    @State private var errorMessage: String?
    @State private var showingError = false
    
    private var completedSessions: [ExposureSessionResult] {
        sessions.filter { $0.endAt != nil }
    }
    
    private var chartDataPoints: [ChartDataPoint] {
        completedSessions.map { session in
            ChartDataPoint(
                id: session.id,
                date: session.startAt,
                anxietyBefore: session.anxietyBefore,
                anxietyAfter: session.anxietyAfter
            )
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                if !completedSessions.isEmpty {
                    // Progress Chart
                    ExposureProgressChart(dataPoints: chartDataPoints)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 24)
                }
                
                // Session List
                if sessions.isEmpty {
                    emptyStateView
                        .padding(.top, 60)
                } else {
                    VStack(spacing: 0) {
                        ForEach(sessions) { session in
                            NavigationLink(destination: SessionDetailView(session: session)) {
                                SessionHistoryRowView(session: session)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                            }
                            .buttonStyle(.plain)
                            
                            if session.id != sessions.last?.id {
                                Divider()
                                    .padding(.leading, 20)
                            }
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(uiColor: .secondarySystemGroupedBackground))
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
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
        .navigationTitle("История сеансов")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadSessions()
        }
        .alert("Ошибка", isPresented: $showingError) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.body)
            }
        }
    }
    
    private var emptyStateView: some View {
        ContentUnavailableView(
            "Нет сеансов",
            systemImage: "clock.badge.xmark",
            description: Text("История сеансов для этой экспозиции пуста")
                .font(.body)
        )
    }
    
    private func loadSessions() {
        let dataManager = DataManager(modelContext: modelContext)
        do {
            sessions = try dataManager.fetchSessionResults(for: exposure)
        } catch {
            errorMessage = "Не удалось загрузить сеансы: \(error.localizedDescription)"
            showingError = true
        }
    }
}

// MARK: - Previews

#Preview("Session History") {
    NavigationStack {
        SessionHistoryView(exposure: Exposure(
            title: "Тестовая экспозиция",
            exposureDescription: "Описание"
        ))
    }
    .modelContainer(for: [Exposure.self, ExposureSessionResult.self], inMemory: true)
}
