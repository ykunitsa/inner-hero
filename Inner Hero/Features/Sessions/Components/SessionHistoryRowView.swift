import SwiftUI
import SwiftData

struct SessionHistoryRowView: View {
    let session: ExposureSessionResult

    private enum Layout {
        static let rowSpacing: CGFloat = 12
        static let contentSpacing: CGFloat = 8
        static let verticalPadding: CGFloat = 8
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: session.startAt)
    }
    
    private var duration: String? {
        guard let endAt = session.endAt else { return nil }
        let interval = endAt.timeIntervalSince(session.startAt)
        let minutes = Int(interval / 60)
        return String(format: String(localized: "%d min"), minutes)
    }
    
    private func anxietyColor(for level: Int, comparing comparison: Int) -> Color {
        if level < comparison {
            return .green
        } else if level > comparison {
            return .red
        } else {
            return .orange
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Layout.rowSpacing) {
            HStack {
                Label(formattedDate, systemImage: "calendar")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .accessibilityLabel("Session date: \(formattedDate)")
                
                Spacer()
                
                if let duration = duration {
                    Text(duration)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("Duration: \(duration)")
                }
            }
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: Layout.contentSpacing) {
                    Text("Before")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(session.anxietyBefore)")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.blue)
                        .monospacedDigit()
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Anxiety before session: \(session.anxietyBefore)")
                
                Spacer()
                
                if let anxietyAfter = session.anxietyAfter {
                    VStack(alignment: .trailing, spacing: Layout.contentSpacing) {
                        Text("After")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(anxietyAfter)")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(
                                anxietyColor(for: anxietyAfter, comparing: session.anxietyBefore)
                            ) // HIG: semantic color for changing anxiety level
                            .monospacedDigit()
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Anxiety after session: \(anxietyAfter)")
                    .accessibilityHint(
                        anxietyAfter < session.anxietyBefore 
? "Level decreased"
                            : "Level increased"
                    )
                }
            }
            
            if !session.notes.isEmpty {
                Text(session.notes)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .accessibilityLabel("Notes: \(session.notes)")
            }
        }
        .padding(.vertical, Layout.verticalPadding)
    }
    
    private var anxietyChange: Int {
        guard let after = session.anxietyAfter else { return 0 }
        return session.anxietyBefore - after
    }
}
