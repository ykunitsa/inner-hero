import SwiftUI

struct MinutesWidget: View {
    let todayMinutes: Int
    let weekMinutes: Int
    
    var body: some View {
        WidgetCard(minHeight: 120) {
            VStack(alignment: .leading, spacing: 10) {
                Label("Practice minutes", systemImage: "timer")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.teal)
                
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("\(todayMinutes)")
                        .font(.system(.title, design: .rounded).weight(.semibold))
                        .foregroundStyle(.primary)
                        .monospacedDigit()
                    Text("min")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                
                Text(String(format: NSLocalizedString("In 7 days: %d min", comment: ""), weekMinutes))
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Practice minutes")
        .accessibilityValue(
            String(
                format: NSLocalizedString("Today %1$d minutes. In 7 days %2$d minutes.", comment: ""),
                todayMinutes,
                weekMinutes
            )
        )
    }
}

