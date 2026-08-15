---
xid: STO-CHARACTER-078
parent: ./epic.md
kind: story
effort: player-character
size: L
status: done
date: 2026-08-14
depends-on: []
bd-id: delve-he52
---

# His own view becomes a platformer

## Summary

> "for him it looks like a platformor"
>
> "make the camra smothly glide to the side of the cheracher so it
> looks like a platformer and make it so when the player aims the camra
> some where else with the mouse nothing is effected in the 2d mode and
> make it so everything turns into a 2d plane like terraria and other
> 2d games" — operator, 2026-08-14

Flat, **his own view becomes a flat game**. The camera swings side-on
to his plane and he moves along it — left, right and up — the way an
old 2D platformer works.

## The three things the operator asked for, precisely

**1. It GLIDES.** The camera does not cut to the side view, it travels
there smoothly. This is the same instinct as the slow warp
(STO-CHARACTER-082) and for the same reason: the moment of changing
dimension should be something you watch, not something that has already
happened.

**2. The mouse does NOTHING while flat.** Not "the camera is
constrained" — *nothing is affected*. Aim wherever you like; the view
does not budge. In a 2D game the camera is not yours to point, and a
view that fought your mouse would feel broken rather than deliberate.

**3. Everything reads as flat, like Terraria.** Not just him — the
whole scene. That is the difference between "a 3D game with a locked
camera" and "a 2D game".

## How the world is made to look flat

Perspective is what makes a 3D scene look 3D: near things loom, far
things shrink, and parallel lines converge. Take that away and a 3D
scene reads as flat — which is exactly what Terraria and every other
side-on game look like.

So the camera pulls **back** and **narrows** as it glides, and the two
together converge on a nearly parallel projection. It is one continuous
movement with no switch and no pop, which is what lets requirement 1
and requirement 3 be the same motion rather than two effects fighting
each other.

This is the half of the trick only he sees, and it is the reason the
power feels like magic rather than like a squeeze through a gap. For a
few seconds he is not playing the same game as everybody else.

## Definition of Done

- [x] Flat, the camera ends up **11.05 m** out and **100% along the
      plane normal** — square-on to his plane, not merely behind him.
- [x] It **glides**. Caught halfway it was **47% of the way**, and
      genuinely between the two ends rather than at either.
- [x] The mouse does **nothing at all**. Shoved 20 times while flat:
      the camera moved **0.0000 m** and he turned **0.0000 rad**.
- [x] The view narrows **75° → 11°**, which with the distance is very
      nearly a parallel projection — so the whole world reads flat, not
      like a 3D scene from the side.
- [x] Coming back it glides home too (caught mid-way returning) and
      lands **0.162 m** from where it started, at its normal 75°.
- [x] Nobody else's view changes — the Sniper's echo vision, the
      Sniper's rifle, the mouse lock and the pause menu all still pass.
- [x] Proven by `tests/smoke_mage_camera.gd`, sampled mid-glide.

## Built (2026-08-14)

Doing it by **narrowing the view while pulling back** rather than
switching the camera to orthographic keeps it one continuous movement:
no mode change, so nothing pops, and requirements 1 and 3 become the
same motion instead of two effects fighting each other.

One bug caught before it shipped: the first version wrote the camera's
transform on **every** frame, which would have stamped on the mouse the
instant it moved — breaking first person for **every character**
because of a feature only the Mage has. It now writes it once, on
arrival home.

- [ ] Movement is not remapped. He still walks with W/S along the
      plane, which reads as left/right on screen because the camera is
      side-on — but A/D are simply blocked rather than being turned
      into left/right. **Not ticked.**

## Out of scope

- Platformer-specific abilities. He moves; he does not gain a
  double-jump for being flat.
- Changing anyone else's camera.
