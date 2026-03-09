import SwiftUI
import SwiftData

// MARK: - Complete Session View

struct CompleteSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    
    let session: ExposureSessionResult
    let notes: String
    let assignment: ExerciseAssignment?
    let onComplete: () -> Void
    
    @State private var anxietyAfter: Double = 5
    @State private var finalNotes: String = ""
    @State private var showError = false
    @State private var errorMessage = ""
    
    private enum FocusField: Hashable {
        case finalNotes
    }
    
    @FocusState private var focusedField: FocusField?
    
    private var dataManager: DataManager {
        DataManager(modelContext: modelContext)
    }
    
    private var screenBackgroundGradientColors: [Color] {
        if colorScheme == .dark {
            return [
                Color(red: 0.06, green: 0.07, blue: 0.09),
                Color(red: 0.10, green: 0.11, blue: 0.14)
            ]
        }
        
        return [
            Color(red: 0.95, green: 0.97, blue: 1.0),
            Color(red: 0.92, green: 0.95, blue: 0.98)
        ]
    }
    
    private var cardBackgroundColor: Color {
        if colorScheme == .dark {
            return Color(red: 0.14, green: 0.15, blue: 0.18)
        }
        
        return Color.white
    }
    
    private var cardShadowOpacity: Double {
        colorScheme == .dark ? Opacity.darkShadow : Opacity.lightShadow
    }
    
    private var editorBackgroundGradientColors: [Color] {
        if colorScheme == .dark {
            return [
                Color(red: 0.12, green: 0.13, blue: 0.16),
                Color(red: 0.09, green: 0.10, blue: 0.13)
            ]
        }
        
        return [
            Color(red: 0.98, green: 0.99, blue: 1.0),
            Color(red: 0.96, green: 0.97, blue: 0.99)
        ]
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    sessionSummaryCard
                    
                    praiseCard
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Label("Anxiety level after session", systemImage: "gauge")
                            .font(.headline)
                            .foregroundStyle(TextColors.primary)
                        
                        Text("Rate your anxiety level now (0–10)")
                            .font(.subheadline)
                            .foregroundStyle(TextColors.secondary)
                        
                        VStack(spacing: 16) {
                            HStack {
                                Spacer()
                                Text("\(Int(anxietyAfter))")
                                    .font(.system(.title, design: .rounded))
                                    .fontWeight(.bold)
                                    .foregroundStyle(anxietyColor(for: Int(anxietyAfter)))
                                    .monospacedDigit()
                                Spacer()
                            }
                            
                            Slider(value: $anxietyAfter, in: 0...10, step: 1)
                                .tint(anxietyColor(for: Int(anxietyAfter)))
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: editorBackgroundGradientColors,
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                    }
                    .padding(.horizontal, 20)
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel("Anxiety level after session")
                    
                    progressCard
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Describe how you feel", systemImage: "note.text")
                            .font(.headline)
                            .foregroundStyle(TextColors.primary)
                        
                        Text("What do you feel now? What thoughts/sensations were there during the session? What helped?")
                            .font(.subheadline)
                            .foregroundStyle(TextColors.secondary)
                        
                        TextEditor(text: $finalNotes)
                            .frame(minHeight: 100)
                            .focused($focusedField, equals: .finalNotes)
                            .scrollContentBackground(.hidden)
                            .padding(10)
                            .background(
                                LinearGradient(
                                    colors: editorBackgroundGradientColors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(cardBackgroundColor)
                            .shadow(color: Color.black.opacity(cardShadowOpacity), radius: 10, x: 0, y: 4)
                    )
                    .padding(.horizontal, 20)
                }
                .padding(.top, 20)
                .padding(.bottom, 32)
            }
            .background(
                LinearGradient(
                    colors: screenBackgroundGradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
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
                        completeSession()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(TextColors.toolbar)
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
        VStack(alignment: .leading, spacing: 16) {
            Label("Well done!", systemImage: "sparkles")
                .font(.headline)
                .foregroundStyle(TextColors.primary)
            
            Text("You completed the session—that's already a big step. Even if anxiety was high, you practiced staying with the feelings and moving forward.")
                .font(.body)
                .foregroundStyle(TextColors.secondary)
            
            VStack(alignment: .leading, spacing: 12) {
                PraiseTipRow(
                    iconSystemName: "checkmark.seal",
                    text: "Note any small progress—it adds up."
                )
                
                PraiseTipRow(
                    iconSystemName: "heart.text.square",
                    text: "Write down what helped (breathing, focus on the task, supportive thought)—it will be useful next time."
                )
            }
            .font(.subheadline)
            .foregroundStyle(TextColors.secondary)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(cardBackgroundColor)
                .shadow(color: Color.black.opacity(cardShadowOpacity), radius: 10, x: 0, y: 4)
        )
        .padding(.horizontal, 20)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Praise for completing the session")
        .accessibilityHint("Short supportive message and tips")
    }
    
    private var sessionSummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Session results", systemImage: "chart.bar.fill")
                .font(.headline)
                .foregroundStyle(TextColors.primary)
            
            HStack(spacing: 16) {
                VStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .accessibilityHidden(true)
                    Text("\(session.completedStepIndices.count)")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(TextColors.primary)
                    Text("steps")
                        .font(.caption)
                        .foregroundStyle(TextColors.secondary)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(String(format: String(localized: "%d steps completed"), session.completedStepIndices.count))
                
                Divider()
                
                VStack(spacing: 6) {
                    Image(systemName: "clock.fill")
                        .font(.title3)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .accessibilityHidden(true)
                    Text(formatTime(session.getTotalStepsTime()))
                        .font(.title3.weight(.bold))
                        .foregroundStyle(TextColors.primary)
                        .monospacedDigit()
                    Text("time")
                        .font(.caption)
                        .foregroundStyle(TextColors.secondary)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Completion time: \(formatTime(session.getTotalStepsTime()))")
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(cardBackgroundColor)
                .shadow(color: Color.black.opacity(cardShadowOpacity), radius: 10, x: 0, y: 4)
        )
        .padding(.horizontal, 20)
    }
    
    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
                .font(.headline)
                .foregroundStyle(TextColors.primary)
            
            HStack(spacing: 14) {
                progressGauge(title: "Before", value: session.anxietyBefore)
                
                Image(systemName: "arrow.right")
                    .font(.caption)
                    .foregroundStyle(TextColors.secondary)
                    .padding(.horizontal, 2)
                    .accessibilityHidden(true)
                
                progressGauge(title: "After", value: Int(anxietyAfter))
                
                Spacer(minLength: 8)
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Change")
                        .font(.caption)
                        .foregroundStyle(TextColors.secondary)
                    
                    let change = session.anxietyBefore - Int(anxietyAfter)
                    let changeText = change == 0 ? "0" : "\(change > 0 ? "-" : "+")\(abs(change))"
                    
                    Text(changeText)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(change > 0 ? .green : (change < 0 ? .yellow : .gray))
                        .monospacedDigit()
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(cardBackgroundColor)
                .shadow(color: Color.black.opacity(cardShadowOpacity), radius: 10, x: 0, y: 4)
        )
        .padding(.horizontal, 20)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Anxiety progress")
        .accessibilityValue(accessibilityProgressValue)
    }

    private func progressGauge(title: String, value: Int) -> some View {
        VStack(spacing: 8) {
            Gauge(value: Double(value), in: 0...10) {
                EmptyView()
            } currentValueLabel: {
                Text("\(value)")
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundStyle(TextColors.primary)
                    .monospacedDigit()
            }
            .gaugeStyle(.accessoryCircular)
            .tint(anxietyColor(for: value))
            .frame(width: 58, height: 58)
            .accessibilityHidden(true)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(TextColors.secondary)
        }
        .frame(width: 72)
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
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: iconSystemName)
                    .frame(width: 22, alignment: .center)
                    .padding(.top, 1)
                    .accessibilityHidden(true)
                
                Text(text)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .accessibilityElement(children: .combine)
        }
    }
    
    private func anxietyColor(for value: Int) -> Color {
        switch value {
        case 0...3:
            return .green
        case 4...6:
            return .orange
        case 7...10:
            return .red
        default:
            return .gray
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func completeSession() {
        do {
            let combinedNotes = notes.isEmpty ? finalNotes : notes + "\n\n" + finalNotes
            try dataManager.completeSession(
                session,
                anxietyAfter: Int(anxietyAfter),
                notes: combinedNotes.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            
            if let assignment {
                try dataManager.markAssignmentCompletedIfNeeded(assignment: assignment)
            }
            onComplete()
        } catch {
            errorMessage = String(localized: "Failed to save result.") + " \(error.localizedDescription)"
            showError = true
        }
    }
}
