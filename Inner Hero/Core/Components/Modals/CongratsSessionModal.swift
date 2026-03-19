import SwiftUI

// MARK: - Congrats Session Modal

struct CongratsSessionModal: View {

    struct Message: Identifiable, Hashable {
        let id = UUID()
        let iconSystemName: String
        let text: String
    }

    enum Palette: Hashable {
        case tealMint
        case purpleIndigo

        var accentColor: Color {
            switch self {
            case .tealMint:     return AppColors.positive
            case .purpleIndigo: return AppColors.accent
            }
        }

        var accentLightColor: Color {
            switch self {
            case .tealMint:     return AppColors.positiveLight
            case .purpleIndigo: return AppColors.accentLight
            }
        }
    }

    struct Configuration: Hashable {
        var palette: Palette = .tealMint
        var topIconSystemName: String = "sparkles"
        var title: String = "Well done!"
        var subtitle: String = "You just took a helpful step for yourself."
        var messages: [Message] = [
            Message(iconSystemName: "heart.circle.fill",    text: "Let this become a small good habit"),
            Message(iconSystemName: "checkmark.circle.fill", text: "Consistency matters more than perfection"),
            Message(iconSystemName: "sparkles",              text: "You're managing—step by step")
        ]
        var primaryButtonTitle: String = "Great"
    }

    let configuration: Configuration
    let onDone: () -> Void

    private var accentColor: Color { configuration.palette.accentColor }
    private var accentLightColor: Color { configuration.palette.accentLightColor }

    init(configuration: Configuration = Configuration(), onDone: @escaping () -> Void) {
        self.configuration = configuration
        self.onDone = onDone
    }

    var body: some View {
        VStack(spacing: 0) {
            // Icon + title + subtitle
            VStack(spacing: Spacing.md) {
                Image(systemName: configuration.topIconSystemName)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(accentColor)
                    .iconContainer(
                        size: IconSize.hero,
                        backgroundColor: accentLightColor,
                        cornerRadius: CornerRadius.pill
                    )
                    .accessibilityHidden(true)

                VStack(spacing: Spacing.xxxs) {
                    Text(configuration.title)
                        .appFont(.h1)
                        .foregroundStyle(TextColors.primary)
                        .multilineTextAlignment(.center)

                    Text(LocalizedStringKey(configuration.subtitle))
                        .appFont(.body)
                        .foregroundStyle(TextColors.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.top, Spacing.xxl)
            .padding(.bottom, Spacing.md)

            // Messages section — single card with header
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Keep in mind")
                    .appFont(.h3)
                    .foregroundStyle(TextColors.primary)

                ForEach(configuration.messages) { message in
                    tipRow(icon: message.iconSystemName, text: message.text)
                }
            }
            .cardStyle()
            .padding(.horizontal, Spacing.lg)

            Spacer()

            PrimaryButton(
                title: configuration.primaryButtonTitle,
                systemImage: "checkmark",
                color: accentColor
            ) {
                onDone()
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.lg)
            .accessibilityLabel("Close")
        }
        .pageBackground()
    }

    private func tipRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.xxs) {
            Image(systemName: icon)
                .font(.system(size: IconSize.glyph))
                .foregroundStyle(accentColor)
                .frame(width: 22, alignment: .center)
                .padding(.top, 1)
                .accessibilityHidden(true)

            Text(LocalizedStringKey(text))
                .appFont(.body)
                .foregroundStyle(TextColors.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    CongratsSessionModal(onDone: { })
        .padding()
}

#Preview("Purple") {
    CongratsSessionModal(
        configuration: .init(
            palette: .purpleIndigo,
            topIconSystemName: "sparkles",
            title: "Well done!",
            subtitle: "You brought your attention to the present moment.",
            messages: [
                .init(iconSystemName: "eye.circle.fill",         text: "If you like, repeat another round."),
                .init(iconSystemName: "hand.raised.circle.fill", text: "You relied on your senses—that strengthens with practice."),
                .init(iconSystemName: "heart.circle.fill",       text: "Even a small step is self-care.")
            ]
        ),
        onDone: { }
    )
    .padding()
}
