import SwiftUI

/// A "label — value" row, used by both the ladder block and the exposure
/// statistics. One type for both because they are the same shape: a name on the
/// left, where things stand on the right.
///
/// Local to History rather than promoted to the design system — it has exactly
/// one screen, and the DS is not a dumping ground for one-off layouts.
struct StatRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
            Text(label)
                .appFont(.body)
                .foregroundStyle(TextColors.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: Spacing.xs)

            Text(value)
                .appFont(.bodyMedium)
                .foregroundStyle(TextColors.primary)
                .multilineTextAlignment(.trailing)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(minHeight: TouchTarget.minimum)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label), \(value)")
    }
}

/// One line of the session feed (spec §2.3.4).
///
/// Not a button: there is no session-detail screen in the spec, and inventing
/// one would add a screen outside §11 (plan `11.6-shell.md` §2, decision 11).
/// Rows are text, and the whole row reads as a single VoiceOver element.
struct SessionFeedRow: View {
    let item: HistoryItem

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.xs) {
            VStack(alignment: .leading, spacing: Spacing.xxxs) {
                HStack(spacing: Spacing.xxs) {
                    Text(item.title)
                        .appFont(.bodyMedium)
                        .foregroundStyle(TextColors.primary)

                    if item.isSituational {
                        AppBadge(text: String(localized: "Situational"), style: .neutral)
                    }
                }

                if !item.detail.isEmpty {
                    Text(item.detail)
                        .appFont(.small)
                        .foregroundStyle(TextColors.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
