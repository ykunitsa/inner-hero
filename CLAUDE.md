# Inner Hero — Project Guide

A CBT companion app for anxiety (iOS). All data is local — no accounts, no network.
**The app is mid-rebuild (redesign 2.0, July 2026).** The product source of truth is
**`docs/redesign-spec.md`**: exercises, flows, screens, the 10 product principles (§1),
and the implementation order (§11).

> This file is loaded into context every session. Keep it as a **map**, not a copy
> of the code. Update it on meaningful architecture/convention changes.

---

## Rebuild state — read this first

- Strategy: **greenfield on top of the design system + plumbing**. Old user data is
  not migrated (author's decision, ~20 installs).
- `_to_delete/` at the repo root holds the torn-down legacy code awaiting manual
  deletion. **Never import, reference, or resurrect anything from it.** Git history
  has everything if archaeology is ever needed.
- Current shell: 4 tabs — Today / Exercises / History / Knowledge. Settings opens
  from the gear on Today. Today is still thin (hero card + BA tail) until the
  schedule lands. §11.1 (situational exposure form, hero card
  on Today → sheet) and §11.2 (planned exposure: before → hidden-random-end timer →
  after, launched from the Exercises row), §11.3 (breathing: before → paced
  session → after, plus the ladder rule — see `docs/plans/11.3-breathing.md`) and
  §11.4 (PMR: script engine, all 5 ladder steps, voice prototype — see
  `docs/plans/11.4-pmr.md`) and §11.5 (BA: energy question → one random card →
  open tail on Today → ratings, plus the store and the BA ladder) are done. Three
  things still await a device run: §11.3 haptics and idle-timer suppression
  (CoreHaptics doesn't exist in the simulator), §11.4 TTS quality plus background
  audio, and §11.5's silent tail reminder. Current step: **§11.6 — оболочка**, cut
  into sub-steps in `docs/plans/11.6-shell.md`: 11.6a (launcher state subtitles +
  the article door), 11.6b (History), 11.6c («Что работает») and 11.6e
  (3-screen onboarding + the crisis section in Settings) are done. **11.6d —
  schedule + Today — is what remains**, and it is the one still carrying an
  unresolved product question: the spec requires a schedule but never says where
  the user sets it.
- SwiftData: container lives in `App/Inner_HeroApp.swift` (`StoreBootstrap`),
  currently holding `ExposureLogEntry`, `BreathingSessionEntry`, `PMRSessionEntry`,
  `BAActivity` and `BALogEntry`. The legacy 1.x store is wiped once on first
  2.0 launch; a store that stops opening after an in-place model edit is recreated
  automatically (pre-release: no versioned schemas). **Anything that flags the
  store's contents must be cleared when the store is deleted** — `deleteDefaultStore()`
  drops the BA seed flag for exactly this reason.

## Language & communication

- **Talk to the user in Russian.** Explanations, answers, summaries — in Russian.
- **Commit messages are in English**, like the rest of the repository's written
  artefacts. Only the conversation is Russian.
- **Code and source strings are in English (primary).** `Localizable.xcstrings` has
  `sourceLanguage: en`. Every new user-facing string is authored in English via
  `String(localized: "English text")`; Russian is added as a translation in
  `.xcstrings`. Never author displayed strings in Russian in code.
- Identifiers, type names, and code comments are in English.

## Stack

| Area          | Choice                         |
|---------------|--------------------------------|
| Platform      | iOS 26+                        |
| UI            | SwiftUI (no UIKit)             |
| Data          | SwiftData (local, no network)  |
| State         | `@Observable` / `@Query` / `@Environment` (Observation framework, not Combine) |
| Localization  | `Localizable.xcstrings` (EN source, RU translation) |
| Tests         | **Swift Testing** (`@Test` / `@Suite` / `#expect`) for new code |

## Commands

```bash
# Build for the simulator
xcodebuild -project "Inner Hero.xcodeproj" -scheme "Inner Hero" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# Tests
xcodebuild -project "Inner Hero.xcodeproj" -scheme "Inner Hero" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```

Single scheme **`Inner Hero`**; targets `Inner Hero`, `Inner HeroTests`, `Inner HeroUITests`.
The Xcode project uses file-system-synchronized groups — files added/removed on disk
are picked up automatically, no pbxproj edits needed.

### Running tests fast

The 43 unit tests execute in **0.1s**. A naive `xcodebuild … test` takes **90s** —
all of it overhead. Don't use it. Use `./scripts/test.sh` (see below), or its two
steps directly:

```bash
xcrun simctl boot "iPhone 17 Pro"          # once per machine session; ignore "already booted"

xcodebuild -project "Inner Hero.xcodeproj" -scheme "Inner Hero" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing "Inner HeroTests" build-for-testing            # ~5s

xcodebuild -project "Inner Hero.xcodeproj" -scheme "Inner Hero" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing "Inner HeroTests" \
  -parallel-testing-enabled NO test-without-building           # ~6s
```

Where the 90s went, and why each flag matters:

- `-parallel-testing-enabled NO` — Xcode *clones the simulator* for parallel runs
  (`Clone 1 of iPhone 17 Pro` in the log). For a suite that runs in 0.1s the cloning
  costs vastly more than the tests. Biggest single win: 90s → 49s.
- `build-for-testing` / `test-without-building` — plain `test` rebuilds the whole
  scheme including the UI-test target and its runner app even when `-only-testing`
  names just the unit bundle. Splitting the phases: 49s → 11s.
- pre-booted simulator — a cold boot is otherwise paid on every run.
- `-only-testing "Inner HeroTests"` — keeps `Inner HeroUITests` (4 tests, **310s**)
  out of the loop. Run the UI suite deliberately before a merge, not while iterating.

**Pacing:** an incremental build (~5s) is the loop while editing; run tests once when
a change set is complete, not after every edit. Note `Executed 0 tests` in xcodebuild
output is the legacy XCTest counter — Swift Testing reports separately
(`Test run with 43 tests in 12 suites passed`). Don't read it as a failure.

Known pre-existing failure: `SituationalExposureFormUITests/testAddNoteScrolls…`
fails on clean `main` too (simulator runner signing) — not a regression.

### Build output without the noise

The `ios-simulator-skill` plugin (project scope, see `.claude/settings.json`) collapses
a build to one line:

```bash
P=$(echo ~/.claude/plugins/cache/conorluddy/ios-simulator-skill/*/skills/ios-simulator-skill)
python3 $P/scripts/build_and_test.py --project "Inner Hero.xcodeproj" \
  --scheme "Inner Hero" --simulator "iPhone 17 Pro"
# → Build: SUCCESS (0 errors, 0 warnings) [xcresult-…]   ·  --get-errors <id> for detail
```

`--simulator` is required (the plugin defaults to iPhone 15, absent here). Its own
`--test` path does not expose the flags above, so it is slower than `scripts/test.sh`
— use it for builds, not test runs.

## Project map

```
Inner Hero/
├── App/Inner_HeroApp.swift        # Entry point + StoreBootstrap (ModelContainer, legacy wipe)
├── Core/
│   ├── DesignSystem/              # ⭐ Tokens and components — ALWAYS start here for UI
│   ├── Navigation/                # AppTab, NavigationRouter, AppRoute, AppRouteView
│   ├── Components/                # (empty for now — shared components return as flows land)
│   └── Utilities/                 # HapticFeedback, ExportDocument, ScreenAwake, BreathingHaptics, PMRVoice, AudioSession
├── Features/
│   ├── MainTab/Views/             # MainTabView, TodayView, ExercisesView, ArticleDetailView
│   ├── History/                   # §11.6b: ladders, active rule, exposure stats, feed, JSON export
│   ├── Activation/               # §11.5 BA flow: energy → one thing → tail → after + store
│   ├── Breathing/                 # §11.3 flow: before → session → after + ladder rule
│   ├── Exposure/                  # §11.1 situational form + §11.2 planned flow: Views/ViewModels/Components
│   ├── KnowledgeCenter/           # Articles list (kept as-is)
│   ├── Onboarding/                # §11.6e: 3 screens, zero questions (spec §7) + CrisisHelplineLink
│   ├── Relaxation/                # §11.4 PMR flow: before → picker → voiced session → after
│   └── Settings/                  # Settings + AppLock; Data section returns with new models
├── Models/                        # AppSettings; ExposureLogEntry / BreathingSession / PMRSession / BAActivity / BALogEntry (@Model) + BreathingLadder, PMRLadder, PMRScript, BALadder, BAPreset
├── Services/                      # ArticlesLoader/Store, NotificationManager (generic primitives)
├── Resources/                     # Localizable.xcstrings, Articles.json, assets
└── docs/redesign-spec.md          # ← product source of truth (repo root /docs)
```

## Conventions

### Design system (`Core/DesignSystem/`) — mandatory
Don't hardcode sizes/colors/fonts. Use tokens: `AppColors.*`, `Spacing.*`,
`CornerRadius.*`, `IconSize.*`, `TouchTarget.*`, `Opacity.*`, `AppAnimation.*`,
`.appFont(...)` via `AppTextStyle` (scales with Dynamic Type). Reusable components
live in `Components.swift` (`PrimaryButton`, `CircleButton`, `RadioCard`,
`SectionHeader`, form inputs `IntensitySlider` / `SuggestionChip` / `SelectableChip` /
`SegmentedChoice`, ...) and `ViewModifiers.swift` (`cardStyle`, `heroCardStyle`,
`touchTarget`, `pageBackground`). Card surfaces use `AppColors.cardBackground`,
never raw `.white`. The 0–10 anxiety scale is intentionally colour-neutral.
See `Core/DesignSystem/USAGE.MD`.

### Product principles
Every change is checked against spec §1. The ones that most often bite in code:
no streaks/minutes/gamification (1.4); leaving a session early SAVES data, never
discards it (1.5); predictions are captured before, never reconstructed after (1.6);
no menus between icon and action (1.2); adaptation only via session count, no
seen/experienced flags (1.7); no advice or recommendations anywhere (1.1).

### Navigation
Centralized `NavigationRouter` (`@Observable @MainActor`, `[AppTab: NavigationPath]`).
Routes live in `AppRoute`; routing is a `switch` in `AppRouteView`. Routes are added
back one by one as screens land — keep the enum minimal.

### MVVM
ViewModels are `@Observable @MainActor`; business logic lives there, views stay thin.
Inject time (`now: Date = Date()`, `calendar: Calendar = .current`) — never read the
clock inside logic.

### SwiftData (pre-release phase)
- New `@Model` types go to `Models/` and are registered in the container in
  `App/Inner_HeroApp.swift`.
- **No versioned schemas or migration plans until the 2.0 App Store release.**
  Models may be edited in place; wipe dev data when the store no longer opens.
  Versioned schemas + migration tests start at release.
- **A new non-optional property needs a default in its declaration**
  (`var kindRaw: String = BAKind.routine.rawValue`), not just a value in `init`.
  Without one CoreData cannot infer the migration ("missing attribute values on
  mandatory destination attribute") and the app fatalErrors at launch — the
  delete-and-retry in `makeContainer()` does **not** save you, because the failed
  first attempt can leave the file in place for the second.
- Enum-backed fields store `String` rawValues. **Never rename a persisted rawValue.**

### Testing
- New tests use Swift Testing; don't write new XCTest.
- Unit-heavy pyramid: ViewModels, services, model invariants. SwiftData tests use
  `ModelConfiguration(isStoredInMemoryOnly: true)`, fresh container per test.
- UI tests stay minimal (launch smoke only).

## Skills

Project skills in `.claude/skills/`: **/planning** (plan a rebuild step against the
spec before coding), **/design-screen** (UX blueprint of a screen before implementation),
**/implement-feature** (build a planned screen/flow), **/design-review** (check an
implemented screen against the interface codex), **/fix-bug** (diagnose → root cause →
minimal fix → verify). Prefer invoking them for matching work.

Interface codex: **`docs/design-principles.md`** — mandatory for any UI design/review.

## Don't

- Don't touch or reference `_to_delete/`.
- Don't use UIKit. Two recorded exceptions wrap APIs with no SwiftUI equivalent:
  `Core/Utilities/HapticFeedback.swift` and `Core/Utilities/ScreenAwake.swift`
  (TECH_DEBT #5). Don't add a third without saying why in the file.
- Don't hardcode colors/spacing/fonts instead of design-system tokens.
- Don't author new displayed strings in Russian in code (source is English).
- Don't rename persisted enum rawValues.
- Don't add screens, metrics, or features that are not in the spec — when in doubt,
  check §1 principles and ask.
