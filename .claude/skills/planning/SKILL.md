---
name: planning
description: >
  Plan the next feature, screen, or rebuild step for Inner Hero BEFORE writing code.
  Use when the user asks to plan, design, or figure out an approach: "спланируй",
  "как будем делать", "что дальше по редизайну", "разбери следующий шаг", "plan",
  or names a spec section / implementation-order item to tackle next.
---

# Planning a rebuild step

Produce a concrete implementation plan, not code. Never start editing files from
this skill — the output is a plan the user confirms first.

## Steps

1. **Read the spec first.** Open `docs/redesign-spec.md`:
   - the section for the feature being planned;
   - §1 (the 10 product principles) — every plan is checked against them;
   - §11 (implementation order) — confirm this step is actually next; if the user
     asks for something out of order, say so and ask.
2. **Read the interface codex** `docs/design-principles.md` when the step includes
   UI — plans for screens must respect it (or hand off to `/design-screen`).
3. **Read the current state.** Relevant kept code (`Inner Hero/`), `TECH_DEBT.md`.
   Never look into `_to_delete/` for reference — that design is dead.
4. **Write the plan** with these sections, kept short:
   - **Что строим** — one paragraph, from the spec, incl. what is deliberately NOT built.
   - **Данные** — SwiftData model changes (fields, rawValue contracts, container impact).
   - **Файлы** — exact files to create/edit (Features/<Module>/{Views,ViewModels,Components}).
   - **Строки** — new user-facing strings (EN source) that need RU translations.
   - **Тесты** — which pure logic gets Swift Testing coverage.
   - **Definition of done** — observable behavior, incl. "collects real data on device".
5. **Principles check.** End with one line per violated-or-risky principle, or
   "принципы: чисто". Typical traps: added choice on the user's path (1.2), fields
   reconstructing predictions after the fact (1.6), streak-like metrics (1.4),
   exit that discards data (1.5), advice/recommendation copy (1.1).
6. Present the plan and wait for confirmation before implementing
   (then `/implement-feature` takes over).
