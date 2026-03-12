import Foundation

struct MuscleGroup: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let instruction: String
    let icon: String
    let duration: TimeInterval
    let phase: Phase
    
    enum Phase: Hashable {
        case tension
        case relaxation
    }
    
    static func groups(for type: RelaxationType) -> [MuscleGroup] {
        switch type {
        case .fullBody:
            return fullBodySequence
        case .short:
            return shortSequence
        }
    }
    
    private static let fullBodySequence: [MuscleGroup] = [
        // Hands and forearms
        MuscleGroup(
            name: "Hands & Forearms",
            instruction: "Make tight fists with both hands. Feel the tension in your hands and forearms.",
            icon: "hand.raised.fill",
            duration: 7,
            phase: .tension
        ),
        MuscleGroup(
            name: "Hands & Forearms",
            instruction: "Release your fists. Let your hands relax completely. Notice the difference between tension and relaxation.",
            icon: "hand.raised.fill",
            duration: 15,
            phase: .relaxation
        ),
        
        // Upper arms
        MuscleGroup(
            name: "Upper Arms",
            instruction: "Bend your arms and tense your biceps. Make them as tight as possible.",
            icon: "figure.strengthtraining.traditional",
            duration: 7,
            phase: .tension
        ),
        MuscleGroup(
            name: "Upper Arms",
            instruction: "Let your arms drop and relax. Feel the tension flowing away from your upper arms.",
            icon: "figure.strengthtraining.traditional",
            duration: 15,
            phase: .relaxation
        ),
        
        // Shoulders
        MuscleGroup(
            name: "Shoulders",
            instruction: "Raise your shoulders up toward your ears. Hold them high and feel the tension.",
            icon: "figure.arms.open",
            duration: 7,
            phase: .tension
        ),
        MuscleGroup(
            name: "Shoulders",
            instruction: "Let your shoulders drop down naturally. Feel them becoming heavy and relaxed.",
            icon: "figure.arms.open",
            duration: 15,
            phase: .relaxation
        ),
        
        // Face and jaw
        MuscleGroup(
            name: "Face & Jaw",
            instruction: "Scrunch up your face. Squeeze your eyes shut and clench your jaw tightly.",
            icon: "face.smiling",
            duration: 7,
            phase: .tension
        ),
        MuscleGroup(
            name: "Face & Jaw",
            instruction: "Release all tension from your face. Let your jaw drop slightly and relax your eyes.",
            icon: "face.smiling",
            duration: 15,
            phase: .relaxation
        ),
        
        // Chest and back
        MuscleGroup(
            name: "Chest & Back",
            instruction: "Take a deep breath and pull your shoulders back. Arch your back slightly.",
            icon: "lungs.fill",
            duration: 7,
            phase: .tension
        ),
        MuscleGroup(
            name: "Chest & Back",
            instruction: "Exhale and let your chest and back relax completely. Breathe naturally.",
            icon: "lungs.fill",
            duration: 15,
            phase: .relaxation
        ),
        
        // Stomach
        MuscleGroup(
            name: "Stomach",
            instruction: "Tighten your stomach muscles. Make your abdomen hard and tense.",
            icon: "figure.core.training",
            duration: 7,
            phase: .tension
        ),
        MuscleGroup(
            name: "Stomach",
            instruction: "Release your stomach muscles. Let your belly be soft and relaxed.",
            icon: "figure.core.training",
            duration: 15,
            phase: .relaxation
        ),
        
        // Legs
        MuscleGroup(
            name: "Legs & Thighs",
            instruction: "Tighten your thigh muscles. Straighten your legs and make them rigid.",
            icon: "figure.walk",
            duration: 7,
            phase: .tension
        ),
        MuscleGroup(
            name: "Legs & Thighs",
            instruction: "Let your legs relax completely. Feel them becoming heavy and loose.",
            icon: "figure.walk",
            duration: 15,
            phase: .relaxation
        ),
        
        // Feet
        MuscleGroup(
            name: "Feet & Calves",
            instruction: "Point your toes downward and tense your calves and feet.",
            icon: "shoeprints.fill",
            duration: 7,
            phase: .tension
        ),
        MuscleGroup(
            name: "Feet & Calves",
            instruction: "Release all tension from your feet and calves. Let them rest naturally.",
            icon: "shoeprints.fill",
            duration: 15,
            phase: .relaxation
        ),
    ]
    
    private static let shortSequence: [MuscleGroup] = [
        // Combined upper body
        MuscleGroup(
            name: "Upper Body",
            instruction: "Make fists, tense your arms, and raise your shoulders. Hold all this tension.",
            icon: "figure.strengthtraining.traditional",
            duration: 7,
            phase: .tension
        ),
        MuscleGroup(
            name: "Upper Body",
            instruction: "Release everything. Let your arms drop and shoulders fall. Feel the relaxation.",
            icon: "figure.strengthtraining.traditional",
            duration: 15,
            phase: .relaxation
        ),
        
        // Face
        MuscleGroup(
            name: "Face",
            instruction: "Scrunch your face. Squeeze your eyes and clench your jaw.",
            icon: "face.smiling",
            duration: 7,
            phase: .tension
        ),
        MuscleGroup(
            name: "Face",
            instruction: "Let all tension melt away from your face. Relax your jaw and eyes.",
            icon: "face.smiling",
            duration: 15,
            phase: .relaxation
        ),
        
        // Core
        MuscleGroup(
            name: "Core",
            instruction: "Take a deep breath. Arch your back and tighten your stomach.",
            icon: "figure.core.training",
            duration: 7,
            phase: .tension
        ),
        MuscleGroup(
            name: "Core",
            instruction: "Exhale and release. Let your back settle and stomach soften.",
            icon: "figure.core.training",
            duration: 15,
            phase: .relaxation
        ),
        
        // Lower body
        MuscleGroup(
            name: "Lower Body",
            instruction: "Straighten your legs and point your toes. Tense your thighs, calves, and feet.",
            icon: "figure.walk",
            duration: 7,
            phase: .tension
        ),
        MuscleGroup(
            name: "Lower Body",
            instruction: "Let your legs relax completely. Feel them becoming heavy and at ease.",
            icon: "figure.walk",
            duration: 15,
            phase: .relaxation
        ),
    ]
}
