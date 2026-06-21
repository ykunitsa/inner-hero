# Inner Hero — Project Guide

A CBT companion app for anxiety (iOS). All data is local — no accounts, no network.
Exposures, breathing, relaxation, grounding, behavioral activation, schedule,
knowledge center.

> This file is loaded into context every session. Keep it as a **map**, not a copy
> of the code: it should help jump straight to the right file, not restate it.
> Update it on meaningful architecture/convention changes.

---

## Language & communication

- **Talk to the user in Russian.** Explanations, answers, summaries — in Russian.
- **Code and source strings are in English (primary).** `Localizable.xcstrings`
  has `sourceLanguage: en`. Every new user-facing string is **authored in English first**
  with the key `String(localized: "English text")`; Russian is added as a **translation**
  in `.xcstrings`. Russian is secondary/translation, never the source.
  ⚠️ Common mistake: creating new labels/strings directly in Russian in code. Don't —
  the source is always English; the translation lives in `.xcstrings`.
- Identifiers, type names, and code comments are in English.

---

## Stack

| Area          | Choice                         |
|---------------|--------------------------------|
| Platform      | iOS 26+                        |
| UI            | SwiftUI (no UIKit)             |
| Data          | SwiftData (local, no network)  |
| State         | `@Observable` / `@Query` / `@Environment` (Observation framework, not Combine) |
| Localization  | `Localizable.xcstrings` (EN source, RU translation) |

SwiftUI and current Swift only. **Do not use UIKit.**

---

## Commands

```bash
# Build for the simulator
xcodebuild -project "Inner Hero.xcodeproj" -scheme "Inner Hero" \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build

# Tests
xcodebuild -project "Inner Hero.xcodeproj" -scheme "Inner Hero" \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' test
```

- Single scheme: **`Inner Hero`**. Targets: `Inner Hero`, `Inner HeroTests`, `Inner HeroUITests`.
- Configurations: `Debug`, `Release`.

---

## Project map

```
Inner Hero/
├── App/
│   ├── Inner_HeroApp.swift        # Entry point, ModelContainer, onboarding/sample data
│   └── Schema/                    # SchemaV1, SchemaV2, AppMigrationPlan (SwiftData migrations)
├── Core/
│   ├── DesignSystem/              # ⭐ Tokens and components — ALWAYS start here for UI
│   ├── Navigation/                # NavigationRouter, AppRoute, AppRouteView
│   ├── Components/                # Shared components (Charts, Modals, Schedule)
│   └── Utilities/                 # BreathingController, StepTimerController, Haptics, Export
├── Features/                      # Features grouped by module (see below)
│   └── <Feature>/{Views,ViewModels,Components}/
├── Models/                        # @Model SwiftData + Extensions/ + Predefined/
├── Services/                      # Stateless helpers and managers
└── Resources/                     # Localizable.xcstrings, assets
```

### Features (`Features/`)
- **MainTab** — Home (summary), tab navigation.
- **Schedule** — planning exercises by day/time, completion marks.
- **Exposures** — exposure therapy: CRUD, steps, timers, session flow, progress.
- **Sessions** — UI for breathing / relaxation / grounding / exposure sessions.
- **BehavioralActivation** — activity lists and sessions (newest module, actively changing).
- **KnowledgeCenter** — articles (search, categories).
- **Onboarding** — first launch + disclaimer.
- **Settings** — Appearance / Privacy (app lock, PIN/biometrics) / Data (export/reset) / About.

---

## Conventions

### Design system (`Core/DesignSystem/`) — mandatory
Don't hardcode sizes/colors/fonts. Use tokens:

- **Colors:** `AppColors.*` (`DesignSystem.swift:8`) — `AppColors.primary`, `AppColors.positive`, etc. No `Color(red:green:blue:)` or `.blue`/`.green` in features.
- **Spacing:** `Spacing.*` (`:73`) — instead of `padding(16)`/`spacing: 12`.
- **Corner radii:** `CornerRadius.*` (`:93`) — instead of `cornerRadius: 20`.
- **Icons/touch targets:** `IconSize.*` (`:121`), `TouchTarget.*` (`:113`).
- **Opacities/shadows:** `Opacity.*` (`:140`).
- **Animations/timings:** `AppAnimation.*` (`:170`), `InteractionTiming.*` (`:191`).
- **Typography:** `.appFont(.body)` etc. via `AppTextStyle` (`Typography.swift:14`).
  Styles: `display, h1, h2, h3, bodyLarge, body, bodyMedium, small, smallMedium,
  caption, mono, monoLarge, statValue, buttonPrimary, buttonSmall, navItem, navItemActive`.
  Instead of `.font(.system(size: 14, weight: .semibold))`, pick a style from `AppTextStyle`.
- Reusable components live in `Components.swift` (large file; before creating a new
  component, check whether one already exists: `PrimaryButton`, `CircleButton`,
  `ExerciseRow`, `RadioCard`, `HeroFeatureCard`, navigation pills, etc.).
- Shared modifiers live in `ViewModifiers.swift` (`cardStyle`, `heroCardStyle`, `touchTarget`, `pageBackground`, ...).

### Localization
- User-facing text: `String(localized: "English source")`. Source is English.
- The RU translation is added in `Localizable.xcstrings`, not in code.
- Format strings: `String(format: String(localized: "Completed %1$d of %2$d"), a, b)`.
- Don't hardcode displayed text directly in `Text("...")` (exception — data/identifiers).

### Navigation
- Centralized `NavigationRouter` (`@Observable @MainActor`), one `NavigationPath` per tab.
- Routes live in `AppRoute` (enum). Routing is a `switch` in `AppRouteView`.
- `BARoute` is a separate enum for BehavioralActivation (see TECH_DEBT — this is considered debt).

### MVVM
- ViewModels: `@Observable @MainActor`, no direct UIKit/globals.
- ⚠️ MVVM is applied **inconsistently**: some features have a ViewModel (Home, Schedule,
  BehavioralActivation), others (Exposures) keep logic in views. For new work, lean toward
  moving business logic into a ViewModel rather than growing "massive views".

### SwiftData
- `@Model` classes live in `Models/`: `Exposure`, `ExposureSessionResult`, `ActivationTask`,
  `ActivationCategory`, `ActivationSession`, `ExerciseAssignment`, `ExerciseCompletion`,
  `FavoriteExercise`, `BreathingSessionResult`, `RelaxationSessionResult`, `GroundingSessionResult`.
- Changing a model **requires** a new schema version + a stage in `AppMigrationPlan`
  (see `App/Schema/`). Don't edit existing schemas in place.
- Localizable/predefined model data lives in `Models/Extensions/` and `Models/Predefined/`.
- Completing an exercise goes only through `Services/SessionCompletionService` (idempotent,
  keyed by `uniqueKey`). Don't create `ExerciseCompletion` by hand.

### Services (`Services/`)
Stateless helpers / managers: `SessionCompletionService`, `NotificationManager` (`@MainActor`),
`FavoritesService`, `ArticlesLoader`/`ArticlesStore`, `SampleDataLoader`. Keep business logic
that touches `ModelContext` here, not in views.

### Concurrency
- `async/await` + `@MainActor`. Don't introduce GCD.
- Long-lived `Task`s and `Timer`s — cancel them in `onDisappear` (not done everywhere yet, see TECH_DEBT).

---

## Before starting work

1. For UI tasks — look at `Core/DesignSystem/` first (tokens and ready-made components).
2. For data work — look at the relevant `@Model` and `App/Schema/`.
3. New user-facing text — English key + translation in `.xcstrings`.
4. Check **[TECH_DEBT.md](TECH_DEBT.md)** — known weak spots and "careful here", so you don't
   rely on them as a model or break agreed conventions.

## Don't
- Don't use UIKit.
- Don't hardcode colors/spacing/fonts instead of design-system tokens.
- Don't author new displayed strings in Russian in code (source is English).
- Don't change existing SwiftData schema versions without a new migration.
- Don't grow "massive views" — extract logic into a ViewModel/components.
