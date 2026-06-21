# Inner Hero — Tech Debt & "Careful here"

Known weak spots as of 2026-06-21. Don't treat the items below as a model. When working
nearby — improve where possible, but don't break things "in passing". Remove items once fixed.

Priorities: 🔴 critical · 🟠 important · 🟡 nice-to-have.

---

## 🔴 Critical

### 1. Almost no tests (<1% coverage)
6 model tests + empty UI templates from the project boilerplate. Key areas uncovered:
`Services/SessionCompletionService`, `Features/Schedule/ViewModels/ScheduleViewModel`,
migrations in `App/Schema/AppMigrationPlan`.
→ First cover `SessionCompletionService` (idempotency) and the V1→V2 migration.

### 2. The V1→V2 migration deletes data irreversibly
`App/Schema/AppMigrationPlan.swift` deletes BA assignments, completions, and legacy models
without archiving. No transactional guarantee between `willMigrate`/`didMigrate`; seed data
in `didMigrate` runs without a duplicate check. No tests.
→ Archive data before deleting; add a dedup check before insert; cover with a test.

### 3. `fatalError` in release builds
`App/Inner_HeroApp.swift:56` — if the in-memory fallback fails, the app crashes in production.
Plus a nested `#if DEBUG` inside `#else` (a conditional-compilation logic error, ~lines 32–56).
→ Replace with graceful degradation + diagnostics; remove the nested `#if`.

### 4. Weak relationships in the data layer (risk of orphaned records)
`ActivationSession.activityId: UUID` and `ActivationTask.categoryId: UUID` are "manual FKs"
instead of `@Relationship`. No cascade delete → deleting a task leaves dangling sessions.
In `ExerciseAssignment` the types are mixed: some fields are `UUID?`, others are `String?`
(enum rawValue).
→ Move to `@Relationship` with `deleteRule: .cascade`; unify the types (requires a migration).

---

## 🟠 Important

### 5. Timer / Task without cancellation
Session flow: `Timer.publish(...).autoconnect()` in `@State` isn't cancelled in `onDisappear`.
The "roulette" animation in `Features/BehavioralActivation/Views/BehavioralActivationRootView.swift`
(~lines 523–568) runs a `Task { @MainActor … }` without cancellation and does `randomElement()!` /
`delays.last!` (potential crash + updating the UI of a dismissed view).
→ Cancel the Timer/Task in `onDisappear`; replace force-unwraps with `?? fallback`.

### 6. Errors swallowed silently
~36 `try?` with `?? 0`/fallback, especially in `ScheduleViewModel` (5–7 in a row) — on a DB
failure the user sees wrong numbers instead of a log/crash. ~21 `print()` instead of `Logger`
(don't reach Console.app, no levels).
→ Introduce a `Logger` (os.log) with levels; don't swallow DB errors without logging.

### 7. "Massive views"
Largest files (lines): `Core/DesignSystem/Components.swift` (1265),
`Features/BehavioralActivation/Views/BehavioralActivationRootView.swift` (920),
`Features/Sessions/Views/ActiveSessionView.swift` (880),
`Features/Schedule/Views/ScheduleTabView.swift` (578),
`Features/Exposures/Components/StepCardView.swift` (578),
`Features/Sessions/Views/MuscleRelaxationSessionView.swift` (571),
`Features/MainTab/Views/HomeView.swift` (558).
They mix UI + business logic + DB work + timers.
→ Move logic into a ViewModel; split into subcomponents. `Components.swift` — break out into
`Buttons/`, `Cards/`, `Navigation/`, `Modals/`.

### 8. Inconsistent MVVM
Some features have a ViewModel (Home, Schedule, BehavioralActivation), others don't (Exposures —
logic in views). `HomeViewModel.refresh()` takes 11 parameters.
→ For changes, move business logic into a ViewModel; consider passing an aggregate instead of a
long parameter list.

### 9. `BARoute` outside `AppRoute`
`Features/BehavioralActivation/BARoute.swift` is a separate enum that `NavigationRouter` has to
accept as a generic `Hashable` → blurred coupling.
→ Fold `BARoute` into `AppRoute` as a case (`case ba(BARoute)`).

---

## 🟡 Nice-to-have

### 10. Duplicated UI patterns
4 row kinds in `SettingsView` (navRow/actionRow/linkRow/infoRow), 3 identical filter menus in
BehavioralActivation, a repeated "session → result → save" pattern across three session views.
→ Extract `SettingsRow`, `FilterMenu<Item>`, a shared session-save helper.

### 11. Hardcoding past the design system
~60+ places with hardcoded `.frame`/`cornerRadius`/`.font(.system(size:))`/RGB colors instead of
tokens (`Spacing`, `CornerRadius`, `AppTextStyle`, `AppColors`).
→ Replace with tokens as you touch the corresponding screens.

### 12. Snapshot data duplication
`ExerciseCompletion` stores a snapshot of fields from `ExerciseAssignment` (`exerciseType`,
`exposureId`, `*Type`, `activityId`) — when the assignment changes, history shows stale data.
→ Decide deliberately: a reference + cache only `displayTitle`, or an explicit snapshot-refresh strategy.

### 13. `NavigationRouter` — duplicated switch-case
A `switch tab` in `navigate`/`navigateBack` for each tab.
→ Replace with `[AppTab: NavigationPath]`.

### 14. `ArticlesLoader` — unsafe static cache
`cachedArticlesByLocalization` is a mutable static, not refreshed when the locale changes at runtime.
→ Invalidate the cache on locale change / thread-safe access.

### 15. Misc
- `SampleDataLoader` — no dedup on repeat load (risk of duplicates).
- `NotificationManager` — revisit the weekday logic and `repeats: true`.
- `AppRouteView` loads all `@Query` sets for individual routes (inefficient on large data).
- Clean up `stale` entries in `Localizable.xcstrings`.
