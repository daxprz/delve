---
xid: STO-CHARACTER-057
parent: ./epic.md
kind: story
effort: character
size: M
status: draft
date: 2026-08-13
depends-on: []
bd-id: delve-a86
---

# Five procedural fingers, two joints each

## Summary

Each of the Grabber's hands grows **five fingers**, and each finger
has **two joints** — so a finger is a chain of segments that can
curl, not a rigid stick.

Laid out like a human hand, named as such:

| finger | where it sits |
|---|---|
| **pointer** | first of the four, nearest the thumb |
| **middle** | next along |
| **ring** | next along |
| **pinky** | last, on the outside edge |
| **thumb** | apart from the other four, opposing them |

**All five are the same length.** That is the one deliberate
difference from a real hand, where the middle finger is longest — the
operator asked for equal lengths, so the hand reads as *mechanical*
rather than as a copy of a human one. It suits the Grabber: these are
built arms, not grown ones.

The thumb sits apart and opposes the rest, so the hand can actually
close **on** something instead of flapping four fingers at it.

Generated in code from the hand's size, the way every other part of
delve is built: no modelled mesh, no keyframes.

This story only *builds* them and lets them curl. Wrapping, clenching
and joint limits are the three stories that follow, and none of them
can start until fingers exist.

## Definition of Done

- [x] Each hand has exactly 5 fingers, named pointer, middle, ring,
      pinky and thumb.
- [x] Each finger has 2 joints (3 segments).
- [x] **All five are the same length** — measured 0.300 to 0.300.
- [x] Built in code, scaling with `arm_scale`.
- [x] The thumb sits back along the palm and is turned 72 degrees to
      oppose the other four.
- [x] `set_finger_curl(finger, t)` / `set_hand_curl(arm, t)`, 0 to 1.
- [x] Both hands have them.
- [x] Proven by a headless test (22 checks).

## Verification notes (2026-08-13)

`tests/smoke_fingers.gd`, 22 checks.

A finger is a **nested** chain — `J0 -> End -> J1 -> End -> J2` — so
curling is just rotating the joint nodes and everything past a joint
comes with it, exactly as a real finger does. The alternative, placing
each segment by hand every frame, would have needed the maths this
gets for free.

The base knuckle bends less than the two joints past it (1.05 against
1.35/1.30 originally). A finger whose joints all bend equally curls
into a **hoop** rather than a fist.

## Out of scope

- What makes them curl — that is 058/059/060.
