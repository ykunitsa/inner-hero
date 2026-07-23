import SwiftUI

struct AppLockGateView<Content: View>: View {
    @AppStorage(AppStorageKeys.appLockEnabled) private var appLockEnabled: Bool = false
    
    @State private var lockManager = AppLockManager()
    
    private let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            content
                .opacity(isBlocked ? 0 : 1)
                .disabled(isBlocked)
            
            if isBlocked {
                LockedOverlay(
                    errorMessage: lockManager.lastErrorMessage,
                    onUnlock: { Task { await lockManager.unlockIfPossible(reason: String(localized: "Unlock Inner Hero")) } }
                )
                .transition(.opacity)
            }
        }
        .animation(.default, value: isBlocked)
        // The gate hides its content with opacity rather than removing it, and a
        // sheet or cover presented from inside would appear *above* the overlay —
        // so an external deep link must be able to see the lock and wait for it
        // (§11.7).
        .environment(\.isAppLocked, isBlocked)
        .task {
            await ensureUnlockedIfNeeded()
        }
        .onChange(of: appLockEnabled) { _, _ in
            Task { await ensureUnlockedIfNeeded() }
        }
    }
    
    private var isBlocked: Bool {
        appLockEnabled && !lockManager.isUnlocked
    }
    
    private func ensureUnlockedIfNeeded() async {
        if lockManager.shouldRequireUnlockAtLaunch(enabled: appLockEnabled) {
            lockManager.isUnlocked = false
            await lockManager.unlockIfPossible(reason: String(localized: "Unlock Inner Hero"))
            return
        }
        
        lockManager.isUnlocked = true
    }
}

// MARK: - Environment

private struct IsAppLockedKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    /// Whether the lock overlay is currently covering the app. Read by anything that
    /// would otherwise present over it.
    var isAppLocked: Bool {
        get { self[IsAppLockedKey.self] }
        set { self[IsAppLockedKey.self] = newValue }
    }
}

private struct LockedOverlay: View {
    let errorMessage: String?
    let onUnlock: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            
            Text("App locked")
                .font(.title3.weight(.semibold))
            
            if let errorMessage, !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                Text("Verify your identity to continue.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(String(localized: "Unlock")) {
                onUnlock()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .background(.ultraThinMaterial)
    }
}


