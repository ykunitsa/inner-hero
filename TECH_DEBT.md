# Inner Hero — Tech Debt & "Careful here"

Reset after the 2.0 teardown (2026-07-17). Most pre-teardown items died with the
legacy code. Remove items once fixed.

Priorities: 🔴 critical · 🟠 important · 🟡 nice-to-have.

---

## 🔴 Critical

### 0. Widget App Group capability not yet added in Xcode (§11.7)
The `InnerHeroWidgetExtension` target exists and builds green (four widgets, shared
sources wired via a synchronized-group exception set). **One step remains, and only the
UI can do it:** add capability **App Groups** → `group.wrongteam.Inner-Hero` on **both**
the `Inner Hero` and `InnerHeroWidgetExtension` targets (Signing & Capabilities — a
developer-portal round trip, team `PFN9H3KS4G`, so it can't be scripted). Until then
`UserDefaults(suiteName:)` is nil on both sides: the app writes the snapshot nowhere and
every widget shows its default state. App and widget both still build and run. Details
in `docs/plans/11.7-widget.md` → "Xcode setup".

### 1. `_to_delete/` awaits manual deletion
The teardown moved legacy code to `_to_delete/` (the cloud bridge can't delete files
on the mounted folder). Delete it manually (`git rm -r _to_delete` + commit).
`_to_delete/git-stale-locks/` collects git lock files moved aside for the same reason.

### 2. Test coverage reset to smoke tests
Teardown removed all logic tests together with the legacy code. Every new ViewModel/
model ships with Swift Testing coverage (see CLAUDE.md); don't let the gap grow.

## 🟠 Important

### 3. `Components.swift` is ~1,265 lines
Split into `Buttons/`, `Cards/`, `Navigation/`, `Modals/` as components get touched.
Also: several components (session modals references, chart styles) may now be dead
after the teardown — audit while splitting.

### 4. Stale localization keys
`Localizable.xcstrings` (~320 KB) still carries keys for deleted screens, plus old
`stale` entries. Prune once the new screens stabilize (script it; don't hand-edit).

### 5. UIKit escape hatches (recorded, not accidental)
CLAUDE.md says no UIKit. Two files break it on purpose, both wrapping an API with no
SwiftUI equivalent on iOS 26 — keep the exceptions to these files:
- `Core/Utilities/HapticFeedback.swift` — the feedback generators.
- `Core/Utilities/ScreenAwake.swift` — `isIdleTimerDisabled`, so the breathing session
  doesn't go dark (and take CoreHaptics with it) mid-exercise. See the plan doc
  `docs/plans/11.3-breathing.md` §2, decision 8.

## 🟡 Nice-to-have

### 6. `ArticlesLoader` — unsafe static cache
`cachedArticlesByLocalization` is a mutable static, not refreshed when the locale
changes at runtime. Invalidate on locale change / thread-safe access.

### 7. Hardcoded values past the design system
Kept files still contain some hardcoded `.font(.system(size:))` / frames (e.g. row
chevrons at size 13). Replace with tokens as screens get touched.

### 8. Exposure duration slider could move to the scrolling ruler
`DurationRangeSlider` still uses the static `TickTrack`; §11.3 introduced
`ScrollingTickRuler` (tape under a fixed marker). Worth unifying **only** if the
exposure control keeps its two markers — the ruler is single-value today, so this is
a real component change, not a swap.

### 9. The ladder suggestion line exists twice
`PMRBeforeView.suggestionLine` and `BAComponents.BASuggestionLine` are the same
control — accent-tinted row, tap applies, renders nothing when there is no
suggestion. Breathing will make it three. Unify into one component in
`Components.swift` when the third appears, not before: the two ladders return
different suggestion types, so a shared version needs a small protocol or a
plain `(glyph, text, action)` init, and that is worth designing once with three
call sites in hand.

### 10. `AppTab` labels are bare literals
`MainTabView` passes plain strings to `.accessibilityLabel` ("Today", "Schedule", …)
rather than `String(localized:)`, so VoiceOver announces the tabs in English on a
Russian device. Pre-existing across all five tabs; fix in one pass, not per tab.
