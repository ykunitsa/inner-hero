import Foundation

// MARK: - PresetActivationData
// Seed data for ActivationCategory and ActivationTask.
// - `title` stores the English fallback (shown when localization key is missing).
// - `predefinedKey` is used at runtime to look up the localized string from Localizable.xcstrings.
// Call from SchemaV2 didMigrate and SampleDataLoader.

enum PresetActivationData {

    // MARK: - Stable category IDs (fixed UUIDs so seed is idempotent)

    static let selfCareId      = UUID(uuidString: "11111111-0000-0000-0000-000000000001")!
    static let achievementId   = UUID(uuidString: "11111111-0000-0000-0000-000000000002")!
    static let pleasureId      = UUID(uuidString: "11111111-0000-0000-0000-000000000003")!
    static let socialId        = UUID(uuidString: "11111111-0000-0000-0000-000000000004")!
    static let physicalId      = UUID(uuidString: "11111111-0000-0000-0000-000000000005")!
    static let creativeId      = UUID(uuidString: "11111111-0000-0000-0000-000000000006")!
    static let valuesId        = UUID(uuidString: "11111111-0000-0000-0000-000000000007")!

    // MARK: - Categories

    static var categories: [ActivationCategory] {
        [
            ActivationCategory(id: selfCareId,    predefinedKey: "self_care",    title: "Self-Care",    sfSymbol: "shield.fill",           colorHex: "#34A85A", sortOrder: 0, isPreset: true),
            ActivationCategory(id: achievementId, predefinedKey: "achievement",  title: "Achievement",  sfSymbol: "checkmark.square.fill", colorHex: "#6366F1", sortOrder: 1, isPreset: true),
            ActivationCategory(id: pleasureId,    predefinedKey: "pleasure",     title: "Pleasure",     sfSymbol: "star.fill",             colorHex: "#F59E0B", sortOrder: 2, isPreset: true),
            ActivationCategory(id: socialId,      predefinedKey: "social",       title: "Social",       sfSymbol: "person.2.fill",         colorHex: "#EC4899", sortOrder: 3, isPreset: true),
            ActivationCategory(id: physicalId,    predefinedKey: "physical",     title: "Physical",     sfSymbol: "bolt.fill",             colorHex: "#E8392A", sortOrder: 4, isPreset: true),
            ActivationCategory(id: creativeId,    predefinedKey: "creative",     title: "Creative",     sfSymbol: "paintbrush.fill",       colorHex: "#8B5CF6", sortOrder: 5, isPreset: true),
            ActivationCategory(id: valuesId,      predefinedKey: "values",       title: "Values",       sfSymbol: "leaf.fill",             colorHex: "#059669", sortOrder: 6, isPreset: true),
        ]
    }

    // MARK: - Tasks

    static var tasks: [ActivationTask] {
        var result: [ActivationTask] = []
        result.append(contentsOf: selfCareTasks)
        result.append(contentsOf: achievementTasks)
        result.append(contentsOf: pleasureTasks)
        result.append(contentsOf: socialTasks)
        result.append(contentsOf: physicalTasks)
        result.append(contentsOf: creativeTasks)
        result.append(contentsOf: valuesTasks)
        return result
    }

    // MARK: - Self-Care

    private static var selfCareTasks: [ActivationTask] {
        let c = selfCareId
        return [
            task(c, "self_care_01", "Take a shower or bath",              "Even a quick one counts",                   P: true,  M: false, effort: .low),
            task(c, "self_care_02", "Have a proper breakfast",             "Sit down and eat without your phone",        P: true,  M: false, effort: .low),
            task(c, "self_care_03", "Go to bed on time",                   "Choose a time and stick to it",              P: false, M: true,  effort: .low),
            task(c, "self_care_04", "Drink enough water",                  "Keep a bottle in plain sight",               P: false, M: true,  effort: .low),
            task(c, "self_care_05", "Get dressed and tidy up",             "Even if you're not going anywhere",          P: true,  M: true,  effort: .low),
            task(c, "self_care_06", "Tidy one spot in your room",          "Just the desk or just the bed",              P: false, M: true,  effort: .low),
            task(c, "self_care_07", "Do a small clean-up",                 "20–30 minutes in one area",                  P: false, M: true,  effort: .medium),
            task(c, "self_care_08", "Cook a proper meal",                  "Not a ready-made dish",                      P: true,  M: true,  effort: .medium),
            task(c, "self_care_09", "Sit in the sun",                      "15 minutes by a window or outside",          P: true,  M: false, effort: .low),
            task(c, "self_care_10", "Get some fresh air",                  "Even for just 10 minutes",                   P: true,  M: false, effort: .low),
        ]
    }

    // MARK: - Achievement

    private static var achievementTasks: [ActivationTask] {
        let c = achievementId
        return [
            task(c, "achievement_01", "Do one task from your to-do list",  "The smallest overdue one",                   P: false, M: true,  effort: .low),
            task(c, "achievement_02", "Reply to an important message",      "The one you've been putting off",            P: false, M: true,  effort: .low),
            task(c, "achievement_03", "Pay a bill or make a call",          "A small admin task",                         P: false, M: true,  effort: .low),
            task(c, "achievement_04", "Sort through your inbox",            "Delete junk, reply to one",                  P: false, M: true,  effort: .medium),
            task(c, "achievement_05", "Finish a started project",           "Bring something to 'done'",                  P: false, M: true,  effort: .high),
            task(c, "achievement_06", "Organise one drawer",                "Throw away what you don't need",             P: false, M: true,  effort: .medium),
            task(c, "achievement_07", "Learn something new",                "An article, video, or lesson — 15 minutes",  P: true,  M: true,  effort: .medium),
            task(c, "achievement_08", "Plan for tomorrow",                  "Three main things",                          P: false, M: true,  effort: .low),
        ]
    }

    // MARK: - Pleasure

    private static var pleasureTasks: [ActivationTask] {
        let c = pleasureId
        return [
            task(c, "pleasure_01", "Watch a favourite show or film",        "Without guilt about 'wasted' time",          P: true,  M: false, effort: .low),
            task(c, "pleasure_02", "Listen to your favourite music",        "A whole album, mindfully",                   P: true,  M: false, effort: .low),
            task(c, "pleasure_03", "Eat something really delicious",        "Something you've been craving",              P: true,  M: false, effort: .low),
            task(c, "pleasure_04", "Read a book or magazine",               "30 minutes without distractions",            P: true,  M: false, effort: .low),
            task(c, "pleasure_05", "Play a game",                           "Board game, video game, or mobile",          P: true,  M: false, effort: .low),
            task(c, "pleasure_06", "Look out the window with coffee or tea","Do nothing — it's okay too",                 P: true,  M: false, effort: .low),
            task(c, "pleasure_07", "Watch funny videos",                    "Intentionally, not mindlessly",              P: true,  M: false, effort: .low),
            task(c, "pleasure_08", "Take a long bath",                      "With a candle, book, or music",              P: true,  M: false, effort: .low),
            task(c, "pleasure_09", "Treat yourself to something small",     "A flower, book, or snack",                   P: true,  M: false, effort: .medium),
        ]
    }

    // MARK: - Social

    private static var socialTasks: [ActivationTask] {
        let c = socialId
        return [
            task(c, "social_01", "Message a friend or loved one",           "Just to ask how they're doing",              P: true,  M: false, effort: .low),
            task(c, "social_02", "Call someone",                            "Not for business — just to talk",            P: true,  M: false, effort: .medium),
            task(c, "social_03", "Meet someone in person",                  "Café, walk, or at home",                     P: true,  M: true,  effort: .high),
            task(c, "social_04", "Say something kind to someone",           "A compliment or words of thanks",            P: true,  M: true,  effort: .low),
            task(c, "social_05", "Go somewhere with people",               "Café, park, or library",                     P: true,  M: false, effort: .medium),
            task(c, "social_06", "Reply to a long-overdue message",         "The one it felt awkward to ignore",          P: false, M: true,  effort: .low),
            task(c, "social_07", "Walk with a friend or pet",               "30+ minutes together",                       P: true,  M: false, effort: .medium),
        ]
    }

    // MARK: - Physical

    private static var physicalTasks: [ActivationTask] {
        let c = physicalId
        return [
            task(c, "physical_01", "Go for a 10–15 minute walk",           "Pace doesn't matter",                        P: true,  M: false, effort: .low,    minutes: 15),
            task(c, "physical_02", "Do a 5–10 minute workout",              "A few exercises at home",                    P: false, M: true,  effort: .low,    minutes: 10),
            task(c, "physical_03", "Dance at home",                         "One or two songs",                           P: true,  M: false, effort: .low),
            task(c, "physical_04", "Stretch or do yoga",                    "15–20 minutes",                              P: true,  M: true,  effort: .low,    minutes: 20),
            task(c, "physical_05", "Ride a bicycle",                        "With or without a destination",              P: true,  M: false, effort: .medium),
            task(c, "physical_06", "Go for a swim",                         "Pool or open water",                         P: true,  M: true,  effort: .high),
            task(c, "physical_07", "Go for a run",                          "Doesn't matter how long",                    P: false, M: true,  effort: .medium),
            task(c, "physical_08", "Just stand up and walk around",         "If you have no energy — this counts too",    P: false, M: true,  effort: .low),
            task(c, "physical_09", "Go to the gym",                         "Even a light workout",                       P: false, M: true,  effort: .high),
        ]
    }

    // MARK: - Creative

    private static var creativeTasks: [ActivationTask] {
        let c = creativeId
        return [
            task(c, "creative_01", "Draw or colour",                        "No goal — just enjoy the process",           P: true,  M: false, effort: .low),
            task(c, "creative_02", "Write in a journal",                    "5–10 minutes, free flow",                    P: true,  M: true,  effort: .low,    minutes: 10),
            task(c, "creative_03", "Play a musical instrument",             "No expectations of yourself",                P: true,  M: true,  effort: .medium),
            task(c, "creative_04", "Cook something new",                    "A recipe you've wanted to try",              P: true,  M: true,  effort: .medium),
            task(c, "creative_05", "Photograph something beautiful",        "On a walk or at home",                       P: true,  M: false, effort: .low),
            task(c, "creative_06", "Do some crafting",                      "Knitting, sewing, or sculpting",             P: true,  M: true,  effort: .medium),
            task(c, "creative_07", "Tend to your plants",                   "Water, repot, or just look",                 P: true,  M: true,  effort: .medium),
            task(c, "creative_08", "Watch inspiring content",               "Art, design, or architecture",               P: true,  M: false, effort: .low),
        ]
    }

    // MARK: - Values

    private static var valuesTasks: [ActivationTask] {
        let c = valuesId
        return [
            task(c, "values_01", "Help someone with a task",               "Small, practical help",                       P: true,  M: true,  effort: .medium),
            task(c, "values_02", "Do something for someone without being asked", "A surprise, care, or attention",        P: true,  M: true,  effort: .medium),
            task(c, "values_03", "Donate or take part in a cause",         "A small contribution to something important", P: true,  M: true,  effort: .low),
            task(c, "values_04", "Spend time in silence or meditation",    "10 minutes without a screen",                 P: true,  M: false, effort: .low,    minutes: 10),
            task(c, "values_05", "Spend time in nature",                   "Park, forest, or shore — mindfully",          P: true,  M: false, effort: .medium),
            task(c, "values_06", "Thank someone sincerely",                "A letter, message, or out loud",              P: true,  M: true,  effort: .low),
        ]
    }

    // MARK: - Helper

    private static func task(
        _ categoryId: UUID,
        _ predefinedKey: String,
        _ title: String,
        _ hint: String,
        P pleasureTag: Bool,
        M masteryTag: Bool,
        effort: EffortLevel,
        minutes: Int? = nil
    ) -> ActivationTask {
        ActivationTask(
            categoryId: categoryId,
            predefinedKey: predefinedKey,
            title: title,
            hint: hint,
            pleasureTag: pleasureTag,
            masteryTag: masteryTag,
            effortLevel: effort,
            suggestedMinutes: minutes,
            sfSymbol: "checkmark.circle",
            isPreset: true
        )
    }
}
