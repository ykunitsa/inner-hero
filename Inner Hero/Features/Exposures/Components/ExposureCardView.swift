import SwiftUI
import SwiftData

struct ExposureCardView: View {
    let exposure: Exposure
    let onStartSession: () -> Void
    
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
                Text(exposure.title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(TextColors.primary)
                    .multilineTextAlignment(.leading)
                
                Text(exposure.exposureDescription)
                    .font(.body)
                    .foregroundStyle(TextColors.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer(minLength: 12)
            
            Image(systemName: "chevron.right")
                .font(.body)
                .foregroundStyle(TextColors.tertiary)
        }
    }
    
    private var metadataRow: some View {
        HStack(spacing: 20) {
            HStack(spacing: 6) {
                Image(systemName: "list.bullet")
                    .font(.caption)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Text("\(exposure.steps.count)")
                    .font(.caption)
                    .foregroundStyle(TextColors.secondary)
            }
            
            HStack(spacing: 6) {
                Image(systemName: "chart.bar")
                    .font(.caption)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Text("\(exposure.sessionResults.count)")
                    .font(.caption)
                    .foregroundStyle(TextColors.secondary)
            }
            
            Spacer()
            
            Button(action: onStartSession) {
                HStack(spacing: 6) {
                    Image(systemName: "play.fill")
                        .font(.caption)
                    Text("Начать")
                        .font(.caption.weight(.medium))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
            }
            .buttonStyle(.plain)
            .frame(minHeight: 44)
        }
        .accessibilityElement(children: .combine)
    }
}
