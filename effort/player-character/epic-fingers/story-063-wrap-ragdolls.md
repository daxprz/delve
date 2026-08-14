---
xid: STO-CHARACTER-063
parent: ./epic.md
kind: story
effort: character
size: M
status: draft
date: 2026-08-14
depends-on: []
bd-id: delve-0wa
---

# Fingers wrap a grabbed ragdoll, and keep hold while dragging it

## Summary

The fingers close around a **grabbed enemy** the same way they close
around a crate — and they **keep** their grip while you haul the body
across the ground, re-fitting as it swings and drags.

A ragdoll is the hardest case there is. A crate is one rigid box that
sits where it is put; a limp enemy is eleven jointed parts that
tumble, swing and catch on the floor while you drag them. If the grip
survives that, it survives anything.

Same rule as everything else here: nothing authored. Each finger
sweeps until it meets the body part it is holding, and does it again
every tick.

## Definition of Done

- [x] Grabbing an enemy closes the fingers around the part held.
- [x] Fingers close by **different** amounts, as on any other object.
- [x] Dragging the body along the ground keeps the grip, and the
      curls re-fit as it moves rather than freezing.
- [x] The fingers do not fold through the body they are holding.
- [x] Letting the body go opens the hand again.
- [x] Proven by `tests/smoke_wrap_ragdoll.gd`, which ragdolls a real enemy and hauls it across the ground.

## Verification notes (2026-08-14)

The ragdoll refused to be gripped at first — every finger closed fully
on nothing, exactly as a crate had. The cause was subtler and had been
there since the arms were built:

**The hand's roll was arbitrary.** `_orient_between` built the hand's
basis from `Quaternion(Vector3(0,0,1), dir)`, which fixes where the
hand POINTS but says nothing about which way the PALM faces. So the
palm could be turned away from the very thing it was holding, and the
fingers curled into empty air behind it.

Nothing had ever cared before, because until fingers existed the hand
was a symmetrical block with no front.

Fixed by rolling the hand so its -Y faces whatever it holds, while +Z
still runs along the arm. Only the hand gets this — every other part
has no front.

Teeth-checked by disabling the roll: this test fails 2 checks again,
while the crate test still passes. That difference is the point — a
crate sat where it was put, so the palm happened to face it often
enough; a dragged ragdoll swings, and only a palm that tracks it can
hold on.

## Out of scope

- Individual fingers gripping different ragdoll parts. The hand holds
  the part it grabbed.

## Depends on

**STO-CHARACTER-062** — the per-finger surface search.
