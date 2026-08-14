---
xid: STO-CHARACTER-066
parent: ./epic.md
kind: story
effort: character
size: M
status: draft
date: 2026-08-14
depends-on: []
bd-id: delve-8nqr
---

# Claw scratches that get faster and harder the more you click

## Summary

The Runner scratches with its claws: **LMB** for one side, **RMB** for
the other. A single press is a light flick — **0.25 damage**. But the
faster you click, the faster it swings AND the harder each scratch
lands.

So it is a weapon that rewards frantic clicking rather than timing —
very different from the Grabber's heavy momentum punches or the
Sniper's one slow deliberate shot.

## Definition of Done

- [ ] LMB scratches with one claw, RMB with the other.
- [ ] One press on its own does **0.25** damage.
- [ ] Clicking faster makes it swing faster.
- [ ] Clicking faster makes each scratch do more damage.
- [ ] There is no minimum gap between clicks other than how fast you
      can press.
- [ ] Only the Runner has it.
- [ ] Proven by a headless test comparing slow clicking with fast
      clicking.

## Open question — "the damage doesn't stack"

The operator said the damage **must not stack**, and that could mean
two different things. **Not yet decided, must be settled before
building:**

1. The build-up has a **ceiling** — clicking ever faster stops helping
   past some point, so you cannot reach absurd damage.
2. Two scratches landing on the same enemy at the same moment count
   **once**, rather than both applying.

Both are reasonable readings of the same sentence, and they need
different code. Ask before building.

## Out of scope

- A separate claw model. The existing arms swing.
