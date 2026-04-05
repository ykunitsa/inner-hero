import SwiftUI

// MARK: - BAAvoidanceStep

struct BAAvoidanceStep: View {
    @Binding var context: String?
    var onNext: () -> Void
    var onSkip: () -> Void

    @State private var text: String = ""

    private let suggestions: [String] = [
        String(localized: "Calling someone"),
        String(localized: "Leaving the house"),
        String(localized: "Starting a task"),
        String(localized: "Taking care of myself"),
        String(localized: "Replying to messages"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    header
                    textField
                    chips
                }
                .padding(.bottom, Spacing.md)
            }

            bottomButtons
        }
        .onAppear {
            text = context ?? ""
        }
    }

    // MARK: - Subviews

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(String(localized: "What are you avoiding right now?"))
                .appFont(.h2)
                .foregroundStyle(TextColors.primary)

            Text(String(localized: "Optional, but being honest with yourself helps."))
                .appFont(.small)
                .foregroundStyle(TextColors.secondary)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.top, Spacing.lg)
    }

    private var textField: some View {
        TextField(
            String(localized: "Write anything..."),
            text: $text,
            axis: .vertical
        )
        .appFont(.body)
        .lineLimit(3...6)
        .padding(Spacing.sm)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(AppColors.gray200, lineWidth: 1)
        )
        .padding(.horizontal, Spacing.md)
    }

    private var chips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.xxs) {
                ForEach(suggestions, id: \.self) { suggestion in
                    suggestionChip(suggestion)
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, 2)
        }
    }

    private var bottomButtons: some View {
        VStack(spacing: Spacing.xs) {
            Button(action: saveAndProceed) {
                Text(String(localized: "Next"))
                    .appFont(.buttonPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: TouchTarget.large)
                    .background(AppColors.accent)
                    .foregroundStyle(TextColors.onColor)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
            }

            Button(action: skipAndClear) {
                Text(String(localized: "Skip"))
                    .appFont(.buttonSmall)
                    .foregroundStyle(TextColors.secondary)
                    .frame(height: TouchTarget.standard)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.top, Spacing.sm)
        .padding(.bottom, Spacing.xl)
    }

    @ViewBuilder
    private func suggestionChip(_ label: String) -> some View {
        Button {
            HapticFeedback.selection()
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            text = trimmed.isEmpty ? label : trimmed + ", " + label
        } label: {
            Text(label)
                .appFont(.small)
                .foregroundStyle(TextColors.secondary)
                .padding(.horizontal, Spacing.xs)
                .frame(height: 32)
                .background(AppColors.cardBackground)
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(AppColors.gray300, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func saveAndProceed() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        context = trimmed.isEmpty ? nil : trimmed
        onNext()
    }

    private func skipAndClear() {
        context = nil
        onSkip()
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var context: String? = nil
    BAAvoidanceStep(context: $context, onNext: {}, onSkip: {})
}
