import SwiftUI
import SwiftData

struct AllSessionsHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ExposureSessionResult.startAt, order: .reverse) private var allSessions: [ExposureSessionResult]
    
    private var completedSessions: [ExposureSessionResult] {
        allSessions.filter { $0.endAt != nil }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if completedSessions.isEmpty {
                    ContentUnavailableView {
                        Label("No sessions", systemImage: "chart.line.uptrend.xyaxis")
                    } description: {
                        Text("Complete your first therapy session,\nto see history")
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
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}
