import SwiftUI
import SwiftData

struct ExposuresListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Exposure.createdAt, order: .reverse) private var exposures: [Exposure]
    @Query(sort: \ExposureSessionResult.startAt, order: .reverse) private var allSessions: [ExposureSessionResult]
    @Query(sort: \ExerciseAssignment.createdAt) private var allAssignments: [ExerciseAssignment]
    @Query(sort: \FavoriteExercise.createdAt, order: .reverse) private var favorites: [FavoriteExercise]
    
    @State private var showingCreateSheet = false
    @State private var exposureToDelete: Exposure?
    @State private var showingDeleteAlert = false
    @State private var exposureToStart: Exposure?
    @State private var currentSession: ExposureSessionResult?
    @State private var exposureToSchedule: Exposure?
    @State private var appeared = false
    
    private var activeSessions: [ExposureSessionResult] {
        allSessions.filter { $0.endAt == nil }
    }
    
    private var pinnedExposures: [Exposure] {
        let exposureById: [UUID: Exposure] = Dictionary(uniqueKeysWithValues: exposures.map { ($0.id, $0) })
        var seen = Set<UUID>()
        
        return favorites
            .filter { $0.exerciseType == .exposure }
            .compactMap { $0.exerciseId }
            .compactMap { id in
                guard seen.insert(id).inserted else { return nil }
                return exposureById[id]
            }
    }
    
    private var pinnedExposureIDs: Set<UUID> {
        Set(pinnedExposures.map(\.id))
    }
    
    private var userCreatedExposures: [Exposure] {
        exposures.filter { !pinnedExposureIDs.contains($0.id) && $0.isPredefined == false }
    }
    
    private var predefinedExposures: [Exposure] {
        exposures.filter { !pinnedExposureIDs.contains($0.id) && $0.isPredefined == true }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 24) {
                    if let activeSession = activeSessions.first,
                       let exposure = activeSession.exposure {
                        ActiveSessionCard(session: activeSession, exposure: exposure) {
                            currentSession = activeSession
                        }
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    if exposures.isEmpty {
                        emptyStateView
                    } else {
                        exposuresSections
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 40)
            }
            .background(TopMeshGradientBackground())
            .navigationTitle("Экспозиции")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingCreateSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.headline)
                            .foregroundStyle(TextColors.toolbar)
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
            .sheet(item: $exposureToSchedule) { exposure in
                ScheduleExerciseView(preSelectedExposureId: exposure.id)
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
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue.opacity(0.6), .cyan.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .accessibilityHidden(true)
            
            VStack(spacing: 12) {
                Text("Начните свой путь")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(TextColors.primary)
                
                Text("Создайте первую экспозицию для работы с тревогой")
                    .font(.body)
                    .foregroundStyle(TextColors.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 80)
        .accessibilityElement(children: .combine)
    }
    
    private var exposuresSections: some View {
        VStack(alignment: .leading, spacing: 24) {
            if !pinnedExposures.isEmpty {
                exposuresSection(title: "Закреплённые", exposures: pinnedExposures)
            }
            
            if !userCreatedExposures.isEmpty {
                exposuresSection(title: "Созданные мной", exposures: userCreatedExposures)
            }
            
            if !predefinedExposures.isEmpty {
                exposuresSection(title: "Предустановленные", exposures: predefinedExposures)
            }
        }
    }
    
    private func exposuresSection(title: String, exposures: [Exposure]) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(TextColors.secondary)
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
        let assignment = allAssignments.first { assignment in
            assignment.exerciseType == .exposure && assignment.exposureId == exposure.id
        }
        
        return NavigationLink(destination: ExposureDetailView(exposure: exposure, onStartSession: {
            startSession(for: exposure)
        })) {
            ExposureCardView(
                exposure: exposure,
                assignment: assignment
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                startSession(for: exposure)
            } label: {
                Label("Начать сеанс", systemImage: "play.fill")
            }
            
            Button {
                exposureToSchedule = exposure
            } label: {
                Label(
                    assignment?.isActive == true ? "Редактировать расписание" : "Создать расписание",
                    systemImage: "calendar"
                )
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
