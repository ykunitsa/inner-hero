import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

// MARK: - Spacing

enum Spacing {
    static let xxxs: CGFloat = 4
    static let xxs: CGFloat = 8
    static let xs: CGFloat = 12
    static let sm: CGFloat = 16
    static let md: CGFloat = 20
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 40
    static let xxxl: CGFloat = 48
}

// MARK: - Corner Radius

enum CornerRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
}

// MARK: - Touch Targets

enum TouchTarget {
    static let minimum: CGFloat = 44
}

// MARK: - Opacity

enum Opacity {
    static let subtleBackground: Double = 0.05
    static let softBackground: Double = 0.08
    static let mediumBackground: Double = 0.15
    static let prominentBackground: Double = 0.2
    static let subtleBorder: Double = 0.2
    static let standardBorder: Double = 0.3
    static let emphasizedBorder: Double = 0.5
    static let lightShadow: Double = 0.05
    static let standardShadow: Double = 0.1
    static let darkShadow: Double = 0.3
}

// MARK: - Text Colors

enum TextColors {
    /// Primary text (adaptive for light/dark mode)
    static let primary: Color = .primary
    
    /// Secondary text (adaptive for light/dark mode)
    static let secondary: Color = .secondary
    
    /// Tertiary text (adaptive for light/dark mode)
    static let tertiary: Color = .secondary.opacity(0.7)
    
    /// Toolbar icons and buttons (adaptive for light/dark mode)
    static let toolbar: Color = .primary
}

// MARK: - App Theme

enum AppTheme {
    static let primaryColor: Color = .teal
    static let secondaryColor: Color = .mint
    
    static func anxietyColor(for level: Int) -> Color {
        switch level {
        case 0...3:
            return .green
        case 4...6:
            return .orange
        case 7...10:
            return .red
        default:
            return .gray
        }
    }
    
    enum State {
        static let success: Color = .green
        static let warning: Color = .orange
        static let error: Color = .red
        static let info: Color = .blue
        static let neutral: Color = .gray
    }
}

// MARK: - View Modifiers

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
        let backgroundColor = Color.gray.opacity(0.1)
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
        let backgroundColor = Color.gray.opacity(0.1)
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
enum HapticFeedback {
    static func success() { }
    static func warning() { }
    static func error() { }
    static func impact(_ style: Int = 0) { }
    static func selection() { }
}
#endif

