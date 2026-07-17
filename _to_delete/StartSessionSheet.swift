import SwiftUI
import SwiftData

struct StartSessionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let exposure: Exposure
    let onSessionCreated: (ExposureSessionResult) -> Void
    
    @State private var anxietyBefore: Double = 5
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showGuidance = false
    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical) {
                VStack(spacing: Spacing.xl) {
                    header
                    anxietySliderSection
                    startButton
                    guidanceSection
                }
                .padding(.bottom, Spacing.lg)
            }
            .pageBackground()
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
        VStack(spacing: Spacing.sm) {
            Image(systemName: "figure.mind.and.body")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(AppColors.primary)
                .iconContainer(
                    size: IconSize.hero,
                    backgroundColor: AppColors.primaryLight,
                    cornerRadius: CornerRadius.md
                )
            VStack(spacing: Spacing.xxxs) {
                Text(exposure.localizedTitle)
                    .appFont(.h2)
                    .foregroundStyle(TextColors.primary)
                    .multilineTextAlignment(.center)
                
                Text("Exposure session")
                    .appFont(.small)
                    .foregroundStyle(TextColors.secondary)
            }
        }
        .padding(.top, Spacing.lg)
        .padding(.horizontal, Spacing.lg)
        .safeAreaInset(edge: .top) {
            Color.clear.frame(height: Spacing.xs)
        }
    }
    
    private var guidanceSection: some View {
        DisclosureGroup(isExpanded: $showGuidance) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Exposure is a gentle courage practice: you learn to stay with anxiety and notice that you can be with it—it's unpleasant but bearable. Sometimes anxiety goes down during the step, sometimes later. Both are okay.")
                    .appFont(.body)
                    .foregroundStyle(TextColors.secondary)
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
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
            }
            .padding(.top, Spacing.xxs)
        } label: {
            HStack(spacing: Spacing.xxs) {
                Image(systemName: "sparkles")
                    .font(.system(size: IconSize.glyph, weight: .semibold))
                    .foregroundStyle(AppColors.accent)
                Text("Why this matters")
                    .appFont(.h3)
                    .foregroundStyle(TextColors.primary)
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .cardStyle()
        .padding(.horizontal, Spacing.lg)
    }
    
    private var anxietySliderSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Label("Anxiety level", systemImage: "gauge")
                .appFont(.h3)
                .foregroundStyle(TextColors.primary)
            
            Text("Rate your current anxiety level before the session (0–10). This helps you compare before vs after.")
                .appFont(.body)
                .foregroundStyle(TextColors.secondary)
            
            VStack(spacing: Spacing.md) {
                VStack(spacing: Spacing.xxxs) {
                    Text("\(Int(anxietyBefore))")
                        .appFont(.monoLarge)
                        .monospacedDigit()
                        .foregroundStyle(anxietyAccent(for: Int(anxietyBefore)))
                    Text(anxietyDescription(for: Int(anxietyBefore)))
                        .appFont(.small)
                        .foregroundStyle(TextColors.secondary)
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: Spacing.xxs) {
                    Slider(value: $anxietyBefore, in: 0...10, step: 1)
                        .tint(anxietyAccent(for: Int(anxietyBefore)))
                    
                    HStack {
                        Text("0\n\(String(localized: "No anxiety"))")
                            .appFont(.small)
                            .multilineTextAlignment(.leading)
                            .foregroundStyle(TextColors.secondary)
                        Spacer()
                        Text("5\n\(String(localized: "Medium"))")
                            .appFont(.small)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(TextColors.secondary)
                        Spacer()
                        Text("10\n\(String(localized: "Maximum"))")
                            .appFont(.small)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(TextColors.secondary)
                    }
                }
            }
            .cardStyle(cornerRadius: CornerRadius.lg, padding: Spacing.lg)
        }
        .padding(.horizontal, Spacing.lg)
    }
    
    private var startButton: some View {
        PrimaryButton(title: "Start session", systemImage: "play.fill", color: AppColors.primary) {
            startSession()
        }
        .padding(.horizontal, Spacing.lg)
        .accessibilityLabel("Start session")
    }
    
    private struct GuidanceTipRow: View {
        let iconSystemName: String
        let text: String
        
        var body: some View {
            HStack(alignment: .top, spacing: Spacing.xxs) {
                Image(systemName: iconSystemName)
                    .font(.system(size: IconSize.glyph))
                    .foregroundStyle(AppColors.gray400)
                    .frame(width: 22, alignment: .center)
                    .padding(.top, 1)
                
                Text(text)
                    .appFont(.small)
                    .foregroundStyle(TextColors.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .accessibilityElement(children: .combine)
        }
    }
    
    private func anxietyAccent(for value: Int) -> Color {
        let clamped = max(0, min(10, value))
        let intensity = 0.35 + (Double(clamped) / 10.0) * 0.65
        return AppColors.accent.opacity(intensity)
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
            let session = ExposureSessionResult(
                exposure: exposure,
                anxietyBefore: Int(anxietyBefore),
                notes: ""
            )
            modelContext.insert(session)
            try modelContext.save()
            dismiss()
            onSessionCreated(session)
        } catch {
            errorMessage = String(format: String(localized: "Failed to create session: %@"), error.localizedDescription)
            showError = true
        }
    }
}
