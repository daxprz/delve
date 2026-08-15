---
xid: STO-ENEMIES-049
parent: ./epic.md
kind: story
effort: enemies
size: M
status: draft
date: 2026-08-14
depends-on: [STO-ENEMIES-034]
bd-id: delve-eib5
---

# The screen tells you what is happening to you

## Summary

> "making the screen dimmer while it drags you across the ground you can
> look around ... then it puts you on a stick making your games screen
> turn red and you can still kinda see" — operator, 2026-08-14

Being taken happens in three stages, and **the screen looks different in
each one**, so you always know which stage you are in without being told
in words.

| Stage | What the screen does | What it means |
|---|---|---|
| Grabbed and smashed down | a hard jolt | it has you |
| Dragged along the ground | goes **dimmer** | you are going out |
| Impaled on the spike | turns **red** | you are bleeding |

## The two rules that matter

**1. You can always still see.** The operator said it twice — "you can
look around" while dragged, and "you can still kinda see" on the spike.
Neither effect is allowed to black the screen out. A screen you cannot
see through is the same as not being in the game, and the entire point
of this epic is that you are **alive and watching**: watching it walk
away, watching the door, watching to see if anyone is coming for you.

So: dim, not dark. Red, not blind.

**2. The red means bleeding, so the red is a gauge.** Once the bleeding
game exists (STO-ENEMIES-050), the redness follows how fast you are
bleeding. Doing well at the timing game and the red eases off; fighting
and thrashing and it deepens. That way you can read your own condition
from the colour without a single number on screen — and when it gets
bad, the room gets hard to see, which is a punishment that hurts without
ever taking control away.

## Definition of Done

- [ ] Grabbed: a visible jolt when it smashes you into the ground.
- [ ] Dragged: the screen dims, and you can still make out the room and
      turn to look around.
- [ ] Impaled: the screen goes red, and you can still make out the room.
- [ ] Nothing ever fades to full black or full red.
- [ ] The red tracks the bleed rate once STO-ENEMIES-050 exists.
- [ ] It clears completely when you are rescued.
- [ ] It clears completely when you die and respawn — no red left over
      on a fresh life.
- [ ] Proven by a headless test reading the effect's actual strength at
      each stage, including that it returns to zero after rescue.

## Out of scope

- Sound. Worth having, but it is not this story and I cannot test it.
- A health bar or numbers on screen. The colour is the gauge.
- Effects for anything other than being taken.
