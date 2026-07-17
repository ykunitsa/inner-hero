import Foundation
import SwiftData

@Observable
@MainActor
final class SessionHistoryViewModel {
    var sessions: [ExposureSessionResult] = []
    var errorMessage: String?
    var showingError = false

    func loadSessions(exposure: Exposure, context: ModelContext) {
        let exposureId = exposure.id
        var descriptor = FetchDescriptor<ExposureSessionResult>(
            predicate: #Predicate<ExposureSessionResult> { result in
                result.exposure?.id == exposureId
            },
            sortBy: [SortDescriptor(\.startAt, order: .reverse)]
        )
        do {
            sessions = try context.fetch(descriptor)
            errorMessage = nil
            showingError = false
        } catch {
            sessions = []
            errorMessage = String(localized: "Failed to load sessions.") + " \(error.localizedDescription)"
            showingError = true
        }
    }
}
