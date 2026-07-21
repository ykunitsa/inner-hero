//
//  PMRScriptTests.swift
//  Inner HeroTests
//
//  Coverage for the script engine (spec §5): the clinical timings, the shape of
//  each ladder step's sequence, and the persisted rawValues.
//

import Foundation
import Testing
@testable import Inner_Hero

// MARK: - Timings

@Suite("PMR script: clinical timings")
struct PMRScriptTimingTests {

    /// Spec §5 calls this out as КРИТИЧНО: 5–7 s, and never the 30–45 s figure
    /// by accident.
    @Test("Tension lasts 5–7 seconds on every step that tenses")
    func tensionWindow() {
        for step in PMRStep.allCases where step.usesTension {
            let tenseCues = PMRScript.cues(for: step).filter { $0.phase == .tense }
            #expect(!tenseCues.isEmpty, "\(step) tenses but produced no tense cues")
            for cue in tenseCues {
                #expect(cue.duration >= 5 && cue.duration <= 7)
            }
        }
    }

    /// The release phase *is* the skill being trained (spec §5) — 30–45 s, and
    /// emphatically not 7.
    @Test("Release lasts 30–45 seconds on the group-based steps")
    func releaseWindow() {
        for step in PMRStep.allCases where step != .cueControlled {
            let releaseCues = PMRScript.cues(for: step).filter { $0.phase == .release }
            #expect(!releaseCues.isEmpty)
            for cue in releaseCues {
                #expect(cue.duration >= 30 && cue.duration <= 45)
            }
        }
    }

    @Test("The pause between groups lasts 10–15 seconds")
    func pauseWindow() {
        for step in PMRStep.allCases where step != .cueControlled {
            for cue in PMRScript.cues(for: step).filter({ $0.phase == .pause }) {
                #expect(cue.duration >= 10 && cue.duration <= 15)
            }
        }
    }

    @Test("Total duration is the sum of the cues")
    func totalIsTheSum() {
        for step in PMRStep.allCases {
            let summed = PMRScript.cues(for: step).reduce(0) { $0 + $1.duration }
            #expect(PMRScript.totalDuration(for: step) == summed)
        }
    }

    @Test("A step's estimated duration comes from its script")
    func estimateIsDerived() {
        for step in PMRStep.allCases {
            #expect(step.estimatedDuration == PMRScript.totalDuration(for: step))
        }
    }

    /// Tuning the timings must move the estimate — that is the whole reason the
    /// step descriptions carry no hardcoded minutes.
    @Test("Shorter timings produce a shorter script")
    func timingsAreParameters() {
        var faster = PMRScript.Timings.canonical
        faster.release = 30
        faster.pause = 10

        #expect(
            PMRScript.totalDuration(for: .fourGroups, timings: faster)
                < PMRScript.totalDuration(for: .fourGroups)
        )
    }
}

// MARK: - Shape

@Suite("PMR script: sequence shape")
struct PMRScriptShapeTests {

    @Test("Every step opens with an intro and closes with an outro")
    func introAndOutro() {
        for step in PMRStep.allCases {
            let cues = PMRScript.cues(for: step)
            #expect(cues.first?.phase == .intro)
            #expect(cues.last?.phase == .outro)
        }
    }

    @Test("Each group is tensed once per configured cycle")
    func tensionCycles() {
        let timings = PMRScript.Timings.canonical
        for step in PMRStep.allCases where step.usesTension {
            let tenseCount = PMRScript.cues(for: step).filter { $0.phase == .tense }.count
            #expect(tenseCount == step.groups.count * timings.tensionCycles)
        }
    }

    @Test("Every tension is followed by a release")
    func tensionIsAlwaysReleased() {
        for step in PMRStep.allCases where step.usesTension {
            let cues = PMRScript.cues(for: step)
            for (index, cue) in cues.enumerated() where cue.phase == .tense {
                #expect(cues[index + 1].phase == .release)
                #expect(cues[index + 1].group == cue.group)
            }
        }
    }

    /// The recall step trains releasing *without* tensing first — a stray tense
    /// cue here would quietly turn it back into the step above it.
    @Test("The recall step never tenses")
    func recallNeverTenses() {
        let cues = PMRScript.cues(for: .fourGroupsRecall)
        #expect(!cues.contains { $0.phase == .tense })
        #expect(cues.filter { $0.phase == .release }.count == PMRStep.fourGroupsRecall.groups.count)
    }

    @Test("The cue-controlled step has no muscle groups at all")
    func cueControlledHasNoGroups() {
        #expect(PMRStep.cueControlled.groups.isEmpty)
        #expect(PMRScript.cues(for: .cueControlled).allSatisfy { $0.group == nil })
    }

    @Test("Pauses sit between groups, never after the last one")
    func pausesBetweenGroupsOnly() {
        for step in PMRStep.allCases where !step.groups.isEmpty {
            let cues = PMRScript.cues(for: step)
            let pauseCount = cues.filter { $0.phase == .pause }.count
            #expect(pauseCount == step.groups.count - 1)
            // The outro is the seam after the last group.
            #expect(cues[cues.count - 2].phase != .pause)
        }
    }

    @Test("Groups are worked in the order the step declares")
    func groupOrderIsPreserved() {
        for step in PMRStep.allCases where !step.groups.isEmpty {
            let worked = PMRScript.cues(for: step)
                .filter { $0.phase == .tense || $0.phase == .release }
                .compactMap(\.group)
            var seen: [PMRMuscleGroup] = []
            for group in worked where seen.last != group {
                seen.append(group)
            }
            #expect(seen == step.groups)
        }
    }
}

// MARK: - Voice and screen

@Suite("PMR script: what is spoken and shown")
struct PMRScriptContentTests {

    /// The pause is the only silence in the script (plan §2, decision 2). If
    /// another phase ever goes quiet, the user is sitting in dead air with their
    /// eyes closed and no way to know the session is still running.
    @Test("Only the pause is silent")
    func onlyPauseIsSilent() {
        for step in PMRStep.allCases {
            for cue in PMRScript.cues(for: step) {
                #expect(cue.isSilent == (cue.phase == .pause))
            }
        }
    }

    /// The screen must always have something to show, including during the
    /// pause — a dimmed blank screen does not answer "is this still running?".
    @Test("Every cue has a headline")
    func everyCueHasAHeadline() {
        for step in PMRStep.allCases {
            for cue in PMRScript.cues(for: step) {
                #expect(!cue.headline.isEmpty)
            }
        }
    }

    /// Naming the group without saying how to tense it is useless to someone
    /// who has just opened their eyes mid-session (plan §2, decision 5).
    @Test("Tension cues carry the instruction, not just the group name")
    func tensionCuesCarryInstructions() {
        for step in PMRStep.allCases where step.usesTension {
            for cue in PMRScript.cues(for: step) where cue.phase == .tense {
                #expect(cue.detail == cue.group?.tensingCue)
                #expect(cue.detail?.isEmpty == false)
            }
        }
    }

    @Test("Every muscle group names itself and how to tense it")
    func everyGroupIsDescribed() {
        for group in PMRMuscleGroup.allCases {
            #expect(!group.title.isEmpty)
            #expect(!group.tensingCue.isEmpty)
        }
    }

    /// Hearing the identical sentence twice in a row reads as a stuck recording.
    @Test("The two release cycles do not repeat the same words")
    func releaseCyclesDiffer() {
        let releases = PMRScript.cues(for: .fourGroups)
            .filter { $0.phase == .release && $0.group == .arms }
            .map(\.spoken)
        #expect(releases.count == 2)
        #expect(releases[0] != releases[1])
    }
}

// MARK: - Persistence contract

@Suite("PMR: persisted rawValues")
struct PMRRawValueTests {

    /// Renaming any of these silently orphans every session already logged
    /// (CLAUDE.md). Pinned here so the rename shows up as a failing test.
    @Test("Step rawValues are pinned")
    func stepRawValues() {
        #expect(PMRStep.sixteenGroups.rawValue == "sixteenGroups")
        #expect(PMRStep.sevenGroups.rawValue == "sevenGroups")
        #expect(PMRStep.fourGroups.rawValue == "fourGroups")
        #expect(PMRStep.fourGroupsRecall.rawValue == "fourGroupsRecall")
        #expect(PMRStep.cueControlled.rawValue == "cueControlled")
    }

    @Test("Phase rawValues are pinned")
    func phaseRawValues() {
        #expect(PMRPhase.intro.rawValue == "intro")
        #expect(PMRPhase.tense.rawValue == "tense")
        #expect(PMRPhase.release.rawValue == "release")
        #expect(PMRPhase.pause.rawValue == "pause")
        #expect(PMRPhase.outro.rawValue == "outro")
    }

    @Test("Muscle group rawValues are pinned")
    func muscleGroupRawValues() {
        #expect(PMRMuscleGroup.rightHandForearm.rawValue == "rightHandForearm")
        #expect(PMRMuscleGroup.chestShouldersBack.rawValue == "chestShouldersBack")
        #expect(PMRMuscleGroup.faceAndNeck.rawValue == "faceAndNeck")
        #expect(PMRMuscleGroup.allCases.count == 25)
    }

    /// The 7- and 4-group sets are not subsets of the canonical 16: "whole arm"
    /// is a different instruction from "right hand and forearm", and collapsing
    /// them would log a tension that never happened.
    @Test("The group sets are distinct, not subsets")
    func groupSetsAreDistinct() {
        let sixteen = Set(PMRStep.sixteenGroups.groups)
        let seven = Set(PMRStep.sevenGroups.groups)
        let four = Set(PMRStep.fourGroups.groups)

        #expect(sixteen.count == 16)
        #expect(seven.count == 7)
        #expect(four.count == 4)
        // Only the genuinely shared groups overlap.
        #expect(sixteen.intersection(seven) == [.neck])
        #expect(seven.intersection(four) == [.torso])
    }
}
