---
xid: STO-CHARACTER-080
parent: ./epic.md
kind: story
effort: player-character
size: L
status: done
date: 2026-08-14
depends-on: []
bd-id: delve-4gxe
---

# An enemy is 2D only while its hitbox is on the line

## Summary

> "any enmys that get in that line is seen as a 2d enemy only when the
> hit box is in the line of the 2d world"

The sharpest rule in the epic, and the operator was precise about it:

**An enemy is in the Mage's 2D world only while its HITBOX is on the
plane. Not before, not after, and not as a permanent state.**

So a monster wandering across his plane fades into his world, becomes
something he can fight and be hurt by, and then wanders out of it
again. The danger is not "this enemy is 2D" — it is "this enemy is on
my line, right now".

## Confirmed, and they come and go (operator, 2026-08-14)

Asked to check this back, the operator confirmed it exactly:

> "yes only when its in the line and the eneymey is able to go in and
> out"

So it is not a one-way door. An enemy can be in his world, leave it,
and come back — as many times as it likes, purely by where it is
standing. **In and out** is the required behaviour, not a side effect.

## Why that is the right rule

Because it makes the plane a **place**, with a real edge. The Mage is
safe from anything off the line and in danger from anything on it,
which turns every fight into a question of where things are standing —
and it gives him something to do while flat besides travel.

It also falls out of one measurement rather than a list of special
cases, which is how the spider's clamber rule works and why that one
has held up.

## Definition of Done

- [x] An enemy whose hitbox intersects the plane is in his 2D world.
- [x] One whose hitbox does not is NOT.
- [x] It updates continuously. Walked across the plane, the same
      creature goes **out → IN → out**, purely by where it is standing.
- [x] It is decided by the HITBOX. The question is put to the physics
      engine as a thin slab laid ON the plane, so it is real colliders
      answering — a big creature counts the moment any part of it is on
      the line, with no special case for size.
- [x] Not flat, nothing is on his line — even a mob standing on top of
      him. He has no line to be on.
- [x] The slab is the same thickness as what he can SEE
      (STO-CHARACTER-081), so the rule and the picture agree: if it is
      in his world it is on his screen, and if it is on his screen it
      can touch him.
- [x] Proven by `tests/smoke_mage_warp_line.gd`.

## Built (2026-08-14)

`things_on_my_line()` and `is_on_my_line()`. What is NOT built is
anything acting on the answer — damage and attacks still ignore it, so
today it is a question the game can ask and does not yet use. The rule
is the hard part and it is done; wiring combat to it is a smaller job
that belongs with the combat stories.

## Out of scope

- Enemies knowing they are 2D or behaving differently.
- Other players being flattened by his plane.
