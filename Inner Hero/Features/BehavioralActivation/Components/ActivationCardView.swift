import SwiftUI
import SwiftData

struct ActivationCardView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    let activation: ActivityList
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            Divider()
            metadataRow
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.thinMaterial)
                .shadow(
                    color: .black.opacity(colorScheme == .dark ? 0.35 : 0.06),
                    radius: 10,
                    x: 0,
                    y: 4
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(.primary.opacity(colorScheme == .dark ? 0.18 : 0.06), lineWidth: 1)
        )
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(activation.title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(TextColors.primary)
                .multilineTextAlignment(.leading)
            
            if !activation.activities.isEmpty {
                Text(activation.activities.prefix(2).joined(separator: ", "))
                    .font(.body)
                    .foregroundStyle(TextColors.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            } else {
                Text("Нет активностей")
                    .font(.body)
                    .foregroundStyle(TextColors.tertiary)
            }
        }
    }
    
    private var metadataRow: some View {
        HStack(spacing: 12) {
            Spacer(minLength: 0)
            
            statItem(
                systemName: "list.bullet",
                valueText: activitiesCountText(for: activation.activities.count)
            )
        }
        .accessibilityElement(children: .combine)
    }
    
    private func statItem(systemName: String, valueText: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: systemName)
                .font(.caption2)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.green, .mint],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Text(valueText)
                .font(.caption2)
                .foregroundStyle(TextColors.secondary)
        }
    }
    
    private func activitiesCountText(for count: Int) -> String {
        "\(count) \(russianPlural(count, one: "активность", few: "активности", many: "активностей"))"
    }
    
    private func russianPlural(_ number: Int, one: String, few: String, many: String) -> String {
        let n = abs(number) % 100
        let n1 = n % 10
        
        if (11...14).contains(n) { return many }
        switch n1 {
        case 1: return one
        case 2, 3, 4: return few
        default: return many
        }
    }
}

#Preview {
    ActivationCardView(
        activation: ActivityList(
            title: "Утренняя рутина",
            activities: ["Разминка", "Медитация", "Полезный завтрак"],
            isPredefined: false
        )
    )
    .padding()
}

