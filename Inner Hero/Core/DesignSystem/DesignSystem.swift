import SwiftUI
import CoreHaptics

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
        let backgroundColor: Color = {
            if colorScheme == .dark {
                return Color(red: 0.14, green: 0.15, blue: 0.18)
            }
            return Color(red: 0.95, green: 0.97, blue: 1.0)
        }()
        
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
        let backgroundColor: Color = {
            if colorScheme == .dark {
                return Color(red: 0.14, green: 0.15, blue: 0.18)
            }
            return Color(red: 0.95, green: 0.97, blue: 1.0)
        }()
        
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

// MARK: - Haptic Feedback Helpers (CoreHaptics-only, no UIKit)

enum HapticFeedback {
    enum ImpactStyle {
        case light
        case medium
        case heavy
        case soft
        case rigid
    }

    static func success() {
        playTransients([
            (time: 0.0, intensity: 0.55, sharpness: 0.35),
            (time: 0.10, intensity: 0.75, sharpness: 0.45)
        ])
    }

    static func warning() {
        playTransients([
            (time: 0.0, intensity: 0.70, sharpness: 0.55),
            (time: 0.14, intensity: 0.55, sharpness: 0.45)
        ])
    }

    static func error() {
        playTransients([
            (time: 0.0, intensity: 0.80, sharpness: 0.70),
            (time: 0.12, intensity: 0.80, sharpness: 0.70),
            (time: 0.24, intensity: 0.60, sharpness: 0.55)
        ])
    }

    static func impact(_ style: ImpactStyle = .light) {
        let (intensity, sharpness): (Float, Float) = switch style {
        case .light: (0.35, 0.30)
        case .medium: (0.55, 0.45)
        case .heavy: (0.80, 0.60)
        case .soft: (0.25, 0.10)
        case .rigid: (0.60, 0.80)
        }

        playTransients([(time: 0.0, intensity: intensity, sharpness: sharpness)])
    }

    static func selection() {
        playTransients([(time: 0.0, intensity: 0.25, sharpness: 0.15)])
    }

    // MARK: - CoreHaptics internals

    private static var engine: CHHapticEngine?

    private static var supportsHaptics: Bool {
        CHHapticEngine.capabilitiesForHardware().supportsHaptics
    }

    private static func ensureEngineStarted() {
        guard supportsHaptics else { return }
        if engine != nil { return }

        do {
            let newEngine = try CHHapticEngine()
            newEngine.isAutoShutdownEnabled = true
            newEngine.stoppedHandler = { _ in
                engine = nil
            }
            newEngine.resetHandler = {
                do { try engine?.start() } catch { /* no-op */ }
            }
            try newEngine.start()
            engine = newEngine
        } catch {
            engine = nil
        }
    }

    private static func playTransients(_ transients: [(time: TimeInterval, intensity: Float, sharpness: Float)]) {
        guard !transients.isEmpty else { return }
        ensureEngineStarted()
        guard let engine, supportsHaptics else { return }

        let events = transients.map { item in
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: item.intensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: item.sharpness)
                ],
                relativeTime: item.time
            )
        }

        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            // no-op
        }
    }
}

