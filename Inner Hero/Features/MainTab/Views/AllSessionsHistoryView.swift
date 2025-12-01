import SwiftUI
import SwiftData

struct AllSessionsHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SessionResult.startAt, order: .reverse) private var allSessions: [SessionResult]
    
    private var completedSessions: [SessionResult] {
        allSessions.filter { $0.endAt != nil }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if completedSessions.isEmpty {
                    ContentUnavailableView {
                        Label("Нет сеансов", systemImage: "chart.line.uptrend.xyaxis")
                    } description: {
                        Text("Завершите первый сеанс терапии,\nчтобы увидеть историю")
                            .multilineTextAlignment(.center)
                    }
                } else {
                    List {
                        ForEach(completedSessions) { session in
                            NavigationLink(destination: MainTabSessionDetailView(session: session)) {
                                SessionHistoryRowView(session: session)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("История")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}
