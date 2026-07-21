import AVFoundation
import Foundation

/// The audio session for a PMR run (spec §5).
///
/// `.playback` is the category that makes the voice keep going when the screen
/// goes dark — which is the whole point of the exercise, since the user is lying
/// with their eyes closed. It also means the voice **ignores the silent switch**:
/// deliberate, because a session that plays nothing is not a quieter session,
/// it is a broken one.
///
/// Paired with `UIBackgroundModes = audio` in the generated Info.plist.
@MainActor
final class AudioSessionController {

    /// Called when something else takes the audio route — a phone call, an
    /// alarm. The session pauses rather than talking over it.
    var onInterruptionBegan: (() -> Void)?
    /// Called when the interruption is over **and** the system says it is fine
    /// to resume. Resuming is still the user's decision — see the session
    /// screen: the script does not restart itself mid-instruction.
    var onInterruptionEnded: (() -> Void)?

    private var observer: NSObjectProtocol?

    func activate() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .spokenAudio)
        try session.setActive(true)
        observeInterruptions()
    }

    func deactivate() {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
            self.observer = nil
        }
        // Letting other audio come back up rather than leaving the route ducked.
        try? AVAudioSession.sharedInstance().setActive(
            false,
            options: .notifyOthersOnDeactivation
        )
    }

    private func observeInterruptions() {
        guard observer == nil else { return }
        observer = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] notification in
            MainActor.assumeIsolated {
                self?.handle(notification)
            }
        }
    }

    private func handle(_ notification: Notification) {
        guard
            let info = notification.userInfo,
            let raw = info[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: raw)
        else { return }

        switch type {
        case .began:
            onInterruptionBegan?()
        case .ended:
            let optionsRaw = info[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsRaw)
            guard options.contains(.shouldResume) else { return }
            try? AVAudioSession.sharedInstance().setActive(true)
            onInterruptionEnded?()
        @unknown default:
            break
        }
    }
}
