import SwiftUI

/// The safety-behavior chip block shared by the situational form and the
/// planned "after" screen (spec §3): an exclusive "Nothing" chip, a
/// multi-select set, and a user-authored "Your own…" chip.
/// State lives in the owning view model; this view only renders and relays.
struct SafetyBehaviorPicker: View {
    let options: [String]
    let isNothingSelected: Bool
    let selected: Set<String>
    let onToggleNothing: () -> Void
    let onToggle: (String) -> Void
    /// Returns false for blank/duplicate input (mirrors the view models).
    let onAddCustom: (String) -> Bool

    @State private var isAddingCustomChip = false
    @State private var customChipDraft = ""
    @FocusState private var customChipFocused: Bool

    var body: some View {
        ChipFlowLayout {
            SelectableChip(
                text: String(localized: "Nothing"),
                isSelected: Binding(
                    get: { isNothingSelected },
                    set: { _ in onToggleNothing() }
                )
            )
            ForEach(options, id: \.self) { option in
                SelectableChip(
                    text: option,
                    isSelected: Binding(
                        get: { selected.contains(option) },
                        set: { _ in onToggle(option) }
                    )
                )
            }
            customChip
        }
    }

    @ViewBuilder
    private var customChip: some View {
        if isAddingCustomChip {
            TextField(String(localized: "Your own…"), text: $customChipDraft)
                .appFont(.body)
                .foregroundStyle(TextColors.primary)
                .focused($customChipFocused)
                .submitLabel(.done)
                .onSubmit { commitCustomChip() }
                .frame(width: 140)
                .padding(.horizontal, Spacing.xs)
                .padding(.vertical, Spacing.xxs)
                .background(Capsule().fill(AppColors.gray100))
        } else {
            AddCustomChipButton {
                isAddingCustomChip = true
                customChipFocused = true
            }
        }
    }

    private func commitCustomChip() {
        _ = onAddCustom(customChipDraft)
        customChipDraft = ""
        isAddingCustomChip = false
    }
}

/// Accent-tinted "add your own" chip — visually separated from the
/// selectable behavior chips around it.
private struct AddCustomChipButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xxxs) {
                Image(systemName: "plus")
                    .font(.system(size: IconSize.fieldGlyph, weight: .semibold))
                Text(String(localized: "Your own…"))
                    .appFont(.body)
                    .lineLimit(1)
            }
            .foregroundStyle(AppColors.accent)
            .padding(.horizontal, Spacing.xs)
            .padding(.vertical, Spacing.xxs)
            .background(Capsule().fill(AppColors.accent.opacity(Opacity.subtleBackground)))
            .overlay(
                Capsule().strokeBorder(
                    AppColors.accent.opacity(Opacity.emphasizedBorder),
                    lineWidth: BorderWidth.standard
                )
            )
            .touchTarget(width: 0)
        }
        .buttonStyle(.plain)
    }
}
