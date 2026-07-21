import SwiftUI

#if os(iOS)
import UIKit
#endif

/// Keeps the screen from auto-locking while a view is on screen.
///
/// **A recorded exception to the "no UIKit" rule** (CLAUDE.md, plan §2 decision 8).
/// iOS 26 has no SwiftUI equivalent of `isIdleTimerDisabled`, and without it the
/// breathing session breaks in *both* channels at once: the display sleeps after
/// 30 s…2 min, and CoreHaptics stops with it. The exercise would simply go dark
/// and silent mid-session with no explanation.
///
/// Kept to this one file and to sessions only. The flag is released on
/// disappear, so auto-lock is restored the moment the circle goes away — the
/// app never leaves the device awake behind the user's back.
private struct KeepScreenAwakeModifier: ViewModifier {
    let isActive: Bool

    func body(content: Content) -> some View {
        content
            .onAppear { apply(isActive) }
            .onChange(of: isActive) { _, newValue in apply(newValue) }
            .onDisappear { apply(false) }
    }

    private func apply(_ keepAwake: Bool) {
        #if os(iOS)
        UIApplication.shared.isIdleTimerDisabled = keepAwake
        #endif
    }
}

extension View {
    /// Suppresses auto-lock while this view is visible and `isActive` is true.
    func keepScreenAwake(_ isActive: Bool = true) -> some View {
        modifier(KeepScreenAwakeModifier(isActive: isActive))
    }
}
