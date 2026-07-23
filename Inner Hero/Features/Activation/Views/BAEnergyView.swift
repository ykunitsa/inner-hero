import SwiftUI

/// The entrance to BA (spec §6): one question, and the answer is the action.
///
/// No "Next" button. The three answers are the only controls on the screen, and
/// tapping one both records the state and moves on — there is nothing to confirm,
/// and a confirm step would be a second choice for the same decision
/// (principle 1.2).
struct BAEnergyView: View {
    let activityCount: Int
    /// Drives the `sessions == 0` rule (principle 1.7) — an explanation before
    /// the first logged activity, nothing afterwards. Derived from the log count,
    /// never from a "has seen" flag.
    let hasSessions: Bool
    let onAnswer: (BAEnergy) -> Void
    let onOpenStore: () -> Void
    let onClose: () -> Void

    @Environment(ArticlesStore.self) private var articles
    @State private var showArticle = false

    private var article: Article? {
        articles.allArticles.first { $0.id == ExerciseArticle.activation }
    }

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Spacer(minLength: Spacing.sm)

            Text(String(localized: "How much energy right now?"))
                .appFont(.h1)
                .foregroundStyle(TextColors.primary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, Spacing.sm)

            Spacer(minLength: Spacing.sm)

            // The answers sit low: whoever taps "Almost none" is holding the
            // phone one-handed, and the bottom third is the part they can reach.
            VStack(spacing: Spacing.xs) {
                BAEnergyCards(onAnswer: onAnswer)

                if !hasSessions {
                    Text(
                        String(
                            localized: "Action comes before the wish. You do it first; wanting it shows up later."
                        )
                    )
                    .appFont(.small)
                    .foregroundStyle(TextColors.tertiary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, Spacing.md)
                    .padding(.top, Spacing.xxs)
                }

                articleDoor
            }
        }
        .padding(.horizontal, Spacing.sm)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .top) { header }
        .safeAreaInset(edge: .bottom) { storeLine }
        .formBackground()
        .ignoresSafeArea(.container, edges: .bottom)
        .articleDoorSheet(article, isPresented: $showArticle)
    }

    private var header: some View {
        ExerciseDoorHeader(
            title: String(localized: "Activation"),
            infoLabel: article?.title,
            onInfo: article == nil ? nil : { showArticle = true },
            onClose: onClose
        )
    }

    /// Spec §8. BA's door has no "Start" button to sit above — the three energy
    /// answers *are* the action — so the card goes below them, under the
    /// corrective phrase it belongs with and above the quiet store line.
    @ViewBuilder
    private var articleDoor: some View {
        if !hasSessions, let article {
            ArticleDoorRow(title: article.title, readTime: article.readTime) {
                showArticle = true
            }
            .padding(.top, Spacing.xs)
        }
    }

    /// The other door (spec §6), kept deliberately quiet. It is a count of what
    /// is on the shelf, not a score — nothing here goes up as a reward.
    private var storeLine: some View {
        Button(action: onOpenStore) {
            Text(
                String(
                    format: String(localized: "Activities · %lld"),
                    activityCount
                )
            )
            .appFont(.small)
            .foregroundStyle(TextColors.secondary)
            .frame(maxWidth: .infinity)
            .frame(minHeight: TouchTarget.minimum)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, Spacing.sm)
        .padding(.bottom, Spacing.lg)
    }
}

#Preview {
    BAEnergyView(
        activityCount: 15,
        hasSessions: false,
        onAnswer: { _ in },
        onOpenStore: {},
        onClose: {}
    )
    .environment(ArticlesStore())
}
