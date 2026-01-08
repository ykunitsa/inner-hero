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
                    onUnlock: { Task { await lockManager.unlockIfPossible(reason: "Разблокировать Inner Hero") } }
                )
                .transition(.opacity)
            }
        }
        .animation(.default, value: isBlocked)
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
            await lockManager.unlockIfPossible(reason: "Разблокировать Inner Hero")
            return
        }
        
        lockManager.isUnlocked = true
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
            
            Text("Приложение заблокировано")
                .font(.title3.weight(.semibold))
            
            if let errorMessage, !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                Text("Подтвердите личность, чтобы продолжить.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("Разблокировать") {
                onUnlock()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .background(.ultraThinMaterial)
    }
}


