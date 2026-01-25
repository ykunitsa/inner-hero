import SwiftUI

struct StreakWidget: View {
    let streakDays: Int
    
    private var dayWord: String {
        let n = abs(streakDays) % 100
        let n1 = n % 10
        
        if (11...14).contains(n) { return "дней" }
        if n1 == 1 { return "день" }
        if (2...4).contains(n1) { return "дня" }
        return "дней"
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
                    Text(dayWord)
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

