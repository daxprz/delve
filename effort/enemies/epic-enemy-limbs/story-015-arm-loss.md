---
xid: STO-ENEMIES-015
parent: ./epic.md
kind: story
effort: enemies
size: S
status: draft
date: 2026-08-07
depends-on: [STO-ENEMIES-012, STO-ENEMIES-011]
bd-id: delve-3hh
---

# One arm weakens their attack, both arms disarm them

## Summary

Take one of an enemy's arms and its attacks hurt much less. Take
**both** and it cannot hurt you at all — it will still chase you, but
it is completely harmless.

That last part is the fun bit: an armless enemy is not dead, it is
*defeated*. It follows you around unable to do a thing about it.

## Definition of Done

- [ ] An enemy with one arm gone deals clearly less damage than a
      whole one — a measured comparison, not a guess.
- [ ] An enemy with **both** arms gone deals **zero** damage.
- [ ] It still chases you with no arms; it is harmless, not dead.
- [ ] Proven by a headless test.

## Out of scope

- Losing an arm changing anything other than damage.

## Depends on

- **STO-ENEMIES-012** — arms cannot come off until limbs can come off.
- **STO-ENEMIES-011** — there must be an attack before a missing arm
  can weaken one. This story is meaningless without it.
