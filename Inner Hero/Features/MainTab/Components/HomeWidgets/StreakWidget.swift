import SwiftUI

struct StreakWidget: View {
    let streakDays: Int
    
    private var dayCountText: String {
        String.localizedStringWithFormat(
            NSLocalizedString("streak.days.count", comment: ""),
            streakDays
        )
    }
    
    var body: some View {
        WidgetCard(minHeight: 120) {
            VStack(alignment: .leading, spacing: 10) {
                Label("Серия", systemImage: "flame.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.orange)
                
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("\(streakDays)")
                        .font(.system(.title, design: .rounded).weight(.semibold))
                        .foregroundStyle(.primary)
                        .monospacedDigit()
                    Text(dayCountText)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                
                Text(streakDays == 0 ? "Начните сегодня" : "Продолжайте в том же духе")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

