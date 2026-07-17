---
name: design-review
description: >
  Review an implemented Inner Hero screen against the interface codex. Use when the
  user shows a screenshot from the simulator/device, or asks to check a screen:
  "посмотри экран", "ревью дизайна", "что не так с экраном", "проверь UI",
  "design review", or after a screen from /implement-feature first builds.
---

# Reviewing a screen

## Steps

1. Identify the screen; read its code (`Features/...`) and, if a screenshot is
   provided, inspect it visually. Read `docs/design-principles.md` (the checklist
   at the bottom is the rubric) and the relevant `docs/redesign-spec.md` section.
2. Run the checklist:
   - hierarchy readable in one second; exactly one primary action;
   - taps-to-done on a bad day; anything removable;
   - token discipline — grep the screen's files for `.system(size:`, `Color(red:`,
     raw paddings/frames not from `Spacing`/`IconSize`;
   - states: empty / `sessions == 0` / error / early-exit-saves-data;
   - copy tone: calm facts, no praise/guilt/exclamations; EN source + RU translation
     both present in `.xcstrings`;
   - accessibility: Dynamic Type behavior, VoiceOver labels, 44pt targets, dark mode;
   - nothing from the codex "never" list (badges, streaks, rings, confetti...).
3. Report findings **by severity, max 7 items**, each as: what — where (file:line
   or screenshot area) — how to fix (one line). If the screen passes, say so in one
   sentence; do not invent nitpicks.
4. Only apply fixes if the user asks; this skill reports.
