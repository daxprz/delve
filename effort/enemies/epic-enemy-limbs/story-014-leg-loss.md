---
xid: STO-ENEMIES-014
parent: ./epic.md
kind: story
effort: enemies
size: S
status: shipped
date: 2026-08-07
depends-on: [STO-ENEMIES-012]
bd-id: delve-7vh
shipped: 2026-08-07
tasks: 5
complete: 5
---

# One leg slows them, both legs kill them

## Summary

Take one of an enemy's legs and it can only limp after you. Take
**both** and it dies.

## Definition of Done

- [x] An enemy missing one leg moves clearly slower (1.20 m/s against
      a whole enemy's 3.00 — 40%).
- [x] "Clearly slower" is measured, not guessed.
- [x] An enemy that loses **both** legs dies.
- [x] It leaves a body behind (STO-ENEMIES-016).
- [x] Proven by a headless test.

## Out of scope

- Crawling with no legs — losing both is death, not a new way to move.

## Depends on

**STO-ENEMIES-012** — shipped first.

## Verification notes (2026-08-07)

In `tests/smoke_limb_effects.gd`. The speed is compared against the
whole-enemy figure rather than against a hard-coded number, so the
check still means something if `Enemy.SPEED` is ever retuned.
