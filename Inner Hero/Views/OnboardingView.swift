//
//  OnboardingView.swift
//  Inner Hero
//
//  Created by Yauheni Kunitsa on 25.10.25.
//

import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    // HIG: Environment для accessibility
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    var body: some View {
        // HIG: ScrollView для поддержки Dynamic Type с большими размерами шрифта
        ScrollView {
            VStack(spacing: 0) {
                // HIG: Верхний spacer для вертикального центрирования на больших экранах
                Spacer()
                    .frame(minHeight: 48)
                
                // App Icon/Title Section
                VStack(spacing: 20) {
                    // HIG: Декоративная иконка скрыта для VoiceOver
                    Image(systemName: "heart.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.teal.gradient)
                        .accessibilityHidden(true)
                    
                    // HIG: Dynamic Type для заголовка приложения
                    Text("Inner Hero")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(.primary)
                }
                // HIG: Spacing между секциями = 32pt (xl)
                .padding(.bottom, 32)
                
                // Main Content Section
                // HIG: Spacing между элементами = 24pt (lg)
                VStack(alignment: .leading, spacing: 24) {
                    // Brief Explanation
                    // HIG: Spacing внутри блока = 12pt (xs)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Добро пожаловать")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(.primary)
                        
                        // HIG: .body для основного текста с Dynamic Type
                        Text("Inner Hero поможет вам практиковать экспозиционную терапию для работы с тревогой. Создавайте сценарии, проводите сеансы и отслеживайте свой прогресс.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            // HIG: fixedSize для правильного переноса строк
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    // Warning Section
                    // HIG: Spacing внутри блока = 12pt (xs)
                    VStack(alignment: .leading, spacing: 12) {
                        // Warning Header
                        // HIG: Spacing для icon+text = 8pt (xxs)
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.body)
                                .foregroundStyle(.orange)
                                // HIG: VoiceOver будет читать только текст заголовка
                                .accessibilityHidden(true)
                            
                            Text("Важное предупреждение")
                                .font(.headline)
                                .foregroundStyle(.primary)
                        }
                        // HIG: Accessibility - объединяем иконку и текст для VoiceOver
                        .accessibilityElement(children: .combine)
                        
                        // Warning Content
                        // HIG: Spacing между параграфами = 12pt (xs)
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
                    // HIG: Card padding = 20pt (md)
                    .padding(20)
                    // HIG: Semantic background color с opacity
                    .background(
                        // HIG: .continuous для современного скругления углов
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.orange.opacity(0.08))
                    )
                    .overlay(
                        // HIG: Border с opacity для визуальной иерархии
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                    )
                }
                // HIG: Screen horizontal padding = 20pt (md)
                .padding(.horizontal, 20)
                
                // HIG: Spacer между контентом и кнопкой = 32pt (xl)
                Spacer()
                    .frame(minHeight: 32)
                
                // Continue Button
                Button {
                    // HIG: Haptic feedback для важного действия
                    #if os(iOS)
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    #endif
                    
                    // HIG: Условная анимация для Reduce Motion
                    withAnimation(reduceMotion ? .none : .easeInOut(duration: 0.3)) {
                        hasCompletedOnboarding = true
                    }
                } label: {
                    Text("Продолжить")
                        .font(.headline)
                        // HIG: frame для максимальной ширины кнопки
                        .frame(maxWidth: .infinity)
                        // HIG: minHeight для touch target (минимум 44pt)
                        .frame(minHeight: 56)
                }
                // HIG: Native button style для Primary Action
                .buttonStyle(.borderedProminent)
                // HIG: Tint color для акцентной кнопки
                .tint(.teal)
                // HIG: Accessibility label для VoiceOver
                .accessibilityLabel("Продолжить")
                .accessibilityHint("Завершить онбординг и перейти к приложению")
                // HIG: Screen horizontal padding = 20pt (md)
                .padding(.horizontal, 20)
                // HIG: Bottom padding = 40pt (xxl) для safe area
                .padding(.bottom, 40)
            }
        }
        // HIG: Background игнорирует safe area для полного покрытия
        .background(Color(uiColor: .systemBackground).ignoresSafeArea())
        // HIG: Dismiss keyboard при прокрутке (для будущих форм)
        .scrollDismissesKeyboard(.interactively)
    }
}

#Preview {
    OnboardingView()
}
