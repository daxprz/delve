---
xid: EPI-CHARACTER-MAGE-FLATLANDER
parent: ../design.md
kind: epic
effort: player-character
status: open
date: 2026-08-14
bd-id: delve-i2mn
---

# The Mage, who steps into the second dimension

## Summary

A fifth character: a **mage with four arms** who can **step sideways
into the second dimension**. Press a key and he flattens onto a plane —
and from then on he is somewhere the rest of the game is not.

> "he should press e then turn 2d and every thing infron of him is the
> 2d plane hes on so hes able to slip through super small gaps or other
> things that would be imposble other wise from the out side it looks
> like he becomes 2d but for him it looks like a platformor and any
> enmys that get in that line is seen as a 2d enemy only when the hit
> box is in the line of the 2d world and hes able to se the backround
> but its faded out into a backround like art stlye"
> — operator, 2026-08-14

## The idea that makes this special

**Two people watching the same moment see two different games.**

- **You**, playing him, see a **platformer**. Side-on, flat, left and
  right and up. The world you were just walking around has become a
  level in an old flat game.
- **Everyone else** sees a man turn **paper-thin** and slide through a
  gap they cannot follow him into.

Nothing else in delve does that. Every other ability changes what you
*can do*; this one changes **what kind of game you are in** — and only
for you. That is worth building carefully, because it is the most
original thing in the project.

## How it works, in the operator's words

| | |
|---|---|
| **The key** | Press **F**. Press again to come back. |
| **The plane** | Everything **in front of him** is the 2D plane he is on. He picks it by where he is facing. |
| **What it is for** | Slipping through **super small gaps** and other things that would be impossible otherwise. |
| **From outside** | He looks like he has **become 2D** — flat. |
| **For him** | It looks like a **platformer**. |
| **Enemies** | An enemy is only a 2D enemy **while its hitbox is in the line** of his plane. Out of the line, it is not in his world at all. |
| **The background** | He can still see it, but **faded out, like background art**. |

That enemy rule is the sharp one. It means the danger changes as things
wander in and out of his plane — an enemy is not "in 2D" or "not in
2D" as a permanent state, it is in or out **at this instant, by where
its hitbox is**.

## Stories

| # | Slug | Size | Notes |
|---|------|------|-------|
| 074 | mage-character | M | **First.** He exists and you can pick him. |
| 075 | four-arms | M | Four procedural arms, not two. |
| 076 | flatten-to-plane | L | Press E, pick the plane, become flat. |
| 077 | slip-through-gaps | L | The point of it: go where nobody can follow. |
| 078 | platformer-view | L | His camera and controls become a flat game. |
| 079 | flat-from-outside | M | What everyone ELSE sees. |
| 080 | enemies-on-the-line | L | In your world only while their hitbox is on the plane. |
| 081 | faded-background | M | The world behind, as background art. |
| 082 | slow-warp | M | Reality warps slowly, and it is mesmerising. |

Built in that order: he has to exist before he can flatten, and he has
to flatten before there is anything to look at or slip through.

## Definition of Done

- [ ] The Mage is on the character select screen and can be played.
- [ ] He has four arms.
- [ ] Pressing F flattens him onto the plane he is facing; pressing it
      again brings him back.
- [ ] The change is a **slow, mesmerising warp**, never a snap.
- [ ] Flat, he fits through gaps that are impossible otherwise.
- [ ] Flat, his own view is a platformer.
- [ ] Flat, other players see a paper-thin man.
- [ ] An enemy counts as being in his 2D world **only** while its
      hitbox is on the plane.
- [ ] The rest of the world is still visible, faded, like background
      art.
- [ ] Every one of those proven by a headless test.

## The key, settled (operator, 2026-08-14)

**F.** The Mage flattens on F.

Raising the clash was worth it, because checking the bindings turned up
a **live bug of my own**: `rescue` had been added on **E**, which the
Grabber's arm-mode toggle already owned. A Grabber pressing E folded
its arms *and* started a rescue.

The operator settled both at once — **the Grabber's key is the one that
moves**:

| key | now |
|---|---|
| **E** | rescue (everyone) |
| **R** | the Grabber's arm-mode toggle |
| **F** | the Mage flattens |

F was already the Grabber's piston pull, and that is fine: the piston
is Grabber-only and the Mage will never have one, so no character is
ever asked to do both. Rescue is the one that had to be exclusive,
because **everybody** can rescue.

## Out of scope

- Other characters going 2D. It is the Mage's trick.
- The world being genuinely 2D for anybody else.
- A second, separate "warp reality" power. It turned out there is no
  such thing: **the warp IS the transition into 2D** (STO-CHARACTER-082).
  He has one power, not two.
