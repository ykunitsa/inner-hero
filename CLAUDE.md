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
  from the gear on Today. Exercises and History are placeholders that light up as
  flows are rebuilt in spec §11 order. §11.1 (situational exposure form, hero card
  on Today → sheet) is done. Current step: **§11.2 — planned exposure session**.
- SwiftData: container lives in `App/Inner_HeroApp.swift` (`StoreBootstrap`),
  currently holding `ExposureLogEntry`. The legacy 1.x store is wiped once on first
  2.0 launch; a store that stops opening after an in-place model edit is recreated
  automatically (pre-release: no versioned schemas).

## Language & communication

- **Talk to the user in Russian.** Explanations, answers, summaries — in Russian.
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

## Project map

```
Inner Hero/
├── App/Inner_HeroApp.swift        # Entry point + StoreBootstrap (ModelContainer, legacy wipe)
├── Core/
│   ├── DesignSystem/              # ⭐ Tokens and components — ALWAYS start here for UI
│   ├── Navigation/                # AppTab, NavigationRouter, AppRoute, AppRouteView
│   ├── Components/                # (empty for now — shared components return as flows land)
│   └── Utilities/                 # HapticFeedback, ExportDocument
├── Features/
│   ├── MainTab/Views/             # MainTabView, TodayView; ExercisesView, HistoryView (placeholders)
│   ├── Exposure/                  # Situational form (§11.1): Views + ViewModels
│   ├── KnowledgeCenter/           # Articles list (kept as-is)
│   ├── Onboarding/                # 1-screen shell; becomes 3 screens per spec §7 in §11.6
│   └── Settings/                  # Settings + AppLock; Data section returns with new models
├── Models/                        # AppSettings (ThemeMode, AppStorageKeys), ExposureLogEntry (@Model)
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
- Don't use UIKit.
- Don't hardcode colors/spacing/fonts instead of design-system tokens.
- Don't author new displayed strings in Russian in code (source is English).
- Don't rename persisted enum rawValues.
- Don't add screens, metrics, or features that are not in the spec — when in doubt,
  check §1 principles and ask.
