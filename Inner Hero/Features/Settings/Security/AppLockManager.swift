import Foundation
import LocalAuthentication

@MainActor
@Observable
final class AppLockManager {
    var isUnlocked: Bool = true
    var lastSuccessfulUnlockAt: Date?
    var lastErrorMessage: String?
    
    func shouldRequireUnlockAtLaunch(enabled: Bool) -> Bool {
        guard enabled else { return false }
        return lastSuccessfulUnlockAt == nil
    }
    
    func unlockIfPossible(reason: String) async {
        lastErrorMessage = nil
        
        let context = LAContext()
        context.localizedCancelTitle = String(localized: "Отмена")
        
        var error: NSError?
        let canEvaluate = context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
        
        guard canEvaluate else {
            isUnlocked = false
            lastErrorMessage = String(localized: "Проверка устройства недоступна.")
            return
        }
        
        do {
            let success = try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
            if success {
                isUnlocked = true
                lastSuccessfulUnlockAt = Date()
            } else {
                isUnlocked = false
                lastErrorMessage = String(localized: "Не удалось подтвердить личность.")
            }
        } catch {
            isUnlocked = false
            lastErrorMessage = String(
                format: NSLocalizedString("Ошибка проверки: %@", comment: ""),
                error.localizedDescription
            )
        }
    }
}
