import SwiftUI

// MARK: - BAIntentionStep

struct BAIntentionStep: View {
    @Binding var draft: BAPlanDraft
    var onNext: () -> Void

    private enum Timing: String, CaseIterable {
        case now = "Now"
        case later = "Later today"
    }

    @State private var timing: Timing = .now
    @State private var placeText: String = ""

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                VStack(spacing: Spacing.xs) {
                    Text(String(localized: "When will you do this?"))
                        .appFont(.h2)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(TextColors.primary)
                        .padding(.top, Spacing.lg)

                    Text(String(localized: "Deciding when and where increases follow-through."))
                        .appFont(.body)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(TextColors.secondary)
                }
                .padding(.horizontal, Spacing.lg)

                Picker(String(localized: "Timing"), selection: $timing) {
                    ForEach(Timing.allCases, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, Spacing.md)

                if timing == .later {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        SectionLabel(text: String(localized: "Time"))
                            .padding(.horizontal, Spacing.xxs)

                        DatePicker(
                            String(localized: "Time"),
                            selection: $draft.scheduledFor,
                            displayedComponents: .hourAndMinute
                        )
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .tint(AppColors.accent)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xs)
                        .background(AppColors.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.md)
                                .stroke(AppColors.gray200, lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, Spacing.md)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    SectionLabel(text: String(localized: "Where (optional)"))
                        .padding(.horizontal, Spacing.xxs)

                    TextField(String(localized: "Where? (optional)"), text: $placeText)
                        .appFont(.body)
                        .padding(Spacing.sm)
                        .background(AppColors.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.md)
                                .stroke(AppColors.gray200, lineWidth: 1)
                        )
                }
                .padding(.horizontal, Spacing.md)

                PrimaryButton(title: String(localized: "Next")) {
                    draft.startNow = timing == .now
                    draft.implementationPlace = placeText.isEmpty ? nil : placeText
                    onNext()
                }
                .padding(.horizontal, Spacing.md)
                .padding(.bottom, Spacing.xl)
            }
        }
        .animation(AppAnimation.spring, value: timing)
        .onAppear {
            timing = draft.startNow ? .now : .later
            placeText = draft.implementationPlace ?? ""
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var draft = BAPlanDraft()
    BAIntentionStep(draft: $draft, onNext: {})
}
