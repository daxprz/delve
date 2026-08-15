---
xid: STO-CHARACTER-076
parent: ./epic.md
kind: story
effort: player-character
size: L
status: draft
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
| **E** | rescue — everybody |
| **R** | the Grabber's arm-mode toggle |
| **F** | the Mage flattens |

F is also the Grabber's piston pull, and that is deliberate rather than
sloppy: the piston is Grabber-only and the Mage will never have one, so
no character is ever asked to do both with one key. Only actions
**everyone** can perform need an exclusive key.

## Definition of Done

- [ ] Pressing F turns the Mage 2D.
- [ ] Pressing it again turns him back.
- [ ] The plane is chosen from where he is FACING when he presses it.
- [ ] The plane stays put while he is in it — turning does not move it.
- [ ] He comes back where he actually is, not where he started.
- [ ] Coming back inside solid rock is handled and does not trap him.
- [ ] Only the Mage can do it.
- [x] The key conflict is resolved, deliberately, and written down.
      Done 2026-08-14: rescue keeps E, the Grabber's toggle moved to R,
      the Mage takes F.
- [ ] Proven by a headless test.

## Out of scope

- What it LOOKS like, inside or out — 078 and 079.
- Slipping through gaps — 077.
- Enemies — 080.
