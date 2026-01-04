import SwiftUI
import SwiftData

struct ActiveSessionCard: View {
    @Environment(\.colorScheme) private var colorScheme

    let session: ExposureSessionResult
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
                    .strokeBorder(
                        LinearGradient(
                            colors: [.blue.opacity(0.3), .cyan.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
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
                .foregroundStyle(TextColors.secondary)
            
            Spacer()
        }
    }
    
    private var content: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(exposure.title)
                .font(.title2.weight(.semibold))
                .foregroundStyle(TextColors.primary)
                .multilineTextAlignment(.leading)
            
            HStack(spacing: 16) {
                Label {
                    Text(session.startAt, style: .relative)
                        .font(.body)
                        .foregroundStyle(TextColors.secondary)
                } icon: {
                    Image(systemName: "clock")
                        .font(.body)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                if !exposure.steps.isEmpty {
                    Label {
                        Text("\(session.completedStepIndices.count)/\(exposure.steps.count)")
                            .font(.body)
                            .foregroundStyle(TextColors.secondary)
                    } icon: {
                        Image(systemName: "checkmark.circle")
                            .font(.body)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .cyan],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                }
            }
            .accessibilityElement(children: .combine)
        }
    }
}
