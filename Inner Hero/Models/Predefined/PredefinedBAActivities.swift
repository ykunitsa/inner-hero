import Foundation

struct PredefinedBAActivityData {
    let key: String
    let lifeValue: LifeValue
}

enum PredefinedBAActivities {
    static var all: [PredefinedBAActivityData] {
        [
            // MARK: Connection
            .init(key: "call_someone_close",   lifeValue: .connection),
            .init(key: "write_warm_message",   lifeValue: .connection),
            .init(key: "arrange_meeting",      lifeValue: .connection),
            .init(key: "spend_time_with_family", lifeValue: .connection),
            .init(key: "compliment_someone",   lifeValue: .connection),
            .init(key: "write_gratitude_note", lifeValue: .connection),
            .init(key: "play_with_child",      lifeValue: .connection),
            .init(key: "ask_how_someone_is",   lifeValue: .connection),

            // MARK: Body
            .init(key: "walk_15_min",          lifeValue: .body),
            .init(key: "morning_stretch",      lifeValue: .body),
            .init(key: "healthy_meal",         lifeValue: .body),
            .init(key: "early_sleep",          lifeValue: .body),
            .init(key: "take_shower",          lifeValue: .body),
            .init(key: "dance_to_song",        lifeValue: .body),
            .init(key: "drink_water",          lifeValue: .body),
            .init(key: "go_outside",           lifeValue: .body),

            // MARK: Creativity
            .init(key: "draw_something",       lifeValue: .creativity),
            .init(key: "journal_entry",        lifeValue: .creativity),
            .init(key: "play_instrument",      lifeValue: .creativity),
            .init(key: "try_new_recipe",       lifeValue: .creativity),
            .init(key: "rearrange_space",      lifeValue: .creativity),
            .init(key: "take_photos",          lifeValue: .creativity),
            .init(key: "write_poem",           lifeValue: .creativity),
            .init(key: "craft_something",      lifeValue: .creativity),

            // MARK: Nature
            .init(key: "sit_by_window",        lifeValue: .nature),
            .init(key: "water_plants",         lifeValue: .nature),
            .init(key: "watch_sky",            lifeValue: .nature),
            .init(key: "barefoot_on_grass",    lifeValue: .nature),
            .init(key: "observe_nature",       lifeValue: .nature),
            .init(key: "smell_flowers",        lifeValue: .nature),
            .init(key: "watch_sunset",         lifeValue: .nature),
            .init(key: "walk_in_park",         lifeValue: .nature),

            // MARK: Growth
            .init(key: "read_10_pages",        lifeValue: .growth),
            .init(key: "one_lesson",           lifeValue: .growth),
            .init(key: "declutter_one_thing",  lifeValue: .growth),
            .init(key: "learn_word",           lifeValue: .growth),
            .init(key: "watch_educational_video", lifeValue: .growth),
            .init(key: "practice_skill",       lifeValue: .growth),
            .init(key: "solve_puzzle",         lifeValue: .growth),
            .init(key: "plan_next_day",        lifeValue: .growth),

            // MARK: Rest
            .init(key: "five_minutes_silence", lifeValue: .rest),
            .init(key: "meditation_5min",      lifeValue: .rest),
            .init(key: "rest_without_phone",   lifeValue: .rest),
            .init(key: "bath_mindful",         lifeValue: .rest),
            .init(key: "listen_to_music",      lifeValue: .rest),
            .init(key: "breathe_deeply",       lifeValue: .rest),
            .init(key: "cozy_corner",          lifeValue: .rest),
            .init(key: "light_candle",         lifeValue: .rest),
        ]
    }
}
