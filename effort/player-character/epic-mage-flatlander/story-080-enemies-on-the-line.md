---
xid: STO-CHARACTER-080
parent: ./epic.md
kind: story
effort: player-character
size: L
status: draft
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

- [ ] An enemy whose hitbox intersects the plane is in the Mage's 2D
      world.
- [ ] An enemy whose hitbox does not is NOT — he cannot hit it and it
      cannot hit him.
- [ ] It updates continuously as things move. An enemy that walks
      across the plane is in, then out.
- [ ] It is decided by the HITBOX, not by the enemy's centre — a big
      creature counts the moment any of it is on the line.
- [ ] Proven by a headless test that walks an enemy across the plane
      and checks it goes out -> in -> out.

## Out of scope

- Enemies knowing they are 2D or behaving differently.
- Other players being flattened by his plane.
