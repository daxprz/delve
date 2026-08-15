---
xid: STO-CHARACTER-074
parent: ./epic.md
kind: story
effort: player-character
size: M
status: done
date: 2026-08-14
depends-on: []
bd-id: delve-jvk1
---

# The Mage exists and you can pick him

## Summary

The Mage joins the roster as delve's **fifth** character, alongside the
Grabber, Runner, Flyer and Sniper. You pick him on the select screen
and play as him.

Confirmed by the operator: he is **a character you pick**, not an enemy
and not a boss.

This story is only that he EXISTS and is playable. No arms, no
flattening. It is deliberately the smallest possible first step,
because every other story in this epic needs somebody to happen to.

## Definition of Done

- [x] The Mage is the **fifth** entry in the character registry, so he
      appears on the select screen with everyone else.
- [x] You can pick him and spawn as him — verified by spawning one and
      asking it who it is.
- [x] He has his own colour, speed (4.6), jump (4.6) and health (75).
- [x] He was added as **DATA only**. Not one line of the player
      controller was changed to make him exist, which is what the
      registry is for.
- [x] He does not get the Grabber's mechanical arms.
- [x] Proven by `tests/smoke_mage.gd`.

## Built (2026-08-14)

Slower and squishier than the others — 4.6 m/s and 75 health, between
the Sniper's 65 and the Runner's 80. He is not meant to win a fight;
his power is going somewhere nobody can follow.

## Out of scope

- The four arms — STO-CHARACTER-075.
- Anything to do with the second dimension.
- Balancing him against the others. He can be tuned once he can be
  played.
