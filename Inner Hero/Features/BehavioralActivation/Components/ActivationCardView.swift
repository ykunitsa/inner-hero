import SwiftUI
import SwiftData

struct ActivationCardView: View {
    let activation: ActivityList
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            Divider().background(Color(.separator))
            metadataRow
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
    }
    
    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text(activation.title)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(TextColors.primary)
                        .multilineTextAlignment(.leading)
                    
                    if activation.isPredefined {
                        Text("Built-in")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(TextColors.tertiary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color(.systemGray6))
                            )
                    }
                }
                
                if !activation.activities.isEmpty {
                    Text(activation.activities.prefix(2).joined(separator: ", "))
                        .font(.body)
                        .foregroundStyle(TextColors.secondary)
                        .lineLimit(1)
                        .multilineTextAlignment(.leading)
                }
            }
            
            Spacer(minLength: 12)
            
            Image(systemName: "chevron.right")
                .font(.body)
                .foregroundStyle(TextColors.tertiary)
        }
    }
    
    private var metadataRow: some View {
        HStack(spacing: 6) {
            Image(systemName: "list.bullet")
                .font(.caption)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.green, .mint],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Text("\(activation.activities.count) activities")
                .font(.caption)
                .foregroundStyle(TextColors.secondary)
            
            Spacer()
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    ActivationCardView(
        activation: ActivityList(
            title: "Morning Routine",
            activities: ["Exercise", "Meditation", "Healthy Breakfast"],
            isPredefined: false
        )
    )
    .padding()
}

