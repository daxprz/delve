---
xid: STO-ENEMIES-012
parent: ./epic.md
kind: story
effort: enemies
size: M
status: shipped
date: 2026-08-07
depends-on: []
bd-id: delve-yow
shipped: 2026-08-07
tasks: 6
complete: 6
---

# Limbs can be torn off

## Summary

Hit a downed enemy hard enough and the limb you hit comes off, drops
to the floor as a real physics object, and stays there.

This is the **foundation** of the limb epic — head-kills, leg limps
and weakened arms are all just consequences of a limb being gone.

The hard part was already done. `ragdoll.gd` builds 11 separate rigid
bodies joined by cone-twist joints, so a limb is held on by exactly
**one joint**. Taking it off is freeing that joint; anything further
down stays attached to what came off, so pulling an upper arm brings
the forearm with it.

## Definition of Done

- [x] A hard enough hit on a limb detaches it (dv >= 14).
- [x] A weak hit does not — a knockdown (dv >= 7.5) tears nothing off.
- [x] The detached part falls, lands, and can be pushed around.
- [x] The remaining body stays stable where the limb came off.
- [x] The enemy remembers which limbs it has lost.
- [x] A headless test proves detachment above the threshold and not
      below it (18 checks).

## Out of scope

- What losing a limb *does* — stories 013, 014, 015.
- Blood, gore, or stumps.
- Limbs coming off a standing enemy: it must be ragdolled first.
- **The Runner's tail cannot dismember.** Deliberate: STO-ENEMIES-009
  was a segfault caused by the tail re-shoving an enemy that was
  already ragdolling, each shove feeding back into the tail. The gun
  and the Grabber's punch both pass a real hit point and can take
  limbs off; the tail stays out of that path on purpose.

## A severed limb used to vanish when its owner stood up (2026-08-13)

Found while building the fingers, of all things: extending an unrelated
test's wait from 1.5 s to 3 s pushed it past the point where a downed
enemy gets back up — and `_exit_ragdoll` frees the whole ragdoll,
**including limbs that had been torn off it**.

So an arm you had ripped off popped out of existence the moment its
owner stood, which flatly contradicts this story's "the detached part
falls, lands, and stays there".

Fixed with `Ragdoll.release_detached()`: severed parts are handed to
the ragdoll's parent, keeping their transform and velocity, before the
ragdoll is freed. A limb on the floor belongs to the world, not to the
body it came off.

Worth remembering: the bug had been there since this story shipped and
no test caught it, because every test looked at the limb within a
second and a half — well inside the window before an enemy stands.

## Verification notes (2026-08-07)

`tests/smoke_enemy_limbs.gd`, 18 checks.

Which limb a blow takes is decided by **where it landed** —
`apply_knockback` now accepts the hit point, and the ragdoll returns
the nearest part to it. The gun passes the exact point its ray struck,
so a shot to the head really is a shot to the head; the Grabber's
punch passes the point of contact.

Deliberately checked the negative case, not just the positive: a
knockdown at dv 7.5 must tear **nothing** off, or every scuffle would
dismantle an enemy. Also checked the body does not explode where the
limb came off (pelvis measured at 9.6 m/s, nowhere near the joint
instability of STO-ENEMIES-010) and that a limb already gone cannot
come off twice.
