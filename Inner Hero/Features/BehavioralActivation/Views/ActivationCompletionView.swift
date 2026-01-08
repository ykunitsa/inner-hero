import SwiftUI
import SwiftData

struct ActivationCompletionView: View {
    let activityName: String
    let startedAt: Date
    let onComplete: (Int?) -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    @State private var rating: Double = 3
    
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
                        
                        Text("Активность завершена")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(TextColors.primary)
                    }
                    .padding(.top, 20)
                    
                    // Activity summary card
                    activitySummaryCard
                    
                    // Rating section
                    ratingSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .navigationTitle("Завершение сеанса")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
                    }
                    .foregroundStyle(TextColors.toolbar)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        completeSession()
                    }
                    .foregroundStyle(TextColors.toolbar)
                    .fontWeight(.semibold)
                    .accessibilityLabel("Сохранить сеанс")
                    .accessibilityHint("Сохранит сеанс и оценку впечатления")
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
                Text("Итоги сеанса")
                    .font(.headline)
                    .foregroundStyle(TextColors.primary)
            }
            
            Divider()
            
            VStack(spacing: 12) {
                SummaryRow(
                    label: "Активность",
                    value: activityName,
                    icon: "figure.walk"
                )
                
                SummaryRow(
                    label: "Начало",
                    value: formatTime(startedAt),
                    icon: "clock"
                )
                
                SummaryRow(
                    label: "Завершено",
                    value: formatTime(Date()),
                    icon: "checkmark.circle"
                )
                
                SummaryRow(
                    label: "Длительность",
                    value: formatDuration(Date().timeIntervalSince(startedAt)),
                    icon: "timer"
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.thinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.primary.opacity(colorScheme == .dark ? 0.18 : 0.06), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Итоги сеанса: \(activityName), начало в \(formatTime(startedAt))")
    }
    
    // MARK: - Rating Section
    
    private var ratingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "star.fill")
                    .font(.title3)
                    .foregroundStyle(.green)
                Text("Насколько понравилось?")
                    .font(.headline)
                    .foregroundStyle(TextColors.primary)
            }
            
            Text("Оцените, насколько приятной была эта активность (1–5)")
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
                        .accessibilityLabel("Оценка впечатления")
                        .accessibilityValue("\(Int(rating)) из 5")
                    
                    HStack {
                        Text("1\nСовсем не понравилось")
                            .font(.caption)
                            .multilineTextAlignment(.leading)
                            .foregroundStyle(TextColors.secondary)
                        Spacer()
                        Text("3\nНормально")
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(TextColors.secondary)
                        Spacer()
                        Text("5\nОчень понравилось")
                            .font(.caption)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(TextColors.secondary)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.thinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.primary.opacity(colorScheme == .dark ? 0.18 : 0.06), lineWidth: 1)
        )
    }
    
    // MARK: - Helper Methods
    
    private func completeSession() {
        HapticFeedback.success()
        
        dismiss()
        onComplete(Int(rating))
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
            return "Совсем не понравилось"
        case 2:
            return "Скорее нет"
        case 3:
            return "Нормально"
        case 4:
            return "Скорее да"
        case 5:
            return "Очень понравилось"
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

// MARK: - Preview

#Preview {
    ActivationCompletionView(
        activityName: "Утренняя прогулка в парке",
        startedAt: Date().addingTimeInterval(-900), // 15 minutes ago
        onComplete: { rating in
            print("Завершено, оценка: \(rating?.description ?? "нет")")
        }
    )
}


