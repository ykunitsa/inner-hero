import SwiftUI
import SwiftData

struct BreathingSessionHistoryView: View {
    let patternType: BreathingPatternType
    let title: String
    
    @Query(sort: \BreathingSessionResult.performedAt, order: .reverse) private var allSessions: [BreathingSessionResult]
    
    private var sessions: [BreathingSessionResult] {
        allSessions.filter { $0.patternType == patternType }
    }
    
    var body: some View {
        Group {
            if sessions.isEmpty {
                ContentUnavailableView(
                    "No sessions",
                    systemImage: "clock.badge.xmark",
                    description: Text("Session history for \"\(title)\" is empty")
                )
                .padding(.top, 60)
            } else {
                List {
                    ForEach(sessions) { session in
                        BreathingSessionHistoryRowView(session: session)
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
        }
        .background(TopMeshGradientBackground(palette: .teal))
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct BreathingSessionHistoryRowView: View {
    let session: BreathingSessionResult
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: session.performedAt)
    }
    
    private var durationText: String {
        let totalSeconds = Int(session.duration.rounded())
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return "\(minutes):\(String(format: "%02d", seconds))"
    }
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(formattedDate)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(TextColors.primary)
                
                HStack(spacing: 6) {
                    Image(systemName: "timer")
                        .font(.caption)
                    Text(durationText)
                        .font(.caption.weight(.medium).monospacedDigit())
                }
                .foregroundStyle(TextColors.secondary)
            }
            
            Spacer(minLength: 0)
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Session: \(formattedDate), duration \(durationText)")
    }
}

#Preview {
    NavigationStack {
        BreathingSessionHistoryView(patternType: .box, title: "Box breathing")
    }
    .modelContainer(for: [BreathingSessionResult.self], inMemory: true)
}


