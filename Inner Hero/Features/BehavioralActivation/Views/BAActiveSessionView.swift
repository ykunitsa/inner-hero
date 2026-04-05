import SwiftUI

struct BAActiveSessionView: View {
    let session: BASession

    @State private var showingCompletion = false

    private static let motivationalQuotes = [
        "Action doesn't require motivation to begin.",
        "You're already doing it.",
        "Just keep going.",
        "Small steps break the cycle.",
        "Every moment you show up counts."
    ]

    private let quote: String

    init(session: BASession) {
        self.session = session
        self.quote = Self.motivationalQuotes.randomElement() ?? "Just keep going."
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: Spacing.lg) {
                Text(session.activity?.localizedTitle ?? "Activity")
                    .appFont(.h1)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(TextColors.primary)
                    .padding(.horizontal, Spacing.lg)

                TimelineView(.periodic(from: .now, by: 1.0)) { context in
                    let elapsed = context.date.timeIntervalSince(session.startedAt ?? context.date)
                    Text(formatElapsed(elapsed))
                        .appFont(.monoLarge)
                        .monospacedDigit()
                        .foregroundStyle(TextColors.secondary)
                }
                .accessibilityLabel("Elapsed time")
            }

            Spacer()

            Text(quote)
                .appFont(.bodyLarge)
                .multilineTextAlignment(.center)
                .foregroundStyle(TextColors.tertiary)
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, Spacing.xxl)

            PrimaryButton(title: "Complete") {
                showingCompletion = true
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.lg)
        }
        .homeBackground()
        .navigationTitle("In progress")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .sheet(isPresented: $showingCompletion) {
            BACompletionSheet(session: session)
        }
    }

    private func formatElapsed(_ interval: TimeInterval) -> String {
        let totalSeconds = max(0, Int(interval))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
