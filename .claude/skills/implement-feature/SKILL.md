---
name: implement-feature
description: >
  Implement a planned Inner Hero feature or screen: new SwiftUI screen, view model,
  SwiftData model, or flow from docs/redesign-spec.md. Use when the user says to
  build/implement/code something: "реализуй", "сделай экран", "пиши код", "имплементируй",
  "продолжаем шаг N", or after a /planning plan is approved.
---

# Implementing a feature

## Before writing code

1. Read the relevant section of `docs/redesign-spec.md` **and** §1 (principles).
   If there is an approved plan from `/planning` in the conversation — follow it.
2. For UI work, read `docs/design-principles.md` (one job per screen, states,
   tone, accessibility) and follow the `/design-screen` blueprint if one exists.
3. Read `Core/DesignSystem/USAGE.MD` and check `Components.swift` for existing
   components before creating new ones (`PrimaryButton`, `CircleButton`, `RadioCard`,
   `SectionHeader`, `cardStyle`, ...).
4. Check `CLAUDE.md` conventions; never reference anything in `_to_delete/`.

## While writing

- **Design system only**: tokens (`AppColors`, `Spacing`, `CornerRadius`, `IconSize`,
  `Opacity`, `AppAnimation`) and `.appFont(...)`. No raw sizes, colors, or system fonts.
- **MVVM**: business logic in an `@Observable @MainActor` ViewModel; views stay thin.
  Inject time (`now: Date = Date()`, `calendar: Calendar = .current`) — no clock reads
  inside logic.
- **Strings**: authored in English via `String(localized: "...")`; add the Russian
  translation to `Resources/Localizable.xcstrings` in the same change.
- **SwiftData (pre-release phase)**: models live in `Models/`, are registered in the
  container in `App/Inner_HeroApp.swift`, and may be edited in place — no versioned
  schemas until the 2.0 App Store release. Enum-backed fields store String rawValues;
  never rename a persisted rawValue.
- **Navigation**: add cases to `AppRoute` + branches in `AppRouteView`; push via
  `NavigationLink(value:)` or `path.append(...)`.

## After writing

1. Add Swift Testing coverage (`@Test`/`#expect`, in-memory `ModelConfiguration`)
   for view-model logic and model invariants. No new XCTest.
2. Build: `xcodebuild -project "Inner Hero.xcodeproj" -scheme "Inner Hero"
   -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build` (or ask the user
   to build in Xcode if running remotely).
3. Self-review against the 10 principles; call out anything debatable to the user.
4. Update `CLAUDE.md` / `TECH_DEBT.md` only if architecture or known weak spots changed.
