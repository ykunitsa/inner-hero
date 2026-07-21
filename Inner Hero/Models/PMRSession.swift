import Foundation
import SwiftData

// MARK: - PMR Phase

/// One phase of the PMR script (spec §5).
///
/// `pause` is a phase of its own rather than trailing silence on `release`: it is
/// the only stretch where the voice is quiet and the user is doing nothing at
/// all, and its job is to let attention move to the next muscle group. Folding it
/// into `release` would make "the voice is still guiding you" and "the voice has
/// stopped" indistinguishable in the script (plan §2, decision 2).
nonisolated enum PMRPhase: String, CaseIterable {
    case intro
    case tense
    case release
    case pause
    case outro
}

// MARK: - Muscle Group

/// The muscle groups of the PMR ladder (spec §5).
///
/// The 7-group and 4-group sets are **not** subsets of the canonical 16: "whole
/// arm" is a different instruction from "right hand and forearm", so they get
/// their own cases rather than reusing one and lying about what was tensed.
/// `neck` and `torso` are genuinely shared and are reused.
///
/// Every group carries both a name and the instruction for tensing it. The
/// screen shows them and the voice speaks them, from this one place — a session
/// where the screen said one thing and the voice another would be worse than
/// either alone (plan §2, decision 5).
nonisolated enum PMRMuscleGroup: String, CaseIterable {
    // Persisted rawValues — never rename (CLAUDE.md).

    // The canonical 16.
    case rightHandForearm
    case rightBicep
    case leftHandForearm
    case leftBicep
    case forehead
    case upperFace
    case lowerFace
    case neck
    case chestShouldersBack
    case abdomen
    case rightThigh
    case rightCalf
    case rightFoot
    case leftThigh
    case leftCalf
    case leftFoot

    // Added by the 7-group set (`neck` is shared with the 16).
    case rightArm
    case leftArm
    case face
    case torso
    case rightLeg
    case leftLeg

    // Added by the 4-group set (`torso` is shared with the 7).
    case arms
    case faceAndNeck
    case legs

    /// The group as it is named to the user: "torso", "right calf".
    var title: String {
        switch self {
        case .rightHandForearm: String(localized: "right hand and forearm")
        case .rightBicep: String(localized: "right upper arm")
        case .leftHandForearm: String(localized: "left hand and forearm")
        case .leftBicep: String(localized: "left upper arm")
        case .forehead: String(localized: "forehead")
        case .upperFace: String(localized: "eyes and nose")
        case .lowerFace: String(localized: "jaw and mouth")
        case .neck: String(localized: "neck")
        case .chestShouldersBack: String(localized: "chest, shoulders and back")
        case .abdomen: String(localized: "stomach")
        case .rightThigh: String(localized: "right thigh")
        case .rightCalf: String(localized: "right calf")
        case .rightFoot: String(localized: "right foot")
        case .leftThigh: String(localized: "left thigh")
        case .leftCalf: String(localized: "left calf")
        case .leftFoot: String(localized: "left foot")
        case .rightArm: String(localized: "right arm")
        case .leftArm: String(localized: "left arm")
        case .face: String(localized: "face")
        case .torso: String(localized: "torso")
        case .rightLeg: String(localized: "right leg")
        case .leftLeg: String(localized: "left leg")
        case .arms: String(localized: "arms")
        case .faceAndNeck: String(localized: "face and neck")
        case .legs: String(localized: "legs")
        }
    }

    /// The group as the object of "tense"/"release".
    ///
    /// In English this is the same word as `title`, which is exactly why it
    /// needs its own entry: Russian puts the object of «напряги» in the
    /// accusative, so «правая рука» has to become «правую руку». The first
    /// attempt dodged the problem with a dash («Напряги — правая рука») and it
    /// sounded wrong the moment it was spoken aloud.
    ///
    /// These are the only strings in the app keyed symbolically rather than by
    /// their English text (CLAUDE.md): two grammatical forms that collapse into
    /// one English word cannot share a key, and the catalog is keyed on the
    /// source string.
    var accusative: String {
        switch self {
        case .rightHandForearm:
            String(localized: "pmr.group.rightHandForearm.accusative", defaultValue: "right hand and forearm")
        case .rightBicep:
            String(localized: "pmr.group.rightBicep.accusative", defaultValue: "right upper arm")
        case .leftHandForearm:
            String(localized: "pmr.group.leftHandForearm.accusative", defaultValue: "left hand and forearm")
        case .leftBicep:
            String(localized: "pmr.group.leftBicep.accusative", defaultValue: "left upper arm")
        case .forehead:
            String(localized: "pmr.group.forehead.accusative", defaultValue: "forehead")
        case .upperFace:
            String(localized: "pmr.group.upperFace.accusative", defaultValue: "eyes and nose")
        case .lowerFace:
            String(localized: "pmr.group.lowerFace.accusative", defaultValue: "jaw and mouth")
        case .neck:
            String(localized: "pmr.group.neck.accusative", defaultValue: "neck")
        case .chestShouldersBack:
            String(localized: "pmr.group.chestShouldersBack.accusative", defaultValue: "chest, shoulders and back")
        case .abdomen:
            String(localized: "pmr.group.abdomen.accusative", defaultValue: "stomach")
        case .rightThigh:
            String(localized: "pmr.group.rightThigh.accusative", defaultValue: "right thigh")
        case .rightCalf:
            String(localized: "pmr.group.rightCalf.accusative", defaultValue: "right calf")
        case .rightFoot:
            String(localized: "pmr.group.rightFoot.accusative", defaultValue: "right foot")
        case .leftThigh:
            String(localized: "pmr.group.leftThigh.accusative", defaultValue: "left thigh")
        case .leftCalf:
            String(localized: "pmr.group.leftCalf.accusative", defaultValue: "left calf")
        case .leftFoot:
            String(localized: "pmr.group.leftFoot.accusative", defaultValue: "left foot")
        case .rightArm:
            String(localized: "pmr.group.rightArm.accusative", defaultValue: "right arm")
        case .leftArm:
            String(localized: "pmr.group.leftArm.accusative", defaultValue: "left arm")
        case .face:
            String(localized: "pmr.group.face.accusative", defaultValue: "face")
        case .torso:
            String(localized: "pmr.group.torso.accusative", defaultValue: "torso")
        case .rightLeg:
            String(localized: "pmr.group.rightLeg.accusative", defaultValue: "right leg")
        case .leftLeg:
            String(localized: "pmr.group.leftLeg.accusative", defaultValue: "left leg")
        case .arms:
            String(localized: "pmr.group.arms.accusative", defaultValue: "arms")
        case .faceAndNeck:
            String(localized: "pmr.group.faceAndNeck.accusative", defaultValue: "face and neck")
        case .legs:
            String(localized: "pmr.group.legs.accusative", defaultValue: "legs")
        }
    }

    /// How to tense this group. Lowercase and imperative — it is spoken as the
    /// second half of "Tense your arms — make fists, bend your arms."
    var tensingCue: String {
        switch self {
        case .rightHandForearm, .leftHandForearm:
            String(localized: "make a fist")
        case .rightBicep, .leftBicep:
            String(localized: "bend your arm at the elbow")
        case .forehead:
            String(localized: "raise your eyebrows")
        case .upperFace:
            String(localized: "squeeze your eyes shut, wrinkle your nose")
        case .lowerFace:
            String(localized: "clench your teeth, press your tongue to the roof of your mouth")
        case .neck:
            String(localized: "press your chin toward your chest")
        case .chestShouldersBack:
            String(localized: "pull your shoulder blades together, take a deep breath")
        case .abdomen:
            String(localized: "pull your stomach in")
        case .rightThigh, .leftThigh:
            String(localized: "straighten your leg at the knee")
        case .rightCalf, .leftCalf:
            String(localized: "pull your toes toward you")
        case .rightFoot, .leftFoot:
            String(localized: "curl your toes")
        case .rightArm, .leftArm:
            String(localized: "make a fist and bend your arm")
        case .face:
            String(localized: "squeeze your eyes shut, clench your teeth")
        case .torso:
            String(localized: "pull your shoulder blades together, pull your stomach in")
        case .rightLeg, .leftLeg:
            String(localized: "straighten your leg, pull your toes toward you")
        case .arms:
            String(localized: "make fists, bend your arms")
        case .faceAndNeck:
            String(localized: "squeeze your eyes shut, clench your teeth, press your chin down")
        case .legs:
            String(localized: "straighten your legs, pull your toes toward you")
        }
    }
}

// MARK: - Ladder Step

/// A rung of the PMR ladder (spec §5).
///
/// Steps are **never blocked** — the spec puts the decision to move with the
/// user's therapist, so the picker offers all five and the ladder rule only ever
/// suggests (plan §2, decision 3).
nonisolated enum PMRStep: String, CaseIterable {
    // Persisted rawValues — never rename (CLAUDE.md).
    case sixteenGroups
    case sevenGroups
    case fourGroups
    case fourGroupsRecall
    case cueControlled

    var title: String {
        switch self {
        case .sixteenGroups: String(localized: "16 groups")
        case .sevenGroups: String(localized: "7 groups")
        case .fourGroups: String(localized: "4 groups")
        case .fourGroupsRecall: String(localized: "4 groups, no tension")
        case .cueControlled: String(localized: "On the exhale")
        }
    }

    /// What the step *is*, never what it gives you or when to reach for it —
    /// that line would be a recommendation (principle 1.1) on the user's own
    /// path (1.3).
    ///
    /// Deliberately carries **no duration**: the time is computed from the
    /// script and composed by the caller, so a tuning change to the timings can
    /// never leave this string claiming a number the session no longer takes.
    var summary: String {
        switch self {
        case .sixteenGroups:
            String(localized: "tense and release, one muscle at a time")
        case .sevenGroups:
            String(localized: "arms, face, neck, torso, legs")
        case .fourGroups:
            String(localized: "arms, face and neck, torso, legs")
        case .fourGroupsRecall:
            String(localized: "the same four, release only")
        case .cueControlled:
            String(localized: "a word on the exhale")
        }
    }

    /// Whether the script tenses before releasing. False from the recall step
    /// down: releasing without tensing first is the skill those steps train.
    var usesTension: Bool {
        switch self {
        case .sixteenGroups, .sevenGroups, .fourGroups: true
        case .fourGroupsRecall, .cueControlled: false
        }
    }

    var groups: [PMRMuscleGroup] {
        switch self {
        case .sixteenGroups:
            [
                .rightHandForearm, .rightBicep, .leftHandForearm, .leftBicep,
                .forehead, .upperFace, .lowerFace, .neck,
                .chestShouldersBack, .abdomen,
                .rightThigh, .rightCalf, .rightFoot,
                .leftThigh, .leftCalf, .leftFoot,
            ]
        case .sevenGroups:
            [.rightArm, .leftArm, .face, .neck, .torso, .rightLeg, .leftLeg]
        case .fourGroups, .fourGroupsRecall:
            [.arms, .faceAndNeck, .torso, .legs]
        case .cueControlled:
            []
        }
    }

    /// Derived from the script, never typed in (spec §5: "расчётное время
    /// вычисляется, не вводится"). Tuning the timings moves this number and
    /// every label built from it, together.
    var estimatedDuration: TimeInterval {
        PMRScript.totalDuration(for: self)
    }
}

// MARK: - Session Entry

/// One PMR session (spec §5).
///
/// Inserted at "Start" with the plan only, exactly like breathing and planned
/// exposure: killing the app mid-session must leave a truthful partial record
/// rather than nothing at all (principle 1.5). `actualDurationSeconds` and
/// `groupsCompleted` are written when the session ends, `didRelax` and `note` on
/// the "after" screen.
@Model
final class PMRSessionEntry {
    var createdAt: Date
    var stepRaw: String
    /// What the script was expected to take when it started.
    var plannedDurationSeconds: Int
    /// Nil while the session has been started and not finished.
    var actualDurationSeconds: Int?
    /// How many muscle groups were actually worked through. Zero for the
    /// cue-controlled step, which has no groups.
    var groupsCompleted: Int
    /// Nil while the "after" screen has not been answered. Nil is *no answer*,
    /// not a negative one — the ladder rule skips these without breaking a run.
    var didRelax: Bool?
    var note: String?

    init(
        createdAt: Date,
        step: PMRStep,
        plannedDurationSeconds: Int
    ) {
        self.createdAt = createdAt
        self.stepRaw = step.rawValue
        self.plannedDurationSeconds = plannedDurationSeconds
        self.groupsCompleted = 0
    }

    var step: PMRStep? {
        PMRStep(rawValue: stepRaw)
    }
}
