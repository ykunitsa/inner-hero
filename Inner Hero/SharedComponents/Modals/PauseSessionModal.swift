import SwiftUI

// MARK: - Pause Session Modal

struct PauseSessionModal: View {
    @Environment(\.colorScheme) private var colorScheme
    
    let onResume: () -> Void
    let onEnd: () -> Void
    
    private var backgroundGradientColors: [Color] {
        if colorScheme == .dark {
            return [
                Color(red: 0.10, green: 0.11, blue: 0.14),
                Color(red: 0.06, green: 0.07, blue: 0.10)
            ]
        }
        
        return [
            Color(red: 0.95, green: 0.97, blue: 1.0),
            Color(red: 0.92, green: 0.95, blue: 0.98)
        ]
    }
    
    private var secondaryButtonBackground: some ShapeStyle {
        if colorScheme == .dark {
            return AnyShapeStyle(Color.primary.opacity(0.14))
        }
        
        // Subtle, glassy surface on light theme
        return AnyShapeStyle(.ultraThinMaterial)
    }
    
    private var cardShadowColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.35) : Color.black.opacity(0.05)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Top section with icon and title
            VStack(spacing: 20) {
                // Icon with gradient background
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.blue.opacity(0.1),
                                    Color.cyan.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "heart.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .accessibilityHidden(true)
                
                // Title and subtitle
                VStack(spacing: 10) {
                    Text("Вы делаете отлично!")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(TextColors.primary)
                        .multilineTextAlignment(.center)
                
                }
            }
            .padding(.top, 28)
            .padding(.bottom, 24)
            
            // Supportive messages
            VStack(spacing: 12) {
                supportiveMessage(icon: "checkmark.circle.fill", text: "Делайте перерывы когда нужно")
                supportiveMessage(icon: "heart.circle.fill", text: "Забота о себе - это не слабость")
                supportiveMessage(icon: "star.circle.fill", text: "Каждый шаг - это прогресс")
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            // Action buttons - horizontal layout
            HStack(spacing: 12) {
                // Secondary button - End
                Button {
                    onEnd()
                } label: {
                    Text("Завершить")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(TextColors.secondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(secondaryButtonBackground)
                        )
                }
                .accessibilityLabel("Завершить на сегодня")
                .accessibilityHint("Дважды нажмите чтобы завершить сеанс без сохранения")
                
                // Primary button - Resume
                Button {
                    onResume()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 15, weight: .semibold))
                            .accessibilityHidden(true)
                        Text("Продолжить")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .cyan],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .accessibilityLabel("Продолжить сеанс")
                .accessibilityHint("Дважды нажмите чтобы вернуться к сеансу")
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 32)
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
                        colors: [.blue, .cyan],
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
