//
//  PMRVoiceTests.swift
//  Inner HeroTests
//
//  Coverage for the SSML the voice builds (spec §5). What is testable here is
//  the *markup*: that it is well-formed, that the pauses and prosody land where
//  intended, and that a hostile string cannot silence the exercise. How it
//  actually sounds is not testable and is not claimed.
//

import AVFoundation
import Foundation
import Testing
@testable import Inner_Hero

@Suite("PMR voice: SSML composition")
@MainActor
struct PMRVoiceMarkupTests {

    @Test("Every line is wrapped in speak and prosody")
    func wrapping() {
        let markup = SystemPMRVoice.markup(for: "Напряги руки.", delivery: .instruction)
        #expect(markup.hasPrefix("<speak><prosody"))
        #expect(markup.hasSuffix("</prosody></speak>"))
        #expect(markup.contains("Напряги руки."))
    }

    @Test("Delivery drives rate and pitch")
    func deliveryDrivesProsody() {
        let settling = SystemPMRVoice.markup(for: "Готово.", delivery: .settling)
        let instruction = SystemPMRVoice.markup(for: "Готово.", delivery: .instruction)
        let releasing = SystemPMRVoice.markup(for: "Готово.", delivery: .releasing)

        #expect(settling.contains("rate=\"80%\""))
        #expect(instruction.contains("rate=\"95%\""))
        #expect(releasing.contains("pitch=\"-15%\""))
        // The release phase is the skill being trained — it must not be read at
        // the same clip as an instruction.
        #expect(settling != instruction)
        #expect(releasing != instruction)
    }

    @Test("Sentence seams become real pauses")
    func sentencePauses() {
        let markup = SystemPMRVoice.markup(
            for: "Расслабь. Дай напряжению уйти.",
            delivery: .releasing
        )
        #expect(markup.contains("<break time=\"600ms\"/>"))
    }

    @Test("The dash between instruction and how-to gets a shorter pause")
    func dashPause() {
        let markup = SystemPMRVoice.markup(
            for: "Напряги руки — сожми кулаки.",
            delivery: .instruction
        )
        #expect(markup.contains("<break time=\"300ms\"/>"))
    }

    /// A stray `&` or `<` in a translation would otherwise make the line invalid
    /// SSML — and invalid SSML means the voice says nothing, which is the one
    /// failure this exercise cannot survive.
    @Test("Markup characters in the text are escaped")
    func escaping() {
        let markup = SystemPMRVoice.markup(for: "A & B < C > D", delivery: .instruction)
        #expect(markup.contains("&amp;"))
        #expect(markup.contains("&lt;"))
        #expect(markup.contains("&gt;"))
        #expect(!markup.contains("A & B"))
    }

    /// The real contract: whatever the text, the synthesizer must accept it.
    @Test("Every line of every step produces valid SSML")
    func everyCueIsValidSSML() {
        for step in PMRStep.allCases {
            for cue in PMRScript.cues(for: step) where !cue.isSilent {
                let markup = SystemPMRVoice.markup(for: cue.spoken, delivery: cue.delivery)
                #expect(
                    AVSpeechUtterance(ssmlRepresentation: markup) != nil,
                    "SSML rejected for: \(cue.spoken)"
                )
            }
        }
    }

    @Test("A hostile string still yields a usable utterance")
    func hostileStringFallsBack() {
        // Never nil: invalid markup drops to a plain utterance rather than
        // leaving the session silent.
        let utterance = SystemPMRVoice.utterance(
            for: "<<< & >>> \" ' unclosed",
            delivery: .instruction
        )
        #expect(!utterance.speechString.isEmpty)
    }
}

@Suite("PMR voice: choosing a voice")
@MainActor
struct PMRVoiceSelectionTests {

    /// The whole point of not using `AVSpeechSynthesisVoice(language:)`, which
    /// hands back the system default even when a better voice is installed.
    @Test("The best installed voice for the language wins")
    func picksHighestQuality() {
        let voices = AVSpeechSynthesisVoice.speechVoices()
        for language in ["ru-RU", "en-US"] {
            guard let chosen = SystemPMRVoice.best(for: language, from: voices) else { continue }
            let matching = voices.filter {
                $0.language.lowercased().hasPrefix(language.prefix(2).lowercased())
            }
            let bestQuality = matching.map(\.quality.rawValue).max()
            #expect(chosen.quality.rawValue == bestQuality)
        }
    }

    @Test("Language matches by prefix, so ru finds ru-RU")
    func matchesByPrefix() {
        let voices = AVSpeechSynthesisVoice.speechVoices()
        guard SystemPMRVoice.best(for: "ru-RU", from: voices) != nil else { return }
        #expect(SystemPMRVoice.best(for: "ru", from: voices) != nil)
    }

    @Test("An unknown language yields nothing rather than a wrong-language voice")
    func unknownLanguageIsNil() {
        // A Russian script read by a Japanese voice would be worse than silence.
        #expect(SystemPMRVoice.best(for: "zz-ZZ") == nil)
    }

    @Test("A voice is always chosen for the session")
    func alwaysResolvesSomething() {
        #expect(SystemPMRVoice.preferredVoice() != nil)
    }
}

@Suite("PMR voice: stress overrides")
@MainActor
struct PMRVoiceStressTests {

    /// Words are only touched when they are in the dictionary — the synthesizer
    /// is right about most of them, and a wrong transcription is worse than none.
    @Test("Nothing is transcribed when the dictionary is empty")
    func emptyDictionaryLeavesTextAlone() {
        let saved = SystemPMRVoice.stressOverrides
        defer { SystemPMRVoice.stressOverrides = saved }
        SystemPMRVoice.stressOverrides = [:]

        let markup = SystemPMRVoice.markup(for: "Напряги руки.", delivery: .instruction)
        #expect(!markup.contains("<phoneme"))
    }

    @Test("A listed word is wrapped in phoneme, its neighbours are not")
    func listedWordIsTranscribed() {
        let saved = SystemPMRVoice.stressOverrides
        defer { SystemPMRVoice.stressOverrides = saved }
        SystemPMRVoice.stressOverrides = ["выпрями": "ˈvɨprʲɪmʲɪ"]

        let markup = SystemPMRVoice.markup(for: "Выпрями ногу.", delivery: .instruction)
        #expect(markup.contains("<phoneme alphabet=\"ipa\" ph=\"ˈvɨprʲɪmʲɪ\">Выпрями</phoneme>"))
        #expect(markup.contains("ногу"))
        #expect(!markup.contains("<phoneme alphabet=\"ipa\" ph=\"ˈvɨprʲɪmʲɪ\">ногу"))
    }

    @Test("Matching ignores case but respects word boundaries")
    func matchingRules() {
        let saved = SystemPMRVoice.stressOverrides
        defer { SystemPMRVoice.stressOverrides = saved }
        SystemPMRVoice.stressOverrides = ["руки": "ˈrukʲɪ"]

        // Same word, different case in the sentence.
        #expect(SystemPMRVoice.markup(for: "Руки", delivery: .instruction).contains("<phoneme"))
        // A longer word merely containing it is left alone.
        #expect(!SystemPMRVoice.markup(for: "порукикрест", delivery: .instruction).contains("<phoneme"))
    }

    /// Guards the shipped dictionary. A malformed IPA string makes the whole
    /// line invalid SSML, which drops it to the plain fallback and silently
    /// loses every other bit of prosody on that line.
    ///
    /// This checks that the markup *parses*. That the engine actually
    /// understands each transcription was established separately, by
    /// synthesizing every entry to a buffer and confirming the audio changed —
    /// see the plan, §13. That check needs a real synthesizer and several
    /// seconds, so it stays a manual probe rather than living in this suite.
    @Test("Every shipped stress override yields valid SSML")
    func shippedOverridesAreValid() {
        for (word, ipa) in SystemPMRVoice.stressOverrides {
            #expect(!ipa.isEmpty, "empty transcription for \(word)")
            #expect(word == word.lowercased(), "keys must be lowercased: \(word)")

            let markup = SystemPMRVoice.markup(for: word, delivery: .instruction)
            #expect(markup.contains("<phoneme"), "\(word) was not transcribed")
            #expect(
                AVSpeechUtterance(ssmlRepresentation: markup) != nil,
                "invalid SSML for \(word) [\(ipa)]"
            )
        }
    }

    /// The dictionary is useless if the words it names never reach the voice —
    /// a rename in the script would otherwise leave dead entries behind.
    @Test("Every override actually occurs in a spoken line")
    func overridesAreReachable() {
        let spoken = PMRStep.allCases
            .flatMap { PMRScript.cues(for: $0) }
            .map(\.spoken)
            .joined(separator: " ")
            .lowercased()

        for word in SystemPMRVoice.stressOverrides.keys {
            #expect(spoken.contains(word), "\(word) is not spoken anywhere in the script")
        }
    }

    @Test("Transcribed lines are still valid SSML")
    func transcriptionStaysValid() {
        let saved = SystemPMRVoice.stressOverrides
        defer { SystemPMRVoice.stressOverrides = saved }
        SystemPMRVoice.stressOverrides = ["руки": "ˈrukʲɪ", "напряги": "nəprʲɪˈɡʲi"]

        let markup = SystemPMRVoice.markup(
            for: "Напряги руки — сожми кулаки. Держи.",
            delivery: .instruction
        )
        #expect(AVSpeechUtterance(ssmlRepresentation: markup) != nil)
    }
}
