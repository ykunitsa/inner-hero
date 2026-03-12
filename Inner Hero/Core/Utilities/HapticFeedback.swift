import SwiftUI

#if os(iOS)
import UIKit
#endif

/// Unified haptic feedback utility. Call from View (UI layer) only.
enum HapticFeedback {

    // MARK: - Impact

    /// Impact with given style. Use for physical "bump" feedback.
    static func impact(_ style: ImpactStyle) {
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: style.uiStyle)
        generator.impactOccurred()
        #endif
    }

    /// Light impact — subtle tap (e.g. selection, add step).
    static func light() {
        impact(.light)
    }

    /// Medium impact — noticeable tap (e.g. delete, reorder).
    static func medium() {
        impact(.medium)
    }

    /// Heavy impact — strong tap.
    static func heavy() {
        impact(.heavy)
    }

    // MARK: - Notification

    /// Notification feedback — success / error / warning.
    static func notification(_ type: NotificationType) {
        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type.uiType)
        #endif
    }

    /// Success notification (e.g. save completed, step completed).
    static func success() {
        notification(.success)
    }

    /// Error notification (e.g. save failed).
    static func error() {
        notification(.error)
    }

    /// Warning notification (e.g. destructive action).
    static func warning() {
        notification(.warning)
    }

    // MARK: - Selection

    /// Selection changed (e.g. picker, segmented control).
    static func selection() {
        #if os(iOS)
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
        #endif
    }

    // MARK: - Styles (internal mapping to UIKit)

    enum ImpactStyle {
        case light, medium, heavy
        #if os(iOS)
        var uiStyle: UIImpactFeedbackGenerator.FeedbackStyle {
            switch self {
            case .light: return .light
            case .medium: return .medium
            case .heavy: return .heavy
            }
        }
        #endif
    }

    enum NotificationType {
        case success, error, warning
        #if os(iOS)
        var uiType: UINotificationFeedbackGenerator.FeedbackType {
            switch self {
            case .success: return .success
            case .error: return .error
            case .warning: return .warning
            }
        }
        #endif
    }
}
