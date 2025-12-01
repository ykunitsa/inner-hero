import SwiftUI
import SwiftData

struct SessionHistoryRowView: View {
    let session: SessionResult

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
        return "\(minutes) мин"
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
                    .accessibilityLabel("Дата сеанса: \(formattedDate)")
                
                Spacer()
                
                if let duration = duration {
                    Text(duration)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("Длительность: \(duration)")
                }
            }
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: Layout.contentSpacing) {
                    Text("Уровень до")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(session.anxietyBefore)")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.blue)
                        .monospacedDigit()
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Тревога до сеанса: \(session.anxietyBefore)")
                
                Spacer()
                
                if let anxietyAfter = session.anxietyAfter {
                    VStack(alignment: .trailing, spacing: Layout.contentSpacing) {
                        Text("Уровень после")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(anxietyAfter)")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(
                                anxietyColor(for: anxietyAfter, comparing: session.anxietyBefore)
                            ) // HIG: semantic color для изменения уровня тревоги
                            .monospacedDigit()
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Тревога после сеанса: \(anxietyAfter)")
                    .accessibilityHint(
                        anxietyAfter < session.anxietyBefore 
                            ? "Уровень снизился" 
                            : "Уровень повысился"
                    )
                }
            }
            
            if !session.notes.isEmpty {
                Text(session.notes)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .accessibilityLabel("Заметки: \(session.notes)")
            }
        }
        .padding(.vertical, Layout.verticalPadding)
    }
    
    private var anxietyChange: Int {
        guard let after = session.anxietyAfter else { return 0 }
        return session.anxietyBefore - after
    }
}
