import SwiftUI

// MARK: - Congrats Session Modal

struct CongratsSessionModal: View {
    @Environment(\.colorScheme) private var colorScheme
    
    let onDone: () -> Void
    
    private var backgroundGradientColors: [Color] {
        if colorScheme == .dark {
            return [
                Color(red: 0.08, green: 0.11, blue: 0.12),
                Color(red: 0.05, green: 0.07, blue: 0.09)
            ]
        }
        
        return [
            Color(red: 0.94, green: 0.98, blue: 0.98),
            Color(red: 0.92, green: 0.96, blue: 0.96)
        ]
    }
    
    private var cardShadowColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.35) : Color.black.opacity(0.05)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top section with icon and title
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.teal.opacity(0.12),
                                    Color.mint.opacity(0.06)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)

                    Image(systemName: "sparkles")
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.teal, .mint],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .accessibilityHidden(true)

                VStack(spacing: 10) {
                    Text("Ты молодец!")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(TextColors.primary)
                        .multilineTextAlignment(.center)

                    Text("Ты только что сделал(а) полезный шаг для себя.")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(TextColors.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.top, 28)
            .padding(.bottom, 24)

            // Supportive messages
            VStack(spacing: 12) {
                supportiveMessage(icon: "heart.circle.fill", text: "Пусть это станет маленькой хорошей привычкой")
                supportiveMessage(icon: "checkmark.circle.fill", text: "Стабильность важнее идеальности")
                supportiveMessage(icon: "sparkles", text: "Ты справляешься — шаг за шагом")
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
                    Text("Отлично")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [.teal, .mint],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .shadow(color: .teal.opacity(0.25), radius: 8, x: 0, y: 4)
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
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.teal, .mint],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 24)
                .accessibilityHidden(true)

            Text(text)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(TextColors.primary)

            Spacer()
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
