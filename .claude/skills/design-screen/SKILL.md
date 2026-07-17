---
name: design-screen
description: >
  Design the UX of an Inner Hero screen BEFORE it is implemented: layout, states,
  copy, component mapping. Use when the user asks how a screen should look or work:
  "спроектируй экран", "как должен выглядеть", "дизайн формы", "продумай интерфейс",
  "design the screen", or when /planning hands off a screen that needs UX design.
---

# Designing a screen

Output is a blueprint, not code. `/implement-feature` consumes it afterwards.

## Inputs to read first

1. `docs/redesign-spec.md` — the section describing this screen, plus §1 (principles).
2. `docs/design-principles.md` — the interface codex (one job per screen, choice is
   expensive, mandatory states, tone of voice, accessibility, the "never" list).
3. `Core/DesignSystem/USAGE.MD` and `Components.swift` — what already exists.

## Blueprint format

Keep it compact; every section is required:

- **Работа экрана** — one sentence: the single job and the single primary action.
- **Вайрфрейм** — text wireframe top to bottom, one line per element, marking the
  accent element (max one) and what recedes.
- **Компоненты** — element → existing DS component/token mapping; flag anything that
  genuinely needs a new component (rare — justify it).
- **Состояния** — empty / `sessions == 0` / error / early-exit; what each shows.
  Early exit saves data and the button names the fact (never "Cancel").
- **Плохой день** — taps from tab to done; what was cut to get there; what requires
  the keyboard and why that is acceptable.
- **Тексты** — draft copy for titles/buttons/labels: EN source + RU translation,
  calm factual tone (no praise, no exclamation marks, no guilt).
- **Проверка** — one line per design-principles checklist item: ok / issue.

## Rules

- No code, no colors/sizes outside DS tokens, no new metrics or gamification.
- If the spec and a "nicer" design conflict — the spec wins; raise the conflict
  explicitly instead of silently deviating.
- End by asking the user to confirm the blueprint before implementation.
