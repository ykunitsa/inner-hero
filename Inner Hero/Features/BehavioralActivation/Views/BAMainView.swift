import SwiftUI
import SwiftData

// MARK: - BATab

enum BATab: String, CaseIterable {
    case today   = "today"
    case library = "library"
}

// MARK: - BAMainView

struct BAMainView: View {
    @AppStorage("ba.selectedTab") private var selectedTabRaw: String = BATab.today.rawValue

    @State private var showingCreatePlanSheet = false
    @State private var appeared = false
    @State private var selectedActiveSession: BASession?

    private var selectedTab: BATab {
        get { BATab(rawValue: selectedTabRaw) ?? .today }
    }

    private func setTab(_ tab: BATab) {
        selectedTabRaw = tab.rawValue
    }

    var body: some View {
        VStack(spacing: 0) {
            // Segmented picker
            Picker(String(localized: "Section"), selection: Binding(
                get: { selectedTab },
                set: { setTab($0) }
            )) {
                Text(String(localized: "Today")).tag(BATab.today)
                Text(String(localized: "Library")).tag(BATab.library)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)

            // Tab content
            ZStack {
                if selectedTab == .today {
                    BATodayView(onActiveSessionTap: { session in
                        selectedActiveSession = session
                    })
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 12)
                    .animation(AppAnimation.appear, value: appeared)
                    .transition(.opacity)
                } else {
                    BALibraryView()
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 12)
                        .animation(AppAnimation.appear, value: appeared)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: selectedTab)
        }
        .homeBackground()
        .navigationTitle(String(localized: "Behavioral activation"))
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingCreatePlanSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingCreatePlanSheet) {
            CreateBAPlanSheet()
        }
        .navigationDestination(item: $selectedActiveSession) { session in
            BAActiveSessionView(session: session)
        }
        .onAppear { appeared = true }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        BAMainView()
    }
    .modelContainer(for: [BASession.self, BAActivity.self], inMemory: true)
}
