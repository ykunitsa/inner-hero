import SwiftUI
import SwiftData

struct ActivationCompletionView: View {
    let activityName: String
    let startedAt: Date
    let onComplete: (Int?) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var rating: Double = 3
    @State private var skipRating: Bool = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.green, .mint],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .accessibilityHidden(true)
                        
                        Text("Activity Completed")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(TextColors.primary)
                    }
                    .padding(.top, 20)
                    
                    // Activity summary card
                    activitySummaryCard
                    
                    // Rating section
                    if !skipRating {
                        ratingSection
                    }
                    
                    // Skip rating toggle
                    skipRatingToggle
                    
                    Spacer(minLength: 20)
                    
                    // Complete button
                    completeButton
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.95, green: 0.97, blue: 1.0),
                        Color(red: 0.92, green: 0.95, blue: 0.98)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Complete Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(TextColors.toolbar)
                }
            }
        }
    }
    
    // MARK: - Activity Summary Card
    
    private var activitySummaryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.green)
                Text("Session Summary")
                    .font(.headline)
                    .foregroundStyle(TextColors.primary)
            }
            
            Divider()
            
            VStack(spacing: 12) {
                SummaryRow(
                    label: "Activity",
                    value: activityName,
                    icon: "figure.walk"
                )
                
                SummaryRow(
                    label: "Started",
                    value: formatTime(startedAt),
                    icon: "clock"
                )
                
                SummaryRow(
                    label: "Completed",
                    value: formatTime(Date()),
                    icon: "checkmark.circle"
                )
                
                SummaryRow(
                    label: "Duration",
                    value: formatDuration(Date().timeIntervalSince(startedAt)),
                    icon: "timer"
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Session summary: \(activityName), started at \(formatTime(startedAt))")
    }
    
    // MARK: - Rating Section
    
    private var ratingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "star.fill")
                    .font(.title3)
                    .foregroundStyle(.green)
                Text("Rate Your Experience")
                    .font(.headline)
                    .foregroundStyle(TextColors.primary)
            }
            
            Text("How would you rate the pleasure or satisfaction from this activity?")
                .font(.subheadline)
                .foregroundStyle(TextColors.secondary)
            
            Divider()
            
            VStack(spacing: 20) {
                // Rating value display
                HStack {
                    Spacer()
                    VStack(spacing: 4) {
                        Text("\(Int(rating))")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundStyle(ratingColor(for: Int(rating)))
                            .monospacedDigit()
                        
                        Text(ratingLabel(for: Int(rating)))
                            .font(.caption.weight(.medium))
                            .foregroundStyle(TextColors.secondary)
                    }
                    Spacer()
                }
                
                // Slider
                VStack(spacing: 8) {
                    Slider(value: $rating, in: 1...5, step: 1)
                        .tint(ratingColor(for: Int(rating)))
                        .accessibilityLabel("Pleasure rating")
                        .accessibilityValue("\(Int(rating)) out of 5")
                    
                    HStack {
                        Text("1")
                            .font(.caption)
                            .foregroundStyle(TextColors.tertiary)
                        Spacer()
                        Text("5")
                            .font(.caption)
                            .foregroundStyle(TextColors.tertiary)
                    }
                }
                
                // Rating scale labels
                VStack(alignment: .leading, spacing: 8) {
                    RatingLabelRow(value: 1, label: "Very low")
                    RatingLabelRow(value: 2, label: "Low")
                    RatingLabelRow(value: 3, label: "Moderate")
                    RatingLabelRow(value: 4, label: "High")
                    RatingLabelRow(value: 5, label: "Very high")
                }
                .padding(.top, 8)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        )
    }
    
    // MARK: - Skip Rating Toggle
    
    private var skipRatingToggle: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                skipRating.toggle()
            }
            #if canImport(UIKit)
            HapticFeedback.selection()
            #endif
        } label: {
            HStack(spacing: 12) {
                Image(systemName: skipRating ? "checkmark.square.fill" : "square")
                    .font(.title3)
                    .foregroundStyle(skipRating ? .green : TextColors.tertiary)
                
                Text("Skip rating (optional)")
                    .font(.body)
                    .foregroundStyle(TextColors.primary)
                
                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Skip rating")
        .accessibilityHint(skipRating ? "Rating will not be saved" : "Tap to skip rating")
    }
    
    // MARK: - Complete Button
    
    private var completeButton: some View {
        Button {
            completeSession()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.body)
                Text("Save Session")
                    .font(.system(size: 17, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [.green, .mint],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Save session")
    }
    
    // MARK: - Helper Methods
    
    private func completeSession() {
        let finalRating = skipRating ? nil : Int(rating)
        
        #if canImport(UIKit)
        HapticFeedback.success()
        #endif
        
        dismiss()
        onComplete(finalRating)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ interval: TimeInterval) -> String {
        let totalSeconds = Int(interval)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    private func ratingColor(for value: Int) -> Color {
        switch value {
        case 1...2:
            return .red
        case 3:
            return .orange
        case 4:
            return .mint
        case 5:
            return .green
        default:
            return .gray
        }
    }
    
    private func ratingLabel(for value: Int) -> String {
        switch value {
        case 1:
            return "Very low"
        case 2:
            return "Low"
        case 3:
            return "Moderate"
        case 4:
            return "High"
        case 5:
            return "Very high"
        default:
            return ""
        }
    }
}

// MARK: - Supporting Views

struct SummaryRow: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(.green.opacity(0.7))
                .frame(width: 24)
            
            Text(label)
                .font(.body)
                .foregroundStyle(TextColors.secondary)
            
            Spacer()
            
            Text(value)
                .font(.body.weight(.medium))
                .foregroundStyle(TextColors.primary)
        }
    }
}

struct RatingLabelRow: View {
    let value: Int
    let label: String
    
    var body: some View {
        HStack(spacing: 8) {
            Text("\(value)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(TextColors.tertiary)
                .frame(width: 20)
            
            Text(label)
                .font(.caption)
                .foregroundStyle(TextColors.secondary)
            
            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    ActivationCompletionView(
        activityName: "Morning walk in the park",
        startedAt: Date().addingTimeInterval(-900), // 15 minutes ago
        onComplete: { rating in
            print("Completed with rating: \(rating?.description ?? "none")")
        }
    )
}

