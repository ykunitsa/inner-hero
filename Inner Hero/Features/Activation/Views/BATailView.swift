import SwiftUI

/// The open activity, answered (spec §6): "Получилось?"
///
/// Two buttons of equal size. "Couldn't" is not a text link tucked under the
/// real answer — if the interface makes one outcome visually cheaper to report,
/// people stop reporting the other one, and the log quietly starts describing
/// someone who always follows through (principle 1.5).
///
/// The forecast is deliberately **not** shown here. Reminding someone they
/// predicted "not at all" right before they report what happened would bias the
/// report; the comparison belongs on the screen after.
struct BATailView: View {
    let entry: BALogEntry?
    let onAnswer: (BAOutcome) -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: Spacing.xs) {
            Spacer(minLength: Spacing.sm)

            if let entry {
                Text(entry.activityTitle)
                    .appFont(.h1)
                    .foregroundStyle(TextColors.primary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Text(BAFlowViewModel.plannedText(createdAt: entry.createdAt))
                    .appFont(.small)
                    .foregroundStyle(TextColors.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: Spacing.sm)
        }
        .padding(.horizontal, Spacing.sm)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .top) { header }
        .safeAreaInset(edge: .bottom) { actions }
        .formBackground()
        .ignoresSafeArea(.container, edges: .bottom)
    }

    private var header: some View {
        HStack {
            Spacer()
            // Closing leaves the activity open: it stays on Today and keeps
            // waiting. Spec §6 — "НЕ истекает молча".
            CircleButton(systemImage: "xmark", background: AppColors.cardBackground) {
                onClose()
            }
            .accessibilityLabel(String(localized: "Close"))
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.top, Spacing.sm)
    }

    private var actions: some View {
        VStack(spacing: Spacing.xxs) {
            PrimaryButton(
                title: String(localized: "Did it"),
                color: AppColors.black,
                titleColor: TextColors.onBlack
            ) {
                onAnswer(.done)
            }

            PrimaryButton(
                title: String(localized: "Couldn't"),
                color: AppColors.cardBackground,
                titleColor: TextColors.primary
            ) {
                onAnswer(.couldNot)
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.xs)
        // `Spacing.lg`, matching the other flows: the screen ignores the bottom
        // safe area, so anything less puts the second button under the home
        // indicator — which is where "Couldn't" was landing.
        .padding(.bottom, Spacing.lg)
    }
}
