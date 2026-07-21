import AVFoundation
import Foundation

/// The voice that runs a PMR session (spec §5).
///
/// Behind a protocol for two reasons. The near one: tests drive the flow without
/// waking a synthesizer. The far one: the spec's endgame is **static audio files
/// in the bundle**, not runtime TTS — `AVSpeechSynthesizer` is the prototype
/// (§11.4), and swapping it must not reach into the session screen.
@MainActor
protocol PMRVoice: AnyObject {
    var isSpeaking: Bool { get }
    /// Speaks a line, replacing anything still in the queue. Empty text is a
    /// no-op, which is what makes a silent pause cue simply do nothing.
    func speak(_ text: String, delivery: PMRDelivery)
    func stop()
}

/// The prototype voice: the system synthesizer, free forever and offline.
///
/// Speaks through **SSML** rather than a plain string, which is what buys the
/// three things a relaxation script needs and a flat utterance cannot give:
/// per-line pace and pitch (`<prosody>`), real pauses at the sentence seams
/// (`<break>`), and per-word stress (`<phoneme>`).
///
/// All three were verified against the system Russian voice by synthesizing to a
/// buffer and comparing the audio — `<break time="2s">` lands within 1.5% of two
/// seconds, and `<phoneme>` produces byte-identical output to the older
/// `AVSpeechSynthesisIPANotationAttribute` route. The combining acute accent
/// (U+0301), the usual trick for Russian stress, is silently stripped and does
/// nothing.
///
/// ⚠️ SSML and the utterance properties are mutually exclusive: `AVSpeechUtterance`
/// documents that `rate`, `pitchMultiplier` and `volume` are ignored on an SSML
/// utterance. Everything prosodic therefore has to go through the markup.
@MainActor
final class SystemPMRVoice: NSObject, PMRVoice {
    private let synthesizer = AVSpeechSynthesizer()

    var isSpeaking: Bool { synthesizer.isSpeaking }

    func speak(_ text: String, delivery: PMRDelivery = .instruction) {
        guard !text.isEmpty else { return }

        // Replacing rather than queueing: cues are scheduled on the session
        // clock, so a line that has not finished by the time the next one is due
        // is late and would push everything after it further behind.
        synthesizer.stopSpeaking(at: .immediate)

        let utterance = Self.utterance(for: text, delivery: delivery)
        utterance.voice = Self.preferredVoice()
        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }

    // MARK: Utterance

    /// Builds the SSML utterance, falling back to a plain one if the markup is
    /// rejected.
    ///
    /// The fallback is not defensive habit: `init(ssmlRepresentation:)` returns
    /// nil on invalid SSML, and a nil here would mean a **silent exercise** —
    /// the one failure this feature cannot survive, since the user is lying with
    /// their eyes closed waiting to be told what to do.
    static func utterance(for text: String, delivery: PMRDelivery) -> AVSpeechUtterance {
        if let ssml = AVSpeechUtterance(ssmlRepresentation: markup(for: text, delivery: delivery)) {
            return ssml
        }
        let plain = AVSpeechUtterance(string: text)
        plain.rate = AVSpeechUtteranceDefaultSpeechRate * delivery.plainRateMultiplier
        plain.pitchMultiplier = delivery.pitch
        return plain
    }

    /// The SSML for a line. Internal rather than private so the composition can
    /// be tested without a synthesizer.
    static func markup(for text: String, delivery: PMRDelivery) -> String {
        let body = stressed(breaking(escaped(text)))
        return """
            <speak><prosody rate="\(delivery.ssmlRate)" pitch="\(delivery.ssmlPitch)">\
            \(body)</prosody></speak>
            """
    }

    /// XML-escapes the text **before** any markup is inserted. Without this a
    /// stray `&` in a translation would make the whole line invalid SSML and
    /// silently drop it to the plain fallback.
    private static func escaped(_ text: String) -> String {
        text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }

    /// Turns the punctuation the script already uses into real silence.
    ///
    /// The script is written as short sentences separated by full stops and an
    /// em-dash between an instruction and how to carry it out ("Напряги руки —
    /// сожми кулаки"). Those seams are where a person pauses; the synthesizer's
    /// own pauses are far too short for a relaxation script.
    private static func breaking(_ text: String) -> String {
        text
            .replacingOccurrences(of: ". ", with: ". <break time=\"600ms\"/>")
            .replacingOccurrences(of: " — ", with: " <break time=\"300ms\"/>— ")
    }

    /// Applies the stress dictionary, word by word.
    ///
    /// Only words in `stressOverrides` are touched. The synthesizer's own
    /// Russian dictionary is right about most words, and a wrong IPA
    /// transcription is worse than none — so this stays a short, verified list
    /// rather than a transcription of the whole script.
    private static func stressed(_ text: String) -> String {
        guard !stressOverrides.isEmpty else { return text }
        var result = ""
        var word = ""

        func flush() {
            guard !word.isEmpty else { return }
            if let ipa = stressOverrides[word.lowercased()] {
                result += "<phoneme alphabet=\"ipa\" ph=\"\(ipa)\">\(word)</phoneme>"
            } else {
                result += word
            }
            word = ""
        }

        for character in text {
            if character.isLetter {
                word.append(character)
            } else {
                flush()
                result.append(character)
            }
        }
        flush()
        return result
    }

    /// Words the system voice stresses wrongly, lowercased, with the IPA to use
    /// instead.
    ///
    /// Every entry here was **reported wrong by ear** and then checked to make
    /// sure the transcription is actually accepted — an IPA string the engine
    /// rejects would leave a word worse off than the wrong stress it replaced
    /// (see `PMRVoiceStressTests`). Nothing goes in on suspicion alone.
    ///
    /// ⚠️ This engine understands only a **narrow subset of IPA**, and silently
    /// drops anything outside it. Three rounds of listening found:
    ///
    /// - `ɡ` U+0261 (the proper IPA voiced velar stop) — dropped. Use ASCII `g`.
    /// - `ʐ` (retroflex, for Russian ж) — dropped. Use `ʒ`.
    /// - **Reduced vowels `ɐ` `ə` `ɪ` `ʊ` — dropped.** Use the full `a e i o u`.
    ///
    /// The last one is the important rule and it inverts the obvious approach:
    /// do **not** pre-reduce the vowels. The engine applies Russian reduction
    /// itself, from the stress mark — feeding it [ɐ] where it expects [a] leaves
    /// it with nothing to reduce, and the vowel disappears. That is what turned
    /// «глаза» into "глза" and «расположись» into "расплжись".
    ///
    /// So: write the word as it is *spelled* phonemically, mark the stress, and
    /// let the engine do the rest. Only ʲ (palatalisation), ʒ, ʃ and ɨ are
    /// carried over from the wider IPA set, all measured as intact.
    ///
    static var stressOverrides: [String: String] = [
        // расположи́сь — «Найди тихое место, расположись удобно.»
        "расположись": "raspalaˈʒɨsʲ",
        // глаза́ — «Напряги глаза и нос.»
        "глаза": "glaˈza",
        // сожми́ — кулак, кулаки, зубы.
        "сожми": "saˈʒmʲi",
        // согни́ — руку, руки.
        "согни": "saˈgnʲi",
        // вы́прями — ногу в колене, ноги. Приставка вы- в совершенном виде
        // всегда ударная, и это самая частая ошибка синтезатора.
        "выпрями": "ˈvɨprʲimʲi",
        // сведи́ — лопатки.
        "сведи": "svʲiˈdʲi",
        // поджми́ — пальцы.
        "поджми": "padˈʒmʲi",
        // го́лень — правую/левую голень.
        "голень": "ˈgolʲinʲ",
        // ступню́ — правую/левую ступню.
        "ступню": "stupˈnʲu",
        // предпле́чье — правую/левую кисть и предплечье.
        "предплечье": "prʲidˈplʲetʃje",
    ]

    // MARK: Voice selection

    /// The best installed voice for the app's language.
    ///
    /// Explicitly **not** `AVSpeechSynthesisVoice(language:)`: that returns the
    /// system default, which is the compact voice even when the user has
    /// downloaded an enhanced or premium one. On the simulator the only Russian
    /// voice is `com.apple.voice.super-compact.ru-RU.Milena`, and it sounds like
    /// its name — picking the best available is most of the quality difference
    /// this exercise can get for free.
    ///
    /// Language, not the device's: the script is localized, and a Russian
    /// sentence read by an English voice is unusable.
    static func preferredVoice() -> AVSpeechSynthesisVoice? {
        let language = Locale.preferredLanguages.first ?? "en-US"
        return best(for: language)
            ?? best(for: "en-US")
            ?? AVSpeechSynthesisVoice(language: language)
    }

    /// Highest-quality installed voice whose language matches, by prefix so that
    /// "ru" matches "ru-RU".
    static func best(
        for language: String,
        from voices: [AVSpeechSynthesisVoice] = AVSpeechSynthesisVoice.speechVoices()
    ) -> AVSpeechSynthesisVoice? {
        let code = language.prefix(2).lowercased()
        return voices
            .filter { $0.language.lowercased().hasPrefix(code) }
            .max { $0.quality.rawValue < $1.quality.rawValue }
    }

}

// MARK: - Delivery → prosody

extension PMRDelivery {
    /// SSML rate. Percentages rather than the utterance's `rate` scale, which is
    /// both non-linear and ignored on SSML utterances.
    var ssmlRate: String {
        switch self {
        case .settling: "80%"
        case .instruction: "95%"
        case .releasing: "80%"
        }
    }

    /// Lower on the settling and releasing lines: a dropping pitch is what makes
    /// a sentence sound like it is coming to rest rather than asking something.
    var ssmlPitch: String {
        switch self {
        case .settling: "-10%"
        case .instruction: "default"
        case .releasing: "-15%"
        }
    }

    /// Only for the plain-utterance fallback. The `rate` scale is compressed —
    /// halving it lengthens the audio by about a third — so these are gentler
    /// than the SSML percentages look.
    var plainRateMultiplier: Float {
        switch self {
        case .settling, .releasing: 0.85
        case .instruction: 0.95
        }
    }

    var pitch: Float {
        switch self {
        case .settling: 0.95
        case .instruction: 1.0
        case .releasing: 0.92
        }
    }
}
