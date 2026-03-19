import SwiftUI
import SwiftData

// MARK: - Complete Session View

struct CompleteSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let session: ExposureSessionResult
    let notes: String
    let assignment: ExerciseAssignment?
    let onSave: (Int, String) async throws -> Void
    let onComplete: () -> Void
    
    @State private var anxietyAfter: Double = 5
    @State private var finalNotes: String = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isSaving = false
    
    private enum FocusField: Hashable {
        case finalNotes
    }
    
    @FocusState private var focusedField: FocusField?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    sessionSummaryCard
                    
                    praiseCard
                    
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Label("Anxiety level after session", systemImage: "gauge")
                            .appFont(.h3)
                            .foregroundStyle(TextColors.primary)
                        
                        Text("Rate your anxiety level now (0–10)")
                            .appFont(.body)
                            .foregroundStyle(TextColors.secondary)
                        
                        VStack(spacing: Spacing.md) {
                            VStack(spacing: Spacing.xxxs) {
                                Text("\(Int(anxietyAfter))")
                                    .appFont(.monoLarge)
                                    .foregroundStyle(anxietyAccent(for: Int(anxietyAfter)))
                                    .monospacedDigit()
                                Text(anxietyDescription(for: Int(anxietyAfter)))
                                    .appFont(.small)
                                    .foregroundStyle(TextColors.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            
                            Slider(value: $anxietyAfter, in: 0...10, step: 1)
                                .tint(anxietyAccent(for: Int(anxietyAfter)))
                            
                            HStack {
                                Text("0\nNo anxiety")
                                    .appFont(.small)
                                    .multilineTextAlignment(.leading)
                                    .foregroundStyle(TextColors.secondary)
                                Spacer()
                                Text("5\nMedium")
                                    .appFont(.small)
                                    .multilineTextAlignment(.center)
                                    .foregroundStyle(TextColors.secondary)
                                Spacer()
                                Text("10\nMaximum")
                                    .appFont(.small)
                                    .multilineTextAlignment(.trailing)
                                    .foregroundStyle(TextColors.secondary)
                            }
                        }
                        .cardStyle(cornerRadius: CornerRadius.lg, padding: Spacing.lg)
                    }
                    .padding(.horizontal, Spacing.lg)
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel("Anxiety level after session")
                    
                    progressCard
                    
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Label("Describe how you feel", systemImage: "note.text")
                            .appFont(.h3)
                            .foregroundStyle(TextColors.primary)
                        
                        Text("What do you feel now? What thoughts/sensations were there during the session? What helped?")
                            .appFont(.body)
                            .foregroundStyle(TextColors.secondary)
                        
                        AppTextEditor(
                            text: $finalNotes,
                            placeholder: "How do you feel now? What helped?",
                            minHeight: 120
                        )
                        .focused($focusedField, equals: .finalNotes)
                    }
                    .cardStyle()
                    .padding(.horizontal, Spacing.lg)
                }
                .padding(.top, Spacing.lg)
                .padding(.bottom, Spacing.xl)
            }
            .pageBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(TextColors.toolbar)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await completeSession() }
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(TextColors.toolbar)
                    .disabled(isSaving)
                    .accessibilityLabel("Save session result")
                    .accessibilityHint("Double-tap to save and finish")
                }
                
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        focusedField = nil
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
        .onAppear {
            finalNotes = notes
        }
    }
    
    private var praiseCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Label("Well done!", systemImage: "sparkles")
                .appFont(.h3)
                .foregroundStyle(TextColors.primary)
            
            Text("You completed the session—that's already a big step. Even if anxiety was high, you practiced staying with the feelings and moving forward.")
                .appFont(.body)
                .foregroundStyle(TextColors.secondary)
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                PraiseTipRow(
                    iconSystemName: "checkmark.seal",
                    text: "Note any small progress—it adds up."
                )
                
                PraiseTipRow(
                    iconSystemName: "heart.text.square",
                    text: "Write down what helped (breathing, focus on the task, supportive thought)—it will be useful next time."
                )
            }
        }
        .cardStyle()
        .padding(.horizontal, Spacing.lg)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Praise for completing the session")
        .accessibilityHint("Short supportive message and tips")
    }
    
    private var sessionSummaryCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Label("Session results", systemImage: "chart.bar.fill")
                .appFont(.h3)
                .foregroundStyle(TextColors.primary)
            
            HStack(spacing: Spacing.md) {
                VStack(spacing: Spacing.xxxs) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: IconSize.inline, weight: .semibold))
                        .foregroundStyle(AppColors.positive)
                        .accessibilityHidden(true)
                    Text("\(session.completedStepIndices.count)")
                        .appFont(.h2)
                        .foregroundStyle(TextColors.primary)
                    Text("steps")
                        .appFont(.small)
                        .foregroundStyle(TextColors.secondary)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(String(format: String(localized: "%d steps completed"), session.completedStepIndices.count))
                
                Divider()
                
                VStack(spacing: Spacing.xxxs) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: IconSize.inline, weight: .semibold))
                        .foregroundStyle(AppColors.primary)
                        .accessibilityHidden(true)
                    Text(formatTime(session.getTotalStepsTime()))
                        .appFont(.h3)
                        .foregroundStyle(TextColors.primary)
                        .monospacedDigit()
                    Text("time")
                        .appFont(.small)
                        .foregroundStyle(TextColors.secondary)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Completion time: \(formatTime(session.getTotalStepsTime()))")
            }
        }
        .cardStyle()
        .padding(.horizontal, Spacing.lg)
    }
    
    private var progressCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
                .appFont(.h3)
                .foregroundStyle(TextColors.primary)
            
            HStack(spacing: Spacing.md) {
                progressGauge(title: "Before", value: session.anxietyBefore)
                
                Divider()
                
                changeColumn
                
                Divider()
                
                progressGauge(title: "After", value: Int(anxietyAfter))
            }
        }
        .cardStyle()
        .padding(.horizontal, Spacing.lg)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Anxiety progress")
        .accessibilityValue(accessibilityProgressValue)
    }

    private func progressGauge(title: String, value: Int) -> some View {
        VStack(spacing: Spacing.xxxs) {
            Gauge(value: Double(value), in: 0...10) {
                EmptyView()
            } currentValueLabel: {
                Text("\(value)")
                    .appFont(.bodyMedium)
                    .foregroundStyle(TextColors.primary)
                    .monospacedDigit()
            }
            .gaugeStyle(.accessoryCircular)
            .tint(anxietyAccent(for: value))
            .frame(width: 58, height: 58)
            .accessibilityHidden(true)
            
            Text(title)
                .appFont(.small)
                .foregroundStyle(TextColors.secondary)
        }
        .frame(width: 72)
    }

    private var changeColumn: some View {
        let change = session.anxietyBefore - Int(anxietyAfter)
        let changeText = change == 0 ? "0" : "\(change > 0 ? "-" : "+")\(abs(change))"
        
        return VStack(spacing: Spacing.xxxs) {
            Text(changeText)
                .appFont(.display)
                .foregroundStyle(change > 0 ? AppColors.positive : (change < 0 ? AppColors.primary : TextColors.secondary))
                .monospacedDigit()
            
            Text("Change")
                .appFont(.small)
                .foregroundStyle(TextColors.secondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Change \(changeText)")
    }
    
    private var accessibilityProgressValue: String {
        let before = session.anxietyBefore
        let after = Int(anxietyAfter)
        let change = before - after
        let changeText = change == 0 ? "0" : "\(change > 0 ? "-" : "+")\(abs(change))"
        return "Before: \(before) of 10, After: \(after) of 10, Change: \(changeText)"
    }
    
    private struct PraiseTipRow: View {
        let iconSystemName: String
        let text: String
        
        var body: some View {
            HStack(alignment: .top, spacing: Spacing.xxs) {
                Image(systemName: iconSystemName)
                    .font(.system(size: IconSize.glyph))
                    .foregroundStyle(AppColors.gray400)
                    .frame(width: 22, alignment: .center)
                    .padding(.top, 1)
                    .accessibilityHidden(true)
                
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
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func completeSession() async {
        isSaving = true
        defer { isSaving = false }
        do {
            let combinedNotes = notes.isEmpty ? finalNotes : notes + "\n\n" + finalNotes
            try await onSave(Int(anxietyAfter), combinedNotes.trimmingCharacters(in: .whitespacesAndNewlines))
            onComplete()
        } catch {
            errorMessage = String(localized: "Failed to save result.") + " \(error.localizedDescription)"
            showError = true
        }
    }
}
