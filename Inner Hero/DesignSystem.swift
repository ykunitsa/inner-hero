//
//  DesignSystem.swift
//  Inner Hero
//
//  Unified Design System based on Apple HIG
//  Reference: DESIGN_GUIDELINES.md
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

// MARK: - Spacing

enum Spacing {
    /// 4pt - Минимальный gap между элементами
    static let xxxs: CGFloat = 4
    
    /// 8pt - Tight spacing (icon + text)
    static let xxs: CGFloat = 8
    
    /// 12pt - Compact spacing (form fields, небольшие элементы)
    static let xs: CGFloat = 12
    
    /// 16pt - Standard spacing (список карточек)
    static let sm: CGFloat = 16
    
    /// 20pt - Section spacing, horizontal padding
    static let md: CGFloat = 20
    
    /// 24pt - Card padding, vertical padding
    static let lg: CGFloat = 24
    
    /// 32pt - Major sections
    static let xl: CGFloat = 32
    
    /// 40pt - Screen sections
    static let xxl: CGFloat = 40
    
    /// 48pt - Hero sections
    static let xxxl: CGFloat = 48
}

// MARK: - Corner Radius

enum CornerRadius {
    /// 8pt - Small badges, chips
    static let sm: CGFloat = 8
    
    /// 12pt - Standard cards, buttons, inputs
    static let md: CGFloat = 12
    
    /// 16pt - Large cards, important elements
    static let lg: CGFloat = 16
    
    /// 20pt - Prominent cards, sheets
    static let xl: CGFloat = 20
    
    /// 24pt - Hero cards, special elements
    static let xxl: CGFloat = 24
}

// MARK: - Touch Targets

enum TouchTarget {
    /// Минимальный размер для touch target (Apple HIG)
    static let minimum: CGFloat = 44
}

// MARK: - Opacity

enum Opacity {
    // BACKGROUNDS
    static let subtleBackground: Double = 0.05
    static let softBackground: Double = 0.08
    static let mediumBackground: Double = 0.15
    static let prominentBackground: Double = 0.2
    
    // BORDERS
    static let subtleBorder: Double = 0.2
    static let standardBorder: Double = 0.3
    static let emphasizedBorder: Double = 0.5
    
    // SHADOWS
    static let lightShadow: Double = 0.05
    static let standardShadow: Double = 0.1
    static let darkShadow: Double = 0.3
}

// MARK: - Shadow

struct ShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
    
    static func subtle(colorScheme: ColorScheme) -> ShadowStyle {
        ShadowStyle(
            color: .black.opacity(colorScheme == .dark ? Opacity.darkShadow : Opacity.lightShadow),
            radius: 8,
            x: 0,
            y: 2
        )
    }
    
    static func prominent(colorScheme: ColorScheme) -> ShadowStyle {
        ShadowStyle(
            color: .black.opacity(colorScheme == .dark ? Opacity.darkShadow : Opacity.standardShadow),
            radius: 12,
            x: 0,
            y: 4
        )
    }
    
    static func accent(color: Color) -> ShadowStyle {
        ShadowStyle(
            color: color.opacity(Opacity.standardBorder),
            radius: 12,
            x: 0,
            y: 6
        )
    }
}

// MARK: - App Theme

enum AppTheme {
    /// Primary accent color для приложения
    static let primaryColor: Color = .teal
    
    /// Secondary accent color
    static let secondaryColor: Color = .mint
    
    /// Функция для определения anxiety level color
    static func anxietyColor(for level: Int) -> Color {
        switch level {
        case 0...3:
            return .green       // Low anxiety
        case 4...6:
            return .orange      // Moderate anxiety
        case 7...10:
            return .red         // High anxiety
        default:
            return .gray
        }
    }
    
    /// Цвета для различных состояний
    enum State {
        static let success: Color = .green
        static let warning: Color = .orange
        static let error: Color = .red
        static let info: Color = .blue
        static let neutral: Color = .gray
    }
}

// MARK: - Animation Presets

enum AnimationPreset {
    /// Стандартная анимация для большинства UI изменений
    static let standard: Animation = .easeInOut(duration: 0.3)
    
    /// Быстрая анимация для мелких изменений
    static let quick: Animation = .easeOut(duration: 0.2)
    
    /// Spring анимация для естественных движений
    static let spring: Animation = .spring(response: 0.4, dampingFraction: 0.7)
    
    /// Плавная анимация для fade-in эффектов
    static let fadeIn: Animation = .easeIn(duration: 0.4)
    
    /// Staggered delay для списков
    static func staggered(index: Int) -> Animation {
        .easeOut(duration: 0.3).delay(Double(index) * 0.05)
    }
}

// MARK: - View Modifiers

// MARK: Card Style
struct CardStyle: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    let cornerRadius: CGFloat
    let padding: CGFloat
    
    init(cornerRadius: CGFloat = CornerRadius.lg, padding: CGFloat = Spacing.lg) {
        self.cornerRadius = cornerRadius
        self.padding = padding
    }
    
    func body(content: Content) -> some View {
        #if canImport(UIKit)
        let backgroundColor = Color(uiColor: .secondarySystemGroupedBackground)
        #else
        let backgroundColor = Color.gray.opacity(0.1)  // Fallback для других платформ
        #endif
        
        return content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(backgroundColor)
            )
            .shadow(
                color: .black.opacity(colorScheme == .dark ? Opacity.darkShadow : Opacity.lightShadow),
                radius: 8,
                y: 2
            )
    }
}

extension View {
    func cardStyle(cornerRadius: CGFloat = CornerRadius.lg, padding: CGFloat = Spacing.lg) -> some View {
        modifier(CardStyle(cornerRadius: cornerRadius, padding: padding))
    }
}

// MARK: Accent Card Style (с цветным border)
struct AccentCardStyle: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    let accentColor: Color
    let cornerRadius: CGFloat
    let padding: CGFloat
    
    init(accentColor: Color = AppTheme.primaryColor, 
         cornerRadius: CGFloat = CornerRadius.lg, 
         padding: CGFloat = Spacing.lg) {
        self.accentColor = accentColor
        self.cornerRadius = cornerRadius
        self.padding = padding
    }
    
    func body(content: Content) -> some View {
        #if canImport(UIKit)
        let backgroundColor = Color(uiColor: .secondarySystemGroupedBackground)
        #else
        let backgroundColor = Color.gray.opacity(0.1)  // Fallback для других платформ
        #endif
        
        return content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(accentColor.opacity(Opacity.standardBorder), lineWidth: 1.5)
            )
            .shadow(
                color: accentColor.opacity(Opacity.subtleBorder),
                radius: 12,
                y: 4
            )
    }
}

extension View {
    func accentCardStyle(
        accentColor: Color = AppTheme.primaryColor,
        cornerRadius: CGFloat = CornerRadius.lg,
        padding: CGFloat = Spacing.lg
    ) -> some View {
        modifier(AccentCardStyle(accentColor: accentColor, cornerRadius: cornerRadius, padding: padding))
    }
}

// MARK: Touch Target Minimum Size
struct TouchTargetStyle: ViewModifier {
    let width: CGFloat
    let height: CGFloat
    
    init(width: CGFloat = TouchTarget.minimum, height: CGFloat = TouchTarget.minimum) {
        self.width = width
        self.height = height
    }
    
    func body(content: Content) -> some View {
        content
            .frame(minWidth: width, minHeight: height)
            .contentShape(Rectangle())
    }
}

extension View {
    func touchTarget(width: CGFloat = TouchTarget.minimum, height: CGFloat = TouchTarget.minimum) -> some View {
        modifier(TouchTargetStyle(width: width, height: height))
    }
}

// MARK: - Haptic Feedback Helpers

#if canImport(UIKit)
enum HapticFeedback {
    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    static func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
    
    static func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
    
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}
#else
// Заглушка для macOS
enum HapticFeedback {
    static func success() { }
    static func warning() { }
    static func error() { }
    static func impact(_ style: Int = 0) { }
    static func selection() { }
}
#endif

// MARK: - Common View Components

// MARK: Section Label
struct SectionLabel: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundStyle(.secondary)
    }
}

// MARK: Badge View
struct BadgeView: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.caption.weight(.medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Capsule().fill(color))
    }
}

// MARK: Icon with Text
struct IconLabel: View {
    let icon: String
    let text: String
    let color: Color?
    
    init(icon: String, text: String, color: Color? = nil) {
        self.icon = icon
        self.text = text
        self.color = color
    }
    
    var body: some View {
        HStack(spacing: Spacing.xxs) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
                .font(.caption)
        }
        .foregroundStyle(color ?? .secondary)
    }
}

// MARK: - Preview Examples

#Preview("Design System Showcase") {
    ScrollView {
        VStack(spacing: Spacing.xl) {
            // Typography
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Typography")
                    .font(.title2.weight(.semibold))
                
                Group {
                    Text("Large Title").font(.largeTitle)
                    Text("Title").font(.title)
                    Text("Title 2").font(.title2)
                    Text("Title 3").font(.title3)
                    Text("Headline").font(.headline)
                    Text("Body").font(.body)
                    Text("Callout").font(.callout)
                    Text("Subheadline").font(.subheadline)
                    Text("Footnote").font(.footnote)
                    Text("Caption").font(.caption)
                    Text("Caption 2").font(.caption2)
                }
            }
            .cardStyle()
            
            // Cards
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Standard Card")
                    .font(.headline)
                Text("This is a standard card with default styling")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .cardStyle()
            
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Accent Card")
                    .font(.headline)
                Text("This card has an accent border")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .accentCardStyle(accentColor: .teal)
            
            // Badges
            HStack(spacing: Spacing.xs) {
                BadgeView(text: "Success", color: .green)
                BadgeView(text: "Warning", color: .orange)
                BadgeView(text: "Error", color: .red)
                BadgeView(text: "Info", color: .blue)
            }
            .cardStyle()
            
            // Icon Labels
            VStack(alignment: .leading, spacing: Spacing.xs) {
                IconLabel(icon: "clock", text: "2 hours ago")
                IconLabel(icon: "checkmark.circle", text: "Completed", color: .green)
                IconLabel(icon: "timer", text: "5:00", color: .orange)
            }
            .cardStyle()
            
            // Anxiety Colors
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Anxiety Levels")
                    .font(.headline)
                
                ForEach([0, 3, 5, 7, 10], id: \.self) { level in
                    HStack {
                        Circle()
                            .fill(AppTheme.anxietyColor(for: level))
                            .frame(width: 20, height: 20)
                        Text("Level \(level)")
                            .font(.body)
                        Spacer()
                    }
                }
            }
            .cardStyle()
        }
        .padding(Spacing.md)
    }
    .background {
        #if canImport(UIKit)
        Color(uiColor: .systemGroupedBackground)
        #else
        Color.gray.opacity(0.05)  // Fallback для других платформ
        #endif
    }
}

