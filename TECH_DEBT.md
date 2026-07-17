# Inner Hero — Tech Debt & "Careful here"

Reset after the 2.0 teardown (2026-07-17). Most pre-teardown items died with the
legacy code. Remove items once fixed.

Priorities: 🔴 critical · 🟠 important · 🟡 nice-to-have.

---

## 🔴 Critical

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

## 🟡 Nice-to-have

### 5. `ArticlesLoader` — unsafe static cache
`cachedArticlesByLocalization` is a mutable static, not refreshed when the locale
changes at runtime. Invalidate on locale change / thread-safe access.

### 6. Hardcoded values past the design system
Kept files still contain some hardcoded `.font(.system(size:))` / frames (e.g. row
chevrons at size 13). Replace with tokens as screens get touched.

### 7. Onboarding is the old single screen
Becomes the 3-screen zero-questions flow (spec §7) in §11.6. Until then the old
welcome/disclaimer screen stays.
