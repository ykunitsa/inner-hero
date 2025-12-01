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
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        )
    }
    
    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                Text(exposure.title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                
                Text(exposure.exposureDescription)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer(minLength: 12)
            
            Image(systemName: "chevron.right")
                .font(.body)
                .foregroundStyle(Color(.tertiaryLabel))
        }
    }
    
    private var metadataRow: some View {
        HStack(spacing: 20) {
            HStack(spacing: 6) {
                Image(systemName: "list.bullet")
                    .font(.caption)
                    .foregroundStyle(.teal)
                Text("\(exposure.steps.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            HStack(spacing: 6) {
                Image(systemName: "chart.bar")
                    .font(.caption)
                    .foregroundStyle(.teal)
                Text("\(exposure.sessionResults.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
                .background(Capsule().fill(Color.teal))
            }
            .buttonStyle(.plain)
            .frame(minHeight: 44)
        }
        .accessibilityElement(children: .combine)
    }
}
