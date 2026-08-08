---
xid: STO-ENEMIES-013
parent: ./epic.md
kind: story
effort: enemies
size: S
status: shipped
date: 2026-08-07
depends-on: [STO-ENEMIES-012]
bd-id: delve-g1g
shipped: 2026-08-07
tasks: 4
complete: 4
---

# Losing the head is instant death

## Summary

Knock an enemy's head off and it dies immediately — no matter how much
health it had left.

## Definition of Done

- [x] An enemy whose head comes off dies at once.
- [x] It dies **even at full health** — the test starts it undamaged.
- [x] It leaves a body behind (STO-ENEMIES-016) rather than vanishing.
- [x] Proven by a headless test.

## Out of scope

- A special animation or sound for a head shot.

## Depends on

**STO-ENEMIES-012** — shipped first.

## Verification notes (2026-08-07)

In `tests/smoke_limb_effects.gd`. The check that matters asserts the
enemy is at **full health (60/60)** immediately before the head comes
off — otherwise the test would pass just as happily on an enemy that
was about to die anyway, and would prove nothing about beheading.
