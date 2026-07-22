import SwiftUI

// Behavioral-activation components (spec §6). Exercise-scoped by the same
// reasoning as `PMRComponents.swift`: these are shaped by one exercise's flow
// and would only make `Components.swift` (already ~1,270 lines, TECH_DEBT #3)
// harder to read.

// ─────────────────────────────────────────────
// MARK: Energy Cards
// ─────────────────────────────────────────────

/// The three answers to "How much energy right now?" (spec §6).
///
/// Looks like `SegmentedChoice(style: .cards)` with the radio dot removed, and
/// that removal is the entire reason it exists. Every selection control in the
/// system encodes "chosen, now confirm below"; here the answer **is** the
/// navigation, so a dot would appear for one frame and then leave with the
/// screen.
///
/// `ScaleChoice` — the usual home for an ordinal set like this — is ruled out for
/// a second reason: its slider is always parked on some value, so a user who
/// never answered would still record one (see USAGE.MD §Шкалы).
///
/// Usage: `BAEnergyCards { viewModel.answerEnergy($0, activities: activities) }`
struct BAEnergyCards: View {
    let onAnswer: (BAEnergy) -> Void

    var body: some View {
        VStack(spacing: Spacing.xxs) {
            ForEach(BAEnergy.allCases, id: \.self) { energy in
                Button {
                    HapticFeedback.selection()
                    onAnswer(energy)
                } label: {
                    Text(energy.title)
                        .appFont(.body)
                        .foregroundStyle(TextColors.primary)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xs)
                        .frame(minHeight: TouchTarget.minimum)
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                                .fill(AppColors.cardBackground)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// ─────────────────────────────────────────────
// MARK: Ladder Suggestion Line
// ─────────────────────────────────────────────

/// The ladder rule as a line the user may take or ignore (spec §6, principle
/// 1.8).
///
/// Renders nothing when there is no suggestion — no placeholder, no greyed-out
/// version. A rule that is always visible stops being a rule and becomes a
/// permanent scoreboard, which is what principle 1.4 rules out.
struct BASuggestionLine: View {
    let suggestion: BALadder.Suggestion
    let onApply: () -> Void

    var body: some View {
        Button {
            onApply()
            HapticFeedback.light()
        } label: {
            HStack(spacing: Spacing.xxs) {
                Image(systemName: glyph)
                    .appFont(.bodyMedium)
                    .accessibilityHidden(true)
                Text(text)
                    .appFont(.small)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .foregroundStyle(AppColors.accent)
            .padding(Spacing.xs)
            .frame(maxWidth: .infinity, minHeight: TouchTarget.minimum)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                    .fill(AppColors.accent.opacity(Opacity.softBackground))
            )
        }
        .buttonStyle(.plain)
        .transition(.opacity)
    }

    private var glyph: String {
        switch suggestion {
        case .stepUp: "arrow.up"
        case .stepDown: "arrow.down"
        }
    }

    /// States the run as the reason for the offer and nothing more. It is gone
    /// the moment it is tapped or the screen is left — it is not a counter.
    ///
    /// Written out per case rather than interpolating the basket name: Russian
    /// declines the adjective, so "Take a %@ one?" with "средне" substituted in
    /// produces text no one would write by hand. Four combinations exist and all
    /// four are spelled.
    private var text: String {
        switch suggestion {
        case .stepUp(.hard):
            String(localized: "Five in a row worked out. Take a hard one?")
        case .stepUp:
            String(localized: "Five in a row worked out. Take a medium one?")
        case .stepDown(.medium):
            String(localized: "Twice in a row it didn't work out. Take a medium one?")
        case .stepDown:
            String(localized: "Twice in a row it didn't work out. Take an easy one?")
        }
    }
}

#Preview {
    VStack(spacing: Spacing.md) {
        BAEnergyCards { _ in }
        BASuggestionLine(suggestion: .stepUp(.medium)) {}
        BASuggestionLine(suggestion: .stepDown(.easy)) {}
    }
    .padding(Spacing.sm)
    .formBackground()
}
