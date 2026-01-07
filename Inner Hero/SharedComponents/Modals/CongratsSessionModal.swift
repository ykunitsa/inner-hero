import SwiftUI

// MARK: - Congrats Session Modal

struct CongratsSessionModal: View {
    @Environment(\.colorScheme) private var colorScheme
    
    struct Message: Identifiable, Hashable {
        let id = UUID()
        let iconSystemName: String
        let text: String
    }
    
    enum Palette: Hashable {
        case tealMint
        case purpleIndigo
        
        var accentColors: [Color] {
            switch self {
            case .tealMint:
                return [.teal, .mint]
            case .purpleIndigo:
                return [.purple, .indigo]
            }
        }
        
        func backgroundGradientColors(colorScheme: ColorScheme) -> [Color] {
            switch (self, colorScheme) {
            case (.tealMint, .dark):
                return [
                    Color(red: 0.08, green: 0.11, blue: 0.12),
                    Color(red: 0.05, green: 0.07, blue: 0.09)
                ]
            case (.tealMint, .light):
                return [
                    Color(red: 0.94, green: 0.98, blue: 0.98),
                    Color(red: 0.92, green: 0.96, blue: 0.96)
                ]
            case (.purpleIndigo, .dark):
                return [
                    Color(red: 0.09, green: 0.08, blue: 0.13),
                    Color(red: 0.06, green: 0.06, blue: 0.10)
                ]
            case (.purpleIndigo, .light):
                return [
                    Color(red: 0.97, green: 0.96, blue: 1.0),
                    Color(red: 0.94, green: 0.93, blue: 0.99)
                ]
            @unknown default:
                return [
                    Color(red: 0.94, green: 0.98, blue: 0.98),
                    Color(red: 0.92, green: 0.96, blue: 0.96)
                ]
            }
        }
    }
    
    struct Configuration: Hashable {
        var palette: Palette = .tealMint
        var topIconSystemName: String = "sparkles"
        var title: String = "Ты молодец!"
        var subtitle: String = "Ты только что сделал(а) полезный шаг для себя."
        var messages: [Message] = [
            Message(iconSystemName: "heart.circle.fill", text: "Пусть это станет маленькой хорошей привычкой"),
            Message(iconSystemName: "checkmark.circle.fill", text: "Стабильность важнее идеальности"),
            Message(iconSystemName: "sparkles", text: "Ты справляешься — шаг за шагом")
        ]
        var primaryButtonTitle: String = "Отлично"
    }
    
    let configuration: Configuration
    let onDone: () -> Void
    
    private var backgroundGradientColors: [Color] {
        configuration.palette.backgroundGradientColors(colorScheme: colorScheme)
    }
    
    private var cardShadowColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.35) : Color.black.opacity(0.05)
    }
    
    private var accentGradient: LinearGradient {
        LinearGradient(
            colors: configuration.palette.accentColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var accentBackgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                configuration.palette.accentColors[0].opacity(0.12),
                configuration.palette.accentColors[1].opacity(0.06)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    init(configuration: Configuration = Configuration(), onDone: @escaping () -> Void) {
        self.configuration = configuration
        self.onDone = onDone
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top section with icon and title
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(accentBackgroundGradient)
                        .frame(width: 80, height: 80)

                    Image(systemName: configuration.topIconSystemName)
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(accentGradient)
                }
                .accessibilityHidden(true)

                VStack(spacing: 10) {
                    Text(configuration.title)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(TextColors.primary)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(configuration.subtitle)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(TextColors.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.top, 28)
            .padding(.bottom, 24)

            // Supportive messages
            VStack(spacing: 12) {
                ForEach(configuration.messages) { message in
                    supportiveMessage(icon: message.iconSystemName, text: message.text)
                }
            }
            .padding(.horizontal, 20)

            Spacer()

            Button {
                onDone()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 15, weight: .semibold))
                        .accessibilityHidden(true)
                    Text(configuration.primaryButtonTitle)
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(accentGradient)
                )
                .shadow(color: configuration.palette.accentColors[0].opacity(0.25), radius: 8, x: 0, y: 4)
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 32)
            .accessibilityLabel("Закрыть")
        }
        .background(
            LinearGradient(
                colors: backgroundGradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private func supportiveMessage(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(accentGradient)
                .frame(width: 24)
                .accessibilityHidden(true)

            Text(text)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(TextColors.primary)
                .multilineTextAlignment(.leading)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .layoutPriority(1)
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.background)
                .shadow(color: cardShadowColor, radius: 6, x: 0, y: 2)
        )
    }
}

#Preview {
    CongratsSessionModal(onDone: { })
        .padding()
}
