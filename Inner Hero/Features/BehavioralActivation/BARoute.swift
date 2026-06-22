import Foundation

// MARK: - BA Navigation Route

enum BARoute: Hashable {
    /// Pre → Active → Post inside `BASessionFlowView`.
    case sessionFlow(taskId: UUID)
    case sessionDetail(sessionId: UUID)
}
