---
name: fix-bug
description: >
  Diagnose and fix a bug in Inner Hero: build errors, crashes, wrong UI/behavior,
  broken data. Use when the user reports something broken: "почини", "баг", "ошибка",
  "не работает", "крэш", "не собирается", or pastes a compiler/runtime error.
---

# Fixing a bug

## Diagnose before patching

1. Reproduce the understanding: read the exact error/report, find the code with
   grep, read the surrounding file — not just the failing line.
2. Name the root cause explicitly before proposing an edit. If the cause is unclear,
   add temporary diagnostics or ask for the missing detail (console output, steps).
3. Check `TECH_DEBT.md` — the bug may be a known weak spot; fix it properly there
   or update the entry rather than papering over it.

## Fix

- Minimal change that removes the cause, not the symptom. Follow the design system
  and MVVM conventions even in fixes — no quick hardcodes.
- Logic bug → write the failing Swift Testing test first, then make it pass.
- Never fix by reintroducing code from `_to_delete/`.
- A bug in behavior that the spec forbids (streak, lost early-exit data, hidden
  choice) is fixed toward the spec, not toward the old behavior.

## Verify

1. Run tests; build for the simulator (or ask the user to build in Xcode).
2. State in one or two sentences: cause → fix → how it was verified.
3. If the same class of bug can exist elsewhere, grep for siblings and mention them.
