import SwiftUI

struct MinutesWidget: View {
    let todayMinutes: Int
    let weekMinutes: Int
    
    var body: some View {
        WidgetCard(minHeight: 120) {
            VStack(alignment: .leading, spacing: 10) {
                Label("Минуты практик", systemImage: "timer")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.teal)
                
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("\(todayMinutes)")
                        .font(.system(.title, design: .rounded).weight(.semibold))
                        .foregroundStyle(.primary)
                        .monospacedDigit()
                    Text("мин")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                
                Text("За 7 дней: \(weekMinutes) мин")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Минуты практик")
        .accessibilityValue("Сегодня \(todayMinutes) минут. За 7 дней \(weekMinutes) минут.")
    }
}

