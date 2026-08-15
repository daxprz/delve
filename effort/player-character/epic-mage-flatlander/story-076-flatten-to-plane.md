---
xid: STO-CHARACTER-076
parent: ./epic.md
kind: story
effort: player-character
size: L
status: done
date: 2026-08-14
depends-on: []
bd-id: delve-nrrc
---

# Press E and he flattens onto the plane he is facing

## Summary

> "he should press e then turn 2d and every thing infron of him is the
> 2d plane hes on"
>
> "do f insted" — operator, 2026-08-14

Press **F** and the Mage steps sideways into the second dimension.
Press it again and he comes back.

The change from E is not cosmetic: see below.

## Which plane?

**Everything in front of him.** He chooses the plane by where he is
facing at the moment he presses the key — so aiming himself before he
flattens IS the skill. Face down a corridor and the corridor is your
world; face a wall and you have chosen a very small world indeed.

The plane is fixed once he is in it. It does not follow him round as
he turns, because a plane that re-chose itself every frame would not be
a place — it would just be a strange way of walking.

## The keys, settled (operator, 2026-08-14)

The Mage uses **F**.

Flagging the clash paid for itself immediately: checking the bindings
showed `rescue` had been put on **E**, which the Grabber's arm-mode
toggle already owned. That was a live bug — a Grabber pressing E folded
its arms *and* began a rescue — and nobody had noticed.

The operator's call was that **the Grabber's key is the one that
moves**, which is right: rescue is used by everyone and should keep the
obvious key, while an arm-mode toggle is Grabber-only.

| key | now |
|---|---|
| **R** | rescue — everybody |
| **E** | the Grabber's arm-mode toggle |
| **F** | the Mage flattens |

F is also the Grabber's piston pull, and that is deliberate rather than
sloppy: the piston is Grabber-only and the Mage will never have one, so
no character is ever asked to do both with one key. Only actions
**everyone** can perform need an exclusive key.

## Definition of Done

- [x] Pressing F turns the Mage 2D.
- [x] Pressing it again turns him back.
- [x] The plane is chosen from where he is FACING when he presses it —
      measured, the normal is square to his facing (dot **0.0000**).
- [x] It is upright: looking up or down at the moment of pressing
      cannot tilt the world he ends up in.
- [x] The plane stays put while he is in it. Turned **69°** and the
      normal and origin did not move.
- [x] He cannot walk off it: **0.0000 m** after 80 ticks walking
      straight at the normal.
- [x] **But he walks ALONG it perfectly well — 6.06 m.** This is the
      comparison that matters; without it, a Mage frozen solid would
      pass every other check here.
- [x] Shoved off the plane by something else, he is **put back** (3.00 m
      off → 0.0000 m).
- [x] He comes back where he actually is (**0.00 m** drift), which was
      **6.06 m** from where he went in.
- [x] Solid again, the forbidden direction works again (**1.52 m**).
- [x] Coming back inside solid rock is handled: he returns to the last
      spot he was seen to occupy safely.
- [x] Only the Mage can do it. A Runner asked to flatten refuses.
- [x] The key conflict is resolved, deliberately, and written down.
      Done 2026-08-14: rescue keeps E, the Grabber's toggle moved to R,
      the Mage takes F.
- [x] Proven by `tests/smoke_mage_flatten.gd`.

## Built (2026-08-14)

**Every movement path now goes through one `_move()`.** There are six
separate ones in `player.gd` — walking, zipping, rolling, flying, being
launched, the main path — and each slides and then returns immediately.
A rule that has to hold after *any* move has to be attached to the move
itself; hanging it off one path would leave the other five free to
break it, and the one that broke it would be whichever path the player
used first.

**Sabotage found a gap in my own test.** Disabling the position
correction alone changed nothing — walking is already covered by never
building the off-plane velocity in the first place, so the correction
had no test of its own. Added the case that needs it: something ELSE
shoves him off the plane, and he has to be put back. With both
mechanisms disabled the test fails by **6.06 m**, so it does have
teeth.

⚠️ **Not yet verified against the movement tests.** `smoke_player`,
`smoke_walljump`, `smoke_dodge`, `smoke_body_anim`, `smoke_flyer`,
`smoke_grab` and `smoke_punch` all need port 7777 and were skipped
because the game was open. They are the exact tests that would catch a
regression in the `_move()` rerouting. **Run them with the game closed
before trusting this.**

## Out of scope

- What it LOOKS like, inside or out — 078 and 079.
- Slipping through gaps — 077.
- Enemies — 080.
