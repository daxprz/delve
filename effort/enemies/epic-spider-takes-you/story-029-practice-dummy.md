---
xid: STO-ENEMIES-029
parent: ./epic.md
kind: story
effort: enemies
size: M
status: done
date: 2026-08-14
depends-on: []
bd-id: delve-r4kn
---

# A practice dummy that stands in for a second player

## Summary

A body standing in the world that **counts as a player** for everything
that matters, but never moves and never fights back.

You can hit it, enemies will go for it, and — once the rest of this
epic lands — the spider can grab it, spike it, and you can rescue it.
All of that with one person at the keyboard.

It **just stands there** (operator's call). No walking, no following,
no shouting. Every rescue story in this epic can be tested against a
thing that only needs to be *present* and *hurtable*, so anything more
is work that buys nothing yet.

## Why this is story 001 and not story 008

Every other story in this epic ends with "...and then someone rescues
you". Alone, there is nobody to be rescued and nobody to do the
rescuing. Without the dummy, the other seven stories can be *built* and
none of them can be *tried* — and something you cannot try is something
you cannot know is finished.

## The one design decision that matters

The dummy joins the **same group as real players**. It is not a special
kind of thing that enemies have been taught to also attack.

That means everything that already works on a player works on the dummy
for free — enemy targeting, damage routing, grabbing, and every rescue
mechanic still to be written. If instead it were its own kind of
object, every one of the seven stories after this would need doing
twice: once for players and once for dummies. They would drift, and the
dummy would slowly stop being a fair test of the real thing.

The risk of that choice is the honest one to state: **anything that
counts players now counts one more.** That is exactly what the full
suite is for, and it is checked below.

## Definition of Done

- [x] A dummy stands in the world where you can find it.
- [x] It has health, takes damage, and reports it.
- [x] Enemies attack it like they attack a player.
- [x] It never moves on its own.
- [x] It survives being knocked about — no crash, no falling out of
      the world.
- [x] Killing it does not end anything; it comes back so you can carry
      on practising.
- [x] It looks like a person, not a box.
- [x] Proven by a headless test.
- [x] The full suite still passes — nothing that counts players broke.

## What it took (2026-08-14)

Two bugs, and the second one is the interesting one.

### The dummy revived at the world origin

It recorded its home position in `_ready()` — which runs the moment it
enters the tree, **before** whoever spawned it has applied the spawn
point. So home was always `(0,0,0)`, and knocking it down teleported it
**5.00 m** across the map to a spot it had never stood in.

The test passed anyway. It checked that the dummy came back with
health, and never checked *where*. Health is not position, and proving
one says nothing about the other. Home is now recorded on the first
physics tick, and the test asserts the position too — sabotaging the
fix reproduces the 5.00 m jump exactly.

### Adding a player broke two unrelated tests

Exactly the risk written down above: **anything that counts players now
counts one more.**

- `smoke_crawler` made the spider stand still by emptying `Players/`.
  The dummy lives in `Dummies/`, so it survived, and the spider kept
  walking toward it. Fixed by clearing the *group* rather than one
  container — the test's method was wrong, not its assertion.
- `smoke_grab_box` measured the held crate at **1.00 m** from the
  shoulder against a `> 1.0` threshold.

The second one deserved real investigation rather than a nudged number,
so it got four runs:

| World | Crate distance |
|---|---|
| no dummy | 1.66 m |
| dummy present, no collider | 1.66 m |
| dummy solid, outside the players group | 1.51 m |
| dummy solid, inside the players group | **1.00 m** |

**Distance to the dummy changed nothing** — 12 m away gave the same
1.00 m. So this is physics ordering, not the dummy pulling anything.
The crate is steered toward a point 2.4 m out while the arm reaches
about 2.0, so where it settles is an *equilibrium*, and the old
threshold sat inside its natural band.

Fixed by asserting what actually distinguishes the bug. When that bug
was real the crate ended up **at the shoulder** — near zero, and behind
the hands. The test now requires it to be out in **front** (a direction
check, which the old test never made) and merely not at the shoulder.
Stronger where it matters, unbrittle where it did not.

Full suite: **pass=50 fail=0**, 24 skipped for the port.

## Out of scope

- Walking, following, or fighting back.
- Being controlled by AI in any way.
- Anything to do with spikes or rescue — those are later stories that
  will use this one.
