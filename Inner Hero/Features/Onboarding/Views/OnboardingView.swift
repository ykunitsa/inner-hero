import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer()
                    .frame(minHeight: 48)
                
                // App Icon/Title Section
                VStack(spacing: 20) {
                    Image(systemName: "heart.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.primary)
                        .accessibilityHidden(true)
                    
                    Text("Inner Hero")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(.primary)
                }
                .padding(.bottom, 32)
                
                // Main Content Section
                VStack(alignment: .leading, spacing: 24) {
                    // Brief Explanation
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Добро пожаловать")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(.primary)
                        
                        Text("Inner Hero поможет вам практиковать экспозиционную терапию для работы с тревогой. Создавайте сценарии, проводите сеансы и отслеживайте свой прогресс.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    // Warning Section
                    VStack(alignment: .leading, spacing: 12) {
                        // Warning Header
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.body)
                                .foregroundStyle(.orange)
                                .accessibilityHidden(true)
                            
                            Text("Важное предупреждение")
                                .font(.headline)
                                .foregroundStyle(.primary)
                        }
                        .accessibilityElement(children: .combine)
                        
                        // Warning Content
                        VStack(alignment: .leading, spacing: 12) {
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
                        .foregroundStyle(.secondary)
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.orange.opacity(0.08))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                    )
                }
                .padding(.horizontal, 20)
                
                Spacer()
                    .frame(minHeight: 32)
                
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
                        .frame(minHeight: 56)
                }
                .buttonStyle(.borderedProminent)
                .tint(.primary)
                .accessibilityLabel("Продолжить")
                .accessibilityHint("Завершить онбординг и перейти к приложению")
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .background(Color(uiColor: .systemBackground).ignoresSafeArea())
        .scrollDismissesKeyboard(.interactively)
    }
}

#Preview {
    OnboardingView()
}
