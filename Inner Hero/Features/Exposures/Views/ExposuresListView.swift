import SwiftUI
import SwiftData

struct ExposuresListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Exposure.createdAt, order: .reverse) private var exposures: [Exposure]
    @Query(sort: \SessionResult.startAt, order: .reverse) private var allSessions: [SessionResult]
    
    @State private var showingCreateSheet = false
    @State private var exposureToDelete: Exposure?
    @State private var showingDeleteAlert = false
    @State private var exposureToStart: Exposure?
    @State private var currentSession: SessionResult?
    @State private var appeared = false
    
    private var activeSessions: [SessionResult] {
        allSessions.filter { $0.endAt == nil }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 24) {
                    if let activeSession = activeSessions.first,
                       let exposure = activeSession.exposure {
                        ActiveSessionCard(session: activeSession, exposure: exposure) {
                            currentSession = activeSession
                            exposureToStart = exposure
                        }
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    if exposures.isEmpty {
                        emptyStateView
                    } else {
                        exposuresSection
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 40)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Экспозиции")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingCreateSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.headline)
                    }
                    .accessibilityLabel("Добавить экспозицию")
                }
            }
            .sheet(isPresented: $showingCreateSheet) {
                CreateExposureView()
            }
            .sheet(item: $exposureToStart) { exposure in
                StartSessionSheet(exposure: exposure) { session in
                    currentSession = session
                }
            }
            .navigationDestination(item: $currentSession) { session in
                if let exposure = session.exposure {
                    ActiveSessionView(session: session, exposure: exposure)
                }
            }
            .alert("Удалить экспозицию?", isPresented: $showingDeleteAlert, presenting: exposureToDelete) { exposure in
                Button("Отмена", role: .cancel) {
                    exposureToDelete = nil
                }
                Button("Удалить", role: .destructive) {
                    deleteExposure(exposure)
                }
            } message: { exposure in
                Text("Вы уверены, что хотите удалить экспозицию \"\(exposure.title)\"? Это действие нельзя отменить.")
            }
            .opacity(appeared ? 1 : 0)
            .animation(.easeIn(duration: 0.3), value: appeared)
            .onAppear {
                appeared = true
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "leaf.circle")
                .font(.system(size: 72))
                .foregroundStyle(.teal.opacity(0.6))
                .accessibilityHidden(true)
            
            VStack(spacing: 12) {
                Text("Начните свой путь")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.primary)
                
                Text("Создайте первую экспозицию для работы с тревогой")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 80)
        .accessibilityElement(children: .combine)
    }
    
    private var exposuresSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Мои экспозиции")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .padding(.leading, 4)
            
            VStack(spacing: 16) {
                ForEach(Array(exposures.enumerated()), id: \.element.id) { index, exposure in
                    exposureCard(exposure: exposure)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                        .animation(.easeOut(duration: 0.3).delay(Double(index) * 0.05), value: appeared)
                }
            }
        }
    }
    
    private func exposureCard(exposure: Exposure) -> some View {
        NavigationLink(destination: ExposureDetailView(exposure: exposure, onStartSession: {
            startSession(for: exposure)
        })) {
            ExposureCardView(exposure: exposure) {
                startSession(for: exposure)
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                startSession(for: exposure)
            } label: {
                Label("Начать сеанс", systemImage: "play.fill")
            }
            
            Button(role: .destructive) {
                exposureToDelete = exposure
                showingDeleteAlert = true
            } label: {
                Label("Удалить", systemImage: "trash")
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(exposure.title). \(exposure.steps.count) шагов, \(exposure.sessionResults.count) сеансов")
        .accessibilityHint("Дважды нажмите для просмотра деталей")
    }
    
    private func startSession(for exposure: Exposure) {
        exposureToStart = exposure
    }
    
    private func deleteExposure(_ exposure: Exposure) {
        withAnimation(.easeInOut(duration: 0.3)) {
            modelContext.delete(exposure)
            exposureToDelete = nil
        }
    }
}

#Preview {
    ExposuresListView()
        .modelContainer(for: Exposure.self, inMemory: true)
}
