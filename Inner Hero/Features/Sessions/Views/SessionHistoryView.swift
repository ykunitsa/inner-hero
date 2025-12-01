import SwiftUI
import SwiftData

struct SessionHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    let exposure: Exposure
    
    @State private var sessions: [SessionResult] = []
    @State private var errorMessage: String?
    @State private var showingError = false
    
    var body: some View {
        Group {
            if sessions.isEmpty {
                ContentUnavailableView(
                    "Нет сеансов",
                    systemImage: "clock.badge.xmark",
                    description: Text("История сеансов для этой экспозиции пуста")
                        .font(.body)
                )
            } else {
                List {
                    ForEach(sessions) { session in
                        NavigationLink(destination: SessionDetailView(session: session)) {
                            SessionHistoryRowView(session: session)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
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
    .modelContainer(for: [Exposure.self, SessionResult.self], inMemory: true)
}
