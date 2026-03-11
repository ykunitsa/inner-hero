# Inner Hero

A CBT (Cognitive Behavioral Therapy) companion app for anxiety: exposure therapy, breathing, relaxation, grounding, and behavioral activation — all in one place, with local-only storage and no account required.

---

## Features

### Exercises

- **Exposures** — Create custom or use predefined exposure scenarios with steps and optional timers. Run sessions, track fear levels, and view progress over time.
- **Breathing** — Guided breathing patterns (e.g. 4-7-8, box breathing) with visual feedback and session history.
- **Relaxation** — Progressive muscle relaxation exercises by body region with session tracking.
- **Grounding** — Grounding and awareness exercises to reduce anxiety, with completed-session history.
- **Behavioral activation** — Activity lists and sessions to increase meaningful activity and track completion.

### Schedule

- Plan exercises by day of week and time.
- See today’s plan and next upcoming session on the Summary tab.
- Mark exercises as done; completions are stored and reflected in progress.

### Summary (Home)

- Overview of planned vs completed exercises for today.
- Quick access to next planned session and recent activity.
- Streak, minutes, and progress widgets.
- Article of the day and favorites.

### Knowledge center

- Searchable articles grouped by category (CBT, anxiety, coping, etc.).
- Read full content in-app.

### Settings

- **Appearance** — Light / Dark / System.
- **Privacy** — App lock (PIN/biometry) and related options.
- **Data** — Export all data as JSON; reset all data.
- **About** — App info and support.

### Other

- **Onboarding** — First-launch intro and disclaimer.
- **Local only** — All data stays on device (SwiftData); no sign-in or cloud.
- **Accessibility** — Labels, hints, and reduced-motion awareness where applicable.

---

## Tech stack

| Area        | Choice        |
|------------|---------------|
| Platform   | iOS 26+       |
| UI         | SwiftUI       |
| Persistence| SwiftData     |
| Data       | On-device only, no auth |

---

## Project structure (high level)

```
Inner Hero/
├── App/
│   └── Inner_HeroApp.swift          # App entry, model container, onboarding/sample data
├── Core/
│   ├── DesignSystem/                # Shared UI (e.g. TopMeshGradientBackground)
│   └── Utilities/                   # BreathingController, StepTimerController, etc.
├── Features/
│   ├── BehavioralActivation/        # Activity lists, sessions, create/edit
│   ├── Exposures/                   # Exposure CRUD, steps, session flow
│   ├── KnowledgeCenter/             # Articles browser and search
│   ├── MainTab/                     # HomeView, ExercisesView, widgets, schedule section
│   ├── Onboarding/                  # OnboardingView
│   ├── Schedule/                    # ScheduleTabView, week strip, assignments
│   ├── Sessions/                    # Breathing, relaxation, grounding, exposure session UIs
│   └── Settings/                    # Appearance, Privacy, Data, About
├── Models/                          # SwiftData models (Exposure, sessions, assignments, etc.)
├── Predefined/                      # Predefined exposures and activation lists
├── Services/                        # NotificationManager, ArticlesStore, DataManager
├── SharedComponents/                # Modals, charts, cards, detail rows
└── Resources/                       # Localizable.xcstrings, assets
```

---

## Getting started

1. Open `Inner Hero.xcodeproj` in Xcode.
2. Select an iOS 26+ simulator or a physical device.
3. Build and run (⌘R).

On first launch, the app shows onboarding and can load sample data (predefined exposures, activation lists, sample sessions) if the database is empty.

---

## Data & privacy

- No account, no server: everything is stored locally with SwiftData.
- Optional app lock (Settings → Privacy) for device-level protection.
- Export (Settings → Data) produces a JSON file of your exercises, schedule, and session results for backup or migration.

---

## License

See the repository for license information.
