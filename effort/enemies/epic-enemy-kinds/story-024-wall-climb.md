---
xid: STO-ENEMIES-024
parent: ./epic.md
kind: story
effort: enemies
size: M
status: draft
date: 2026-08-14
depends-on: []
bd-id: delve-gq7
---

# The spider climbs walls

## Summary

The spider can go **up walls**. Corner it and it does not stop — it
walks up, so high ground and doorways stop being safe.

It suits this creature more than any other: four splayed legs gripping
a surface is what a spider is *for*, and nothing else in delve can
leave the floor except the Flyer.

## Definition of Done

- [x] Meeting a wall while chasing, it climbs instead of stopping.
- [x] It gains real height: **y 1.0 -> 3.3** against a test wall.
- [ ] It keeps climbing to the top. **It stalls partway** — this is
      what is unfinished.
- [ ] It comes off the wall when there is no longer one to hold.
- [ ] It still falls when knocked down — climbing must not make it
      immune to being ragdolled.
- [x] Walkers do NOT climb — asserted.
- [ ] Proven by a headless test. The height check is currently
      REPORTED, not asserted, and says why.

## Where this got to (2026-08-14) — NOT finished

**Climbing works.** A spider placed at a wall detects it (normal
`(0,0,1)`), switches off gravity and goes up: **y 1.0 to 3.3 m** over
about a second.

**Then it stalls.** Velocity drops to zero at 3.3 m with the player
still 5.7 m above it, and it just hangs there. Not yet understood — the
chase branch should still be driving it upward.

Only the spider climbs; the Walker at the same wall does not, and that
IS asserted.

The height check inside `smoke_crawler.gd` is deliberately a **print,
not an assert**: that phase inherits a crawler which has already been
staggered by an earlier phase, so a failure there would not mean what
it appears to. Asserting on a setup I do not trust would be worse than
not asserting at all.

Next step: reproduce the stall in isolation (the debug harness that
produced the 1.0 -> 3.3 figures) and find why velocity goes to zero.

## Out of scope

- Ceilings, or hanging upside down.
- Climbing while carrying something.
