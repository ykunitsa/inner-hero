import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer()
                    .frame(minHeight: Spacing.xxxl)
                
                // App Icon/Title Section
                VStack(spacing: Spacing.md) {
                    Image(systemName: "heart.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.blue)
                        .accessibilityHidden(true)
                    
                    Text("Inner Hero")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(TextColors.primary)
                }
                .padding(.bottom, Spacing.xl)
                
                // Main Content Section
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    // Brief Explanation
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Добро пожаловать")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(TextColors.primary)
                        
                        Text("Inner Hero поможет вам практиковать экспозиционную терапию для работы с тревогой. Создавайте сценарии, проводите сеансы и отслеживайте свой прогресс.")
                            .font(.body)
                            .foregroundStyle(TextColors.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    // Warning Section
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        // Warning Header
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.body)
                                .foregroundStyle(AppTheme.State.warning)
                                .accessibilityHidden(true)
                            
                            Text("Важное предупреждение")
                                .font(.headline)
                                .foregroundStyle(TextColors.primary)
                        }
                        .accessibilityElement(children: .combine)
                        
                        // Warning Content
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Это приложение **не заменяет** профессиональную психотерапию или медицинскую помощь.")
                                .font(.body)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Text("Если вы испытываете серьёзные симптомы тревоги или других психических состояний, пожалуйста, обратитесь к квалифицированному специалисту.")
                                .font(.body)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Text("Используйте это приложение как дополнительный инструмент в рамках комплексного подхода к заботе о своём психическом здоровье.")
                                .font(.body)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .foregroundStyle(TextColors.secondary)
                    }
                    .padding(Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                            .fill(AppTheme.State.warning.opacity(Opacity.softBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                            .stroke(AppTheme.State.warning.opacity(Opacity.standardBorder), lineWidth: 1)
                    )
                }
                .padding(.horizontal, Spacing.md)
                
                Spacer()
                    .frame(minHeight: Spacing.xl)
                
                // Continue Button
                Button {
                    #if os(iOS)
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    #endif
                    
                    withAnimation(reduceMotion ? .none : .easeInOut(duration: 0.3)) {
                        hasCompletedOnboarding = true
                    }
                } label: {
                    Text("Продолжить")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: TouchTarget.minimum)
                        .padding(.vertical, Spacing.xs)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .accessibilityLabel("Продолжить")
                .accessibilityHint("Завершить онбординг и перейти к приложению")
                .padding(.horizontal, Spacing.md)
                .padding(.bottom, Spacing.xxl)
            }
        }
        .homeBackground()
        .scrollDismissesKeyboard(.interactively)
    }
}

#Preview {
    OnboardingView()
}
