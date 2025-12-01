import SwiftUI
import SwiftData

struct ActiveSessionCard: View {
    let session: SessionResult
    let exposure: Exposure
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 16) {
                header
                content
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.teal.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Продолжить активный сеанс: \(exposure.title)")
        .accessibilityHint("Дважды нажмите, чтобы возобновить сеанс")
    }
    
    private var header: some View {
        HStack {
            Image(systemName: "circle.fill")
                .font(.caption)
                .foregroundStyle(.green)
                .accessibilityHidden(true)
            
            Text("Активный сеанс")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Image(systemName: "arrow.right.circle.fill")
                .font(.body)
                .foregroundStyle(.teal)
        }
    }
    
    private var content: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(exposure.title)
                .font(.title2.weight(.semibold))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
            
            HStack(spacing: 16) {
                Label {
                    Text(session.startAt, style: .relative)
                        .font(.body)
                        .foregroundStyle(.secondary)
                } icon: {
                    Image(systemName: "clock")
                        .font(.body)
                        .foregroundStyle(.teal)
                }
                
                if !exposure.steps.isEmpty {
                    Label {
                        Text("\(session.completedStepIndices.count)/\(exposure.steps.count)")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    } icon: {
                        Image(systemName: "checkmark.circle")
                            .font(.body)
                            .foregroundStyle(.teal)
                    }
                }
            }
            .accessibilityElement(children: .combine)
        }
    }
}
