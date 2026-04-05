import SwiftUI

struct BAMoodPickerView: View {
    let question: String
    @Binding var mood: Int
    var onNext: () -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: Spacing.xxs), count: 5)

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Text(question)
                .appFont(.h2)
                .foregroundStyle(TextColors.primary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            VStack(spacing: Spacing.sm) {
                LazyVGrid(columns: columns, spacing: Spacing.xs) {
                    ForEach(1...10, id: \.self) { value in
                        moodButton(value)
                    }
                }

                Text(moodLabel)
                    .appFont(.body)
                    .foregroundStyle(TextColors.secondary)
                    .animation(.easeInOut(duration: 0.15), value: mood)
            }

            Spacer()

            PrimaryButton(title: String(localized: "Next"), color: AppColors.positive, action: onNext)
        }
        .padding(Spacing.md)
    }

    @ViewBuilder
    private func moodButton(_ value: Int) -> some View {
        let isSelected = mood == value

        Button {
            if mood != value {
                HapticFeedback.selection()
                mood = value
            }
        } label: {
            Text("\(value)")
                .appFont(.bodyMedium)
                .foregroundStyle(isSelected ? .white : TextColors.secondary)
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .background(
                    Circle()
                        .fill(isSelected ? AppColors.positive : AppColors.cardBackground)
                )
                .overlay(
                    Circle()
                        .strokeBorder(
                            isSelected ? AppColors.positive : AppColors.gray300,
                            lineWidth: 1.5
                        )
                )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }

    private var moodLabel: String {
        switch mood {
        case 1...3:  return String(localized: "Very difficult")
        case 4...5:  return String(localized: "Difficult")
        case 6...7:  return String(localized: "Neutral")
        case 8...9:  return String(localized: "Good")
        case 10:     return String(localized: "Excellent")
        default:     return ""
        }
    }
}

#Preview {
    @Previewable @State var mood = 5
    BAMoodPickerView(
        question: "How are you feeling right now?",
        mood: $mood,
        onNext: {}
    )
    .padding()
}
