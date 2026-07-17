import SwiftUI

// MARK: - Mood Emoji Helper

/// Maps a 1–10 mood rating to an emoji. Namespaced to avoid a global free function.
enum Mood {
    static let emptyGlyph = "😶"
    private static let emojiTable = ["😭", "😢", "😞", "😔", "😐", "🙂", "😊", "😄", "😁", "🤩"]

    static func emoji(for value: Int) -> String {
        guard value >= 1, value <= 10 else { return emptyGlyph }
        return emojiTable[value - 1]
    }
}

// MARK: - MoodEmojiSlider
// Interactive 1–10 mood selector using emoji on a draggable slider.

struct MoodEmojiSlider: View {
    @Binding var selectedMood: Int?

    var body: some View {
        VStack(spacing: Spacing.sm) {
            emojiDisplay
            sliderTrack
            labelsRow
        }
    }

    // MARK: - Emoji Display

    private var emojiDisplay: some View {
        VStack(spacing: Spacing.xxs) {
            if let mood = selectedMood {
                Text(Mood.emoji(for: mood))
                    .font(.system(size: 52))
                    .id(mood)
                    .transition(
                        .asymmetric(
                            insertion: .scale(scale: 0.6).combined(with: .opacity),
                            removal:   .scale(scale: 0.6).combined(with: .opacity)
                        )
                    )
                Text("\(mood)")
                    .appFont(.statValue)
                    .foregroundStyle(TextColors.primary)
                    .contentTransition(.numericText())
                    .animation(AppAnimation.fast, value: mood)
            } else {
                Text("😶")
                    .font(.system(size: 52))
                    .opacity(0.3)
                    .id(-1)
                Text("—")
                    .appFont(.statValue)
                    .foregroundStyle(TextColors.tertiary)
            }
        }
        .frame(minHeight: 96)
        .frame(maxWidth: .infinity)
        .animation(AppAnimation.fast, value: selectedMood)
    }

    // MARK: - Slider Track

    private var sliderTrack: some View {
        GeometryReader { geo in
            let totalWidth    = geo.size.width
            let thumbDiameter: CGFloat = 28
            let thumbRadius   = thumbDiameter / 2
            let available     = totalWidth - thumbDiameter
            let step          = available / 9.0

            ZStack(alignment: .leading) {
                // Background track
                Capsule()
                    .fill(AppColors.gray200)
                    .frame(height: 4)
                    .padding(.horizontal, thumbRadius)
                    .frame(maxHeight: .infinity)

                // Filled track
                if let mood = selectedMood {
                    Capsule()
                        .fill(AppColors.primary)
                        .frame(
                            width: thumbRadius + step * CGFloat(mood - 1),
                            height: 4
                        )
                        .frame(maxHeight: .infinity, alignment: .leading)
                        .animation(AppAnimation.fast, value: mood)
                }

                // Thumb
                Circle()
                    .fill(AppColors.primary)
                    .frame(width: thumbDiameter, height: thumbDiameter)
                    .shadow(color: AppColors.primary.opacity(0.3), radius: 6, y: 2)
                    .offset(x: thumbOffset(mood: selectedMood, step: step))
                    .animation(AppAnimation.fast, value: selectedMood)
                    .frame(maxHeight: .infinity)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let x = max(0, min(value.location.x - thumbRadius, available))
                        let newMood = max(1, min(10, Int((x / step).rounded()) + 1))
                        if selectedMood != newMood {
                            withAnimation(AppAnimation.fast) { selectedMood = newMood }
                            HapticFeedback.selection()
                        }
                    }
            )
        }
        .frame(height: 28)
    }

    private func thumbOffset(mood: Int?, step: CGFloat) -> CGFloat {
        guard let mood else { return 0 }
        return step * CGFloat(mood - 1)
    }

    // MARK: - Labels

    private var labelsRow: some View {
        HStack {
            Text(String(localized: "Very bad"))
            Spacer()
            Text(String(localized: "Great"))
        }
        .appFont(.caption)
        .foregroundStyle(TextColors.tertiary)
    }
}
