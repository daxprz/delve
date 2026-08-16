---
xid: STO-CHARACTER-070
parent: ./epic.md
kind: story
effort: character
size: S
status: removed
date: 2026-08-14
depends-on: []
bd-id: delve-pg4o
---

# The two hands combine to form the piston

## ⛔ REMOVED from the Grabber (2026-08-16)

The Grabber was remastered into a claw-machine claw
(EPI-CHARACTER-GRABBER-CLAW) and every one of its abilities was taken
out at the operator's request — four abilities, four keys and seven
unfinished piston stories traded for one idea a child can describe in
a sentence.

**This story is kept, not deleted**, the way the Guardian and Builder
were. What it measured and the bugs it found outlive the feature.

## Summary

In piston mode the Grabber's two arms are drawn **together** — both
hands meet at one point in front of the chest and lock into a single
shaft.

Before this the piston simply **appeared out of thin air** while the
two arms carried on dangling separately at the player\'s sides. The
mode was correct, the shape was not.

## Definition of Done

- [x] Both hands are pulled to the same point in piston mode.
- [x] Measured: **0.560 m apart in grab mode, 0.041 m in piston mode**.
- [x] The elbows come in too, so the arms do not meet at the hands
      while bowing out in the middle.
- [x] Grab and punch modes are unchanged.

## It also LOOKS like a piston now (STO-CHARACTER-071)

It was a box that grew. It is three parts with three behaviours:

```
[====housing====]---------rod---------[HEAD]
 dark barrel,     bright, thin,        wide
 fixed length     the only part        flat
 never moves      that extends         face
```

That split is what makes it read as a piston rather than a stretching
block: a real piston has a rod sliding OUT of a fixed barrel.

Godot builds cylinders along **Y** while the shaft runs along **+Z**,
so every piece is turned a quarter turn about X — get that wrong and
you have a piston lying on its side.

## Verification notes (2026-08-14)

The elbow matters more than it sounds. Pulling only the hands together
left the arms meeting at the fingertips while their middles still
bowed out to the sides — two arms touching, not one shaft. The elbow
is drawn halfway along the same line at a gentler rate.

Asserted both ways round in `smoke_piston.gd`: apart in grab mode,
together in piston mode. Checking only the second would pass on arms
that were always joined.
