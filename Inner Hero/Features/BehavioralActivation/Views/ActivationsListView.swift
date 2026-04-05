import SwiftUI

// MARK: - BATab

enum BATab: String {
    case today
    case library
}

// MARK: - BAMainView

struct BAMainView: View {
    @AppStorage("ba.selectedTab") private var selectedTab: BATab = .today
    @State private var showingCreatePlanSheet = false
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            tabPicker
            tabContent
        }
        .homeBackground()
        .navigationTitle(String(localized: "Behavioral activation"))
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingCreatePlanSheet = true } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(TextColors.toolbar)
                }
                .touchTarget()
                .accessibilityLabel(String(localized: "Create plan"))
            }
        }
        .sheet(isPresented: $showingCreatePlanSheet) {
            CreateBAPlanSheet()
        }
        .opacity(appeared ? 1 : 0)
        .animation(AppAnimation.appear, value: appeared)
        .onAppear { appeared = true }
    }

    // MARK: - Subviews

    private var tabPicker: some View {
        Picker(String(localized: "Tab"), selection: $selectedTab) {
            Text(String(localized: "Today")).tag(BATab.today)
            Text(String(localized: "Library")).tag(BATab.library)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
    }

    @ViewBuilder
    private var tabContent: some View {
        ZStack {
            switch selectedTab {
            case .today:
                BATodayView()
            case .library:
                BALibraryView()
            }
        }
        .animation(.easeInOut(duration: 0.2), value: selectedTab)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    NavigationStack {
        BAMainView()
    }
}
