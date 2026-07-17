import SwiftUI
import SwiftData

struct SessionHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    let exposure: Exposure

    @State private var viewModel = SessionHistoryViewModel()

    private var completedSessions: [ExposureSessionResult] {
        viewModel.sessions.filter { $0.endAt != nil }
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
        @Bindable var vm = viewModel
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
                if viewModel.sessions.isEmpty {
                    emptyStateView
                        .padding(.top, 60)
                } else {
                    VStack(spacing: 0) {
                        ForEach(viewModel.sessions) { session in
                            NavigationLink(value: AppRoute.sessionDetail(sessionId: session.id)) {
                                SessionHistoryRowView(session: session)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                            }
                            .buttonStyle(.plain)

                            if session.id != viewModel.sessions.last?.id {
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
        .navigationTitle("Session history")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadSessions(exposure: exposure, context: modelContext)
        }
        .alert("Error", isPresented: $vm.showingError) {
            Button("OK") {
                vm.errorMessage = nil
                vm.showingError = false
            }
        } message: {
            if let errorMessage = vm.errorMessage {
                Text(errorMessage)
                    .font(.body)
            }
        }
    }

    private var emptyStateView: some View {
        ContentUnavailableView(
            "No sessions",
            systemImage: "clock.badge.xmark",
            description: Text("Session history for this exposure is empty")
                .font(.body)
        )
    }
}

// MARK: - Previews

#Preview("Session History") {
    NavigationStack {
        SessionHistoryView(exposure: Exposure(
            title: "Test exposure",
            exposureDescription: "Description"
        ))
    }
    .modelContainer(for: [Exposure.self, ExposureSessionResult.self], inMemory: true)
}
