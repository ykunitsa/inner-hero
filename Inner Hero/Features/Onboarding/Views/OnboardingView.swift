import SwiftUI

/// Onboarding (spec §7): three screens, zero questions.
///
/// The three screens are not a welcome tour. Screen 1 sets the frame the whole
/// app depends on (skills are trained in advance, protocols are done on a
/// schedule), screen 2 states what the app refuses to be — a compliance asset
/// that filters out the wrong user on install day — and screen 3 points at real
/// crisis care.
///
/// Nothing is asked and nothing can be skipped: a skippable screen 2 would not
/// do the one job it exists for. The cost is three taps, once per install.
struct OnboardingView: View {
    @AppStorage(AppStorageKeys.hasCompletedOnboarding) private var hasCompletedOnboarding = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var page = 0

    private static let lastPage = 2

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                trainingPage.tag(0)
                absencesPage.tag(1)
                crisisPage.tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            // The bare dots render near-white on this background and all but
            // vanish; the pill puts them back above readable contrast
            // (codex §6). They are navigation, not a progress metric (§1.4).
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            continueButton
                .padding(.horizontal, Spacing.sm)
                .padding(.bottom, Spacing.xl)
        }
        .homeBackground()
    }

    // MARK: Page 1 — the frame

    private var trainingPage: some View {
        OnboardingPage(
            icon: "figure.mind.and.body",
            title: String(localized: "This is training, not first aid")
        ) {
            Text(
                String(
                    localized: "Breathing and relaxation are skills. They work when they have been trained in advance, on a calm day — not when anxiety is already at its peak."
                )
            )
            Text(
                String(
                    localized: "Exposure and activation are protocols. They are done on a schedule, by agreement with yourself or your therapist."
                )
            )
        }
    }

    // MARK: Page 2 — the boundaries

    /// Deliberately not styled as a warning. The old onboarding put this behind
    /// an orange border and a warning triangle; these are boundaries stated
    /// calmly, not an alert (codex §8).
    private var absencesPage: some View {
        OnboardingPage(
            icon: "minus.circle",
            title: String(localized: "What's not here")
        ) {
            Text(
                String(
                    localized: "No \"I feel bad right now\" button. This app does not do rescue."
                )
            )
            Text(
                String(
                    localized: "No replacement for a therapist. It does not diagnose and does not treat."
                )
            )
            Text(
                String(
                    localized: "No advice. It never decides which exercise you need."
                )
            )
        }
    }

    // MARK: Page 3 — where to actually go

    private var crisisPage: some View {
        OnboardingPage(
            icon: "phone.arrow.up.right",
            title: String(localized: "If things get really bad")
        ) {
            Text(
                String(
                    localized: "This app is not the place for that. Crisis helplines are free and open around the clock."
                )
            )

            CrisisHelplineLink()

            // The fallback that cannot go stale and needs no network. The list
            // of helplines is deliberately not hardcoded (spec §7), which means
            // it leans on a site the app does not control — this line is what
            // survives that.
            Text(
                String(
                    localized: "If there is immediate danger, call your country's emergency number."
                )
            )

            Text(String(localized: "This stays in Settings."))
                .appFont(.small)
                .foregroundStyle(TextColors.tertiary)
        }
    }

    // MARK: Button

    private var continueButton: some View {
        PrimaryButton(
            title: page == Self.lastPage
                ? String(localized: "Start")
                : String(localized: "Next"),
            color: AppColors.primary
        ) {
            if page == Self.lastPage {
                hasCompletedOnboarding = true
            } else {
                withAnimation(reduceMotion ? .none : AppAnimation.standard) {
                    page += 1
                }
            }
        }
    }
}

// MARK: - Page layout

/// One onboarding page: icon, title, body. Shared layout for the three, which is
/// chrome — the pages differ only in words.
private struct OnboardingPage<Content: View>: View {
    let icon: String
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        // Centred while the copy is short, scrollable once Dynamic Type makes it
        // tall. Top-aligning left roughly half the screen empty below the text,
        // which reads as unfinished rather than as deliberate quiet (codex §3).
        GeometryReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    Image(systemName: icon)
                        .appFont(.h1)
                        .foregroundStyle(AppColors.primary)
                        .frame(width: IconSize.hero, height: IconSize.hero)
                        .background(
                            Circle().fill(AppColors.primary.opacity(Opacity.softBackground))
                        )
                        .accessibilityHidden(true)

                    Text(title)
                        .appFont(.h1)
                        .foregroundStyle(TextColors.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        content
                    }
                    .appFont(.body)
                    .foregroundStyle(TextColors.secondary)
                    // No lineLimit anywhere: this copy *is* the screen, and it
                    // has to survive the largest Dynamic Type sizes intact
                    // (codex §6).
                    .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xl)
                .frame(minHeight: proxy.size.height, alignment: .center)
            }
        }
    }
}

// MARK: - Crisis helpline link

/// Spec §7: an up-to-date list, never a hardcoded one. Numbers go stale and are
/// country-specific; a directory is the only version of this that stays true.
///
/// Opening it hands the user to Safari — nothing is sent anywhere, and the app
/// still has no network of its own (§1.9).
struct CrisisHelplineLink: View {
    static let url = URL(string: "https://findahelpline.com")!

    /// A `Button` rather than a `Link`: `Link` insists on styling its own label,
    /// so it rendered system blue; overriding that with the page's own
    /// `foregroundStyle` then made it grey and indistinguishable from body text.
    /// Opening the URL by hand is the only way this row obeys the design system.
    @Environment(\.openURL) private var openURL

    var body: some View {
        Button {
            openURL(Self.url)
        } label: {
            HStack(spacing: Spacing.xxs) {
                Text(String(localized: "Find a helpline in your country"))
                    .appFont(.bodyMedium)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Image(systemName: "arrow.up.right")
                    .appFont(.small)
                    .accessibilityHidden(true)
                Spacer(minLength: 0)
            }
            .foregroundStyle(AppColors.accent)
            .frame(minHeight: TouchTarget.minimum)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    OnboardingView()
}
