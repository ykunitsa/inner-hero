import SwiftUI
import SwiftData

struct StartSessionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    
    let exposure: Exposure
    let onSessionCreated: (ExposureSessionResult) -> Void
    
    @State private var anxietyBefore: Double = 5
    @State private var showError = false
    @State private var errorMessage = ""
    
    private var dataManager: DataManager {
        DataManager(modelContext: modelContext)
    }
    
    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                ScrollView(.vertical) {
                    VStack(spacing: 32) {
                        header
                        anxietySliderSection
                        guidanceSection
                        startButton
                    }
                    .frame(width: proxy.size.width)
                    .padding(.bottom, 20)
                }
                .background(.background)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(TextColors.toolbar)
                }
            }
            .alert(String(localized: "Error"), isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private var header: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.mind.and.body")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .cyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            VStack(spacing: 6) {
                Text(exposure.localizedTitle)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(TextColors.primary)
                    .multilineTextAlignment(.center)
                
                Text("Exposure session")
                    .font(.body)
                    .foregroundStyle(TextColors.secondary)
            }
        }
        .padding(.top, 20)
        .padding(.horizontal, 20)
    }
    
    private var guidanceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("You've got this", systemImage: "sparkles")
                .font(.headline)
                .foregroundStyle(TextColors.primary)
            
            Text("Exposure is a gentle courage practice: you learn to stay with anxiety and notice that you can be with it—it's unpleasant but bearable. Sometimes anxiety goes down during the step, sometimes later. Both are okay.")
                .font(.body)
                .foregroundStyle(TextColors.secondary)
            
            VStack(alignment: .leading, spacing: 12) {
                GuidanceTipRow(
                    iconSystemName: "figure.walk",
                    text: String(localized: "Start with a manageable step and progress gradually.")
                )
                
                GuidanceTipRow(
                    iconSystemName: "timer",
                    text: String(localized: "If anxiety stays high, it doesn’t mean you’re failing. Try to stay with it and notice: the wave of anxiety can shift, come and go.")
                )
                
                GuidanceTipRow(
                    iconSystemName: "checkmark.seal",
                    text: String(localized: "Notice avoidance and safety behaviors without judgment. When you can, gently return to the step.")
                )
            }
            .font(.subheadline)
            .foregroundStyle(TextColors.secondary)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.thinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(cardBorderColor, lineWidth: 1)
                )
                .shadow(
                    color: .black.opacity(colorScheme == .dark ? 0.35 : 0.06),
                    radius: 10,
                    x: 0,
                    y: 4
                )
        )
        .padding(.horizontal, 20)
        .accessibilityElement(children: .combine)
    }
    
    private var anxietySliderSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Label("Anxiety level", systemImage: "gauge")
                .font(.headline)
                .foregroundStyle(TextColors.primary)
            
            Text("Rate your current anxiety level before the session (0–10)")
                .font(.body)
                .foregroundStyle(TextColors.secondary)
            
            VStack(spacing: 20) {
                HStack {
                    Spacer()
                    Text("\(Int(anxietyBefore))")
                        .font(.system(.largeTitle, design: .rounded))
                        .fontWeight(.bold)
                        .monospacedDigit()
                        .foregroundStyle(anxietyColor(for: Int(anxietyBefore)))
                    Spacer()
                }
                
                VStack(spacing: 8) {
                    Slider(value: $anxietyBefore, in: 0...10, step: 1)
                        .tint(anxietyColor(for: Int(anxietyBefore)))
                    
                    HStack {
                        Text("0\n\(String(localized: "No anxiety"))")
                            .font(.caption)
                            .multilineTextAlignment(.leading)
                            .foregroundStyle(TextColors.secondary)
                        Spacer()
                        Text("5\n\(String(localized: "Medium"))")
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(TextColors.secondary)
                        Spacer()
                        Text("10\n\(String(localized: "Maximum"))")
                            .font(.caption)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(TextColors.secondary)
                    }
                }
                
                Text(anxietyDescription(for: Int(anxietyBefore)))
                    .font(.body)
                    .foregroundStyle(TextColors.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(softCardFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(cardBorderColor, lineWidth: 1)
                    )
            )
        }
        .padding(20)
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
        .padding(.horizontal, 20)
    }
    
    private var startButton: some View {
        Button(action: startSession) {
            HStack(spacing: 8) {
                Image(systemName: "play.fill")
                    .font(.body)
                Text("Start session")
                    .font(.system(size: 17, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
            )
        }
        .padding(.horizontal, 20)
        .accessibilityLabel("Start session")
    }
    
    // MARK: - Helpers
    
    private var softCardFill: AnyShapeStyle {
        if colorScheme == .dark {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.10),
                        Color.white.opacity(0.04)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
        
        return AnyShapeStyle(
            LinearGradient(
                colors: [
                    Color(red: 0.98, green: 0.99, blue: 1.0),
                    Color(red: 0.96, green: 0.97, blue: 0.99)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
    
    private var insetCardFill: AnyShapeStyle {
        if colorScheme == .dark {
            return AnyShapeStyle(Color.white.opacity(0.06))
        }
        
        return AnyShapeStyle(
            LinearGradient(
                colors: [
                    Color(red: 0.98, green: 0.99, blue: 1.0),
                    Color(red: 0.96, green: 0.97, blue: 0.99)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
    
    private var cardBorderColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.10) : Color.black.opacity(0.06)
    }
    
    private var insetBorderColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.05)
    }
    
    private struct GuidanceTipRow: View {
        let iconSystemName: String
        let text: String
        
        var body: some View {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: iconSystemName)
                    .frame(width: 22, alignment: .center)
                    .padding(.top, 1)
                
                Text(text)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .accessibilityElement(children: .combine)
        }
    }
    
    private func anxietyColor(for value: Int) -> Color {
        switch value {
        case 0...3: return .green
        case 4...6: return .orange
        case 7...10: return .red
        default: return .gray
        }
    }
    
    private func anxietyDescription(for value: Int) -> String {
        switch value {
        case 0: return String(localized: "Complete calm, no anxiety")
        case 1...2: return String(localized: "Very low anxiety")
        case 3...4: return String(localized: "Mild anxiety, manageable")
        case 5...6: return String(localized: "Moderate anxiety, noticeable discomfort")
        case 7...8: return String(localized: "High anxiety, significant distress")
        case 9: return String(localized: "Very high anxiety, hard to tolerate")
        case 10: return String(localized: "Extreme anxiety, panic")
        default: return ""
        }
    }
    
    private func startSession() {
        do {
            let session = try dataManager.createSessionResult(
                for: exposure,
                anxietyBefore: Int(anxietyBefore)
            )
            dismiss()
            onSessionCreated(session)
        } catch {
            errorMessage = String(format: String(localized: "Failed to create session: %@"), error.localizedDescription)
            showError = true
        }
    }
}
