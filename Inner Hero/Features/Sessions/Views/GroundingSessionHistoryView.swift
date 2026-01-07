import SwiftUI
import SwiftData

struct GroundingSessionHistoryView: View {
    let type: GroundingType
    let title: String
    
    @Query(sort: \GroundingSessionResult.performedAt, order: .reverse) private var allSessions: [GroundingSessionResult]
    
    private var sessions: [GroundingSessionResult] {
        allSessions.filter { $0.type == type }
    }
    
    var body: some View {
        Group {
            if sessions.isEmpty {
                ContentUnavailableView(
                    "Нет сеансов",
                    systemImage: "clock.badge.xmark",
                    description: Text("История сеансов для \"\(title)\" пуста")
                )
                .padding(.top, 60)
            } else {
                List {
                    ForEach(sessions) { session in
                        GroundingSessionHistoryRowView(session: session)
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
        }
        .background(TopMeshGradientBackground(palette: .purple))
        .navigationTitle("История")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct GroundingSessionHistoryRowView: View {
    let session: GroundingSessionResult
    
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
        .accessibilityLabel("Сеанс: \(formattedDate), длительность \(durationText)")
    }
}

#Preview {
    NavigationStack {
        GroundingSessionHistoryView(type: .fiveFourThreeTwoOne, title: "5-4-3-2-1")
    }
    .modelContainer(for: [GroundingSessionResult.self], inMemory: true)
}


