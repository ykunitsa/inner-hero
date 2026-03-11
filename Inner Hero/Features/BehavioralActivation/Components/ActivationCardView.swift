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
            Text(activation.localizedTitle)
                .font(.title3.weight(.semibold))
                .foregroundStyle(TextColors.primary)
                .multilineTextAlignment(.leading)
            
            if !activation.localizedActivities.isEmpty {
                Text(activation.localizedActivities.prefix(2).joined(separator: ", "))
                    .font(.body)
                    .foregroundStyle(TextColors.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            } else {
                Text(String(localized: "No activities"))
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
                valueText: activitiesCountText(for: activation.localizedActivities.count)
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
        let form = pluralForm(for: count)
        let word = String(localized: String.LocalizationValue(form.key))
        return "\(count) \(word)"
    }
    
    private enum PluralForm {
        case one
        case few
        case many
        
        var key: String {
            switch self {
                case .one: return "activity"
                case .few: return "activities_few"
                case .many: return "activities"
            }
        }
    }
    
    /// One form for all locales: EN has "activities" for few/many; RU uses all three forms.
    private func pluralForm(for number: Int) -> PluralForm {
        let n = abs(number) % 100
        let n1 = n % 10
        if (11...14).contains(n) { return .many }
        switch n1 {
            case 1: return .one
            case 2, 3, 4: return .few
            default: return .many
        }
    }
}
