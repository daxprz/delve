---
xid: STO-ENEMIES-015
parent: ./epic.md
kind: story
effort: enemies
size: S
status: shipped
date: 2026-08-07
depends-on: [STO-ENEMIES-012, STO-ENEMIES-011]
bd-id: delve-3hh
shipped: 2026-08-07
tasks: 4
complete: 4
---

# One arm weakens their attack, both arms disarm them

## Summary

Take one of an enemy's arms and its attacks hurt far less. Take
**both** and it cannot hurt you at all — it will still chase you
around, completely harmless.

## Definition of Done

- [x] One arm gone = clearly less damage (**4.2** against a whole
      enemy's **12.0**).
- [x] Both arms gone = **zero** damage.
- [x] It still chases with no arms — harmless, not dead.
- [x] Proven by a headless test.

## Depends on

- **STO-ENEMIES-012** — shipped first.
- **STO-ENEMIES-011** — shipped first. This story would have been
  meaningless without it: there was no damage to reduce.

## Verification notes (2026-08-07)

In `tests/smoke_limb_effects.gd`. Two checks exist purely to stop the
rule collapsing into "losing an arm kills it": an armless enemy must
still be **alive** and must still **move**. Harmless is not the same
as dead, and the difference is the fun part.
