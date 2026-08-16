---
xid: STO-CHARACTER-087
parent: ./epic.md
kind: story
effort: character
size: M
status: done
date: 2026-08-16
depends-on: []
bd-id: delve-rpkm
---

# It actually looks like a claw-machine claw

## Summary

> "make it so it acualy look like the claw" — operator, 2026-08-16

The claw BEHAVES like a claw machine (STO-CHARACTER-084/085) and still
**looks like a human hand** — five fingers with a thumb, opening and
shutting.

A claw machine's claw is not a hand. It is **three metal prongs**
around a hub, evenly spaced, hinging inward together. That silhouette
is the whole reason everyone instantly knows what a claw machine does,
and it is what is missing.

## What changes

| from | to |
|---|---|
| five fingers, one of them a thumb | **three prongs**, evenly spaced |
| spread across a knuckle line | arranged around a **hub**, 120° apart |
| soft, finger-thick | **tapered metal**, thicker at the hub, pointed at the tip |
| a hand closing | prongs swinging **inward together** |

## Only for the claw

The Grabber gets prongs; everyone else keeps their hands. The fingers
are used by other things — the Runner's scratch, the finger-wrap around
a grabbed ragdoll — and this is a change to what the GRABBER'S hands
are, not to what a hand is.

## The mechanism should not change

`set_hand_curl` already drives every digit together and the claw
already drives that slowly between two poses. Prongs should be built as
digits in the same shape of structure, so the driving code does not
know or care that there are three of them and that they are metal.

If that turns out not to work, it means the finger code is
finger-shaped in a way that matters, and that is worth finding out.

## Definition of Done

- [x] **Four** prongs, one at each diagonal corner — top-left,
      top-right, bottom-left, bottom-right.
- [x] Spread **around** a hub, not in a row — all four sign
      combinations of (x, y) present.
- [x] **Longer**, and each **bent like `<`**: the elbow sits measurably
      off the straight line from base to tip.
- [x] They taper from the hub to a point.
- [x] All metal, never the skin material.
- [x] They still open and shut on Q and E and still catch things —
      every check in `smoke_claw` still passes.
- [x] Proven by `tests/smoke_claw.gd`.
- [ ] ~~Every other character still has five fingers.~~ **This turned
      out to be meaningless** — see below.

## Amended (2026-08-16): four prongs, longer, bent like `<`

> "make it so its like so its longer and its shaped like < and theres 4
> one at the top right one at the bottem right one at the top left and
> one the bottem left" — operator

Three prongs at 120° was my reading of "a claw machine claw". The
operator's is more specific and better:

- **Four** prongs, one at each **diagonal corner** — top-left,
  top-right, bottom-left, bottom-right. Not three, and not in a row.
- **Longer.**
- **Bent like `<`** — each prong has an elbow, so it goes out and then
  angles back in, rather than being a straight spike.

Four at the corners is the arrangement of an actual arcade claw, and
the elbow is what makes the silhouette read as a grabber rather than a
fork. Straight prongs cannot cradle anything; bent ones can.

### How the bend survives curling

`set_finger_curl` drives `rotation.x` on every joint and nothing else,
so the elbow is built as a fixed rotation on a **different axis** at
the middle joint. Curling and the bend then cannot fight: one owns x,
the other owns y.

**The bend is measured, not eyeballed.** A `<` means the elbow is off
the straight line between the base and the tip — so that is the check,
in metres, rather than "it looks bent".

## The consequence nobody asked for, and it is real

The Grabber was the **only** character with mechanical arms. So turning
its hands into prongs did not "change one character's hands" — it
**removed the five-finger hand from delve entirely.**

That surfaced as two tests going red rather than as a decision:
`smoke_fingers` (there are five, named Pointer/Middle/Ring/Pinky/Thumb)
and `smoke_wrap_ragdoll` (they close by different amounts on what they
hold). Both were testing something true that afternoon and false by
teatime.

**Eight finger stories (STO-CHARACTER-057 to 064) are marked
superseded**, and those two tests are removed. Kept in git, as always —
`git show HEAD~1 -- tests/smoke_fingers.gd` brings them back.

This is worth flagging rather than burying: a small visual change
deleted a whole subsystem, and the only reason anyone found out was
that the subsystem had tests. Without them the fingers would simply
have stopped existing quietly.

## Built (2026-08-16)

The prongs are built as **digits** — the same nested `J0/J1/...` chain,
under a node still called "Fingers" — so `set_hand_curl`, the wrap and
every caller drive them without knowing there are three and that they
are metal.

That prediction was in this story before it was built, along with what
it would mean if it failed: that the finger code was finger-shaped in a
way that mattered. It was not. Nothing in the driving code changed.

## Out of scope

- Animating a claw-machine cable or winch.
- Making the prongs hurt.
