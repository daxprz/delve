---
xid: STO-CHARACTER-086
parent: ./epic.md
kind: story
effort: character
size: M
status: done
date: 2026-08-16
depends-on: []
bd-id: delve-nlqd
---

# The hands do nothing at all, ready to be rewritten

## Summary

> "get rid of anything the hands can do we will rewrite all of this"
> — operator, 2026-08-16

The arms stay. Everything the **hands** do stops.

STO-CHARACTER-083 emptied the Grabber's ability list, but the hands
kept their own behaviour underneath it: the mouse buttons still grabbed
and released, and E still cycled arm modes. This turns all of that off,
so the claw is written onto a blank page instead of on top of a system
that already thinks it knows what a hand is for.

## What stops

Everything routed through `_update_grab_input()` in
`mechanical_arms.gd`:

| stops | was |
|---|---|
| **left mouse** | left hand grabs where you aim (STO-CHARACTER-003) |
| **right mouse** | right hand grabs, and picks things up (055) |
| **E** | cycles grab / punch / piston mode (007, 069) |
| holding, releasing, dragging | everything downstream of a grab |

## What stays, deliberately

- **The arms themselves** — two procedural chains that hang, ragdoll
  and drag behind you (STO-CHARACTER-001, 002).
- **The fingers** — five per hand, two joints each. The claw is going
  to be made of them.
- **Collision** — the arms still clip against the world
  (STO-CHARACTER-011).

So the Grabber still LOOKS exactly right. It simply cannot do anything
with its hands, which is the honest state to rewrite from.

## Off, not deleted

The grab machinery is switched off behind one gate rather than torn
out. Two reasons:

1. The claw will want most of it back — `grab_body`, `release`, the
   finger wrap. Deleting it would mean writing it again worse.
2. A gate is one line to reverse if this turns out to be the wrong
   idea. Ripping out 1500 lines is not.

**This is not the same as keeping dead code.** The gate is the feature:
the hands are meant to do nothing right now.

## Definition of Done

- [x] Pressing the mouse buttons does nothing to the hands.
- [x] Pressing E does nothing to the hands.
- [x] Nothing is grabbed, held or released — measured **0 things held**
      after mashing both mouse buttons and E for 70 ticks.
- [x] The arms still exist, hang and collide — `smoke_arm_rest` and
      `smoke_arm_solid` still pass.
- [x] The fingers still exist — `smoke_fingers` still passes.
- [x] The Runner's claws still work — `smoke_runner_claws` passes.
- [x] Proven by `tests/smoke_grabber_stripped.gd`.

## Built (2026-08-16)

One gate at the top of `_update_grab_input()`, which is where every
hand behaviour was routed. `hands_can_act := false`.

### The grab tests cannot see this, and that is worth knowing

`smoke_grab` and `smoke_rmb_pickup` both still pass — because neither
presses a button. They call `arms.grab(0, target)` and
`arms.grab_body(1, box, ...)` **directly**, so they test that the
grabbing machinery works and never that a player can reach it.

That is the third test in this project found doing it: `smoke_abilities`
calls `do_throw()` and `do_zip()` the same way. All three would pass
with every control in the game disconnected.

It is not wrong for them to exist — the machinery does need testing,
and the claw is about to reuse it. But **nothing was checking that a
key press reaches the hands** until this story added it, and a whole
character's controls could have been dead for weeks without a red
test.

## Out of scope

- Deleting the grab code. It is switched off; the claw will reuse it.
- Removing the arms or the fingers.
