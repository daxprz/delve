---
xid: STO-CHARACTER-075
parent: ./epic.md
kind: story
effort: player-character
size: M
status: done
date: 2026-08-14
depends-on: []
bd-id: delve-1f1t
---

# He has four arms

## Summary

> "a mage with 4 arms" — operator, 2026-08-14

**Four** arms, not two. Generated in code like every other body part in
delve, so no two mages have quite the same ones.

Four is the readable number: it is instantly obviously wrong for a
person, without becoming a mass of limbs you cannot count. It also
says *magic* before he has cast anything — you know what he is the
moment you see him.

## Definition of Done

- [x] The Mage has four arms — **4 hands**, against the Runner's 2.
- [x] They are built by the same procedural body code as everyone
      else's, from the same seed.
- [x] All four are in **different places**: the closest two hands are
      **0.259 m** apart, and the lower pair sits **0.25 m below** the
      upper pair (y 0.512 vs 0.766). You can count them.
- [x] They move with him: walking, the lower arms swing **0.090 rad**,
      and **out of step** with the top pair by up to 0.027 rad — so the
      four do not move as one block.
- [x] Nobody else grows extra arms. Asserted against a Runner in the
      same test.
- [x] Proven by `tests/smoke_mage.gd`.

## Built (2026-08-14)

The second pair hangs from its own shoulders lower down the torso,
tucked in slightly and 14% shorter, derived from the torso the body
actually generated rather than typed in as metres — so a big Mage and a
small one both get arms that fit them.

**Two bugs in my own test, both of the same family:** it first measured
a man standing still on no floor and reported 0.0000, then measured the
*average of a left and a right arm* — which swing in opposite
directions and cancel to exactly zero. Both would have reported four
welded arms on a body whose arms were swinging 0.6 radians.

## Out of scope

- The arms doing anything. This is what he looks like, not what he
  does.
- Reusing the Grabber's mechanical arms. Those are a machine; these are
  his own.
