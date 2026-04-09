import SwiftUI

// MARK: - BehavioralActivationRootView
// Placeholder for the new Behavioral Activation feature (INN-45).
// Will be replaced with the full implementation.

struct BehavioralActivationRootView: View {
    var body: some View {
        ContentUnavailableView(
            String(localized: "Behavioral Activation"),
            systemImage: "sparkles",
            description: Text(String(localized: "The new interface is coming soon"))
        )
    }
}

#Preview {
    BehavioralActivationRootView()
}
