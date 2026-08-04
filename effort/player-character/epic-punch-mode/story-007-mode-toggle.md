---
xid: STO-CHARACTER-007
parent: ./epic.md
kind: story
effort: character
size: M
status: shipped
date: 2026-08-03
depends-on: []
bd-id: delve-9xo
tasks: 3
complete: 3
---

# Press E to switch grab-mode / punch-mode (no grabbing while punching)

## Summary

Press **E** to switch the Grabber's arms between **grab mode** and
**punch mode**. In punch mode the hands can't grab onto anything;
switching to punch mode also lets go of anything currently held.

## Definition of Done

- [x] E toggles grab-mode / punch-mode.
- [x] In punch mode, clicking does not grab.
- [x] Entering punch mode releases any active grab/grapple.

## Verification notes (2026-08-03)

- New input action `toggle_arm_mode` bound to **E** (project.godot).
- `mechanical_arms.gd`: `_punch_mode` flag; `set_punch_mode()` /
  `toggle_mode()` / `is_punch_mode()`. `_update_grab_input` branches on
  the mode — punch mode routes a click to `punch()` and never grabs.
  Entering punch mode clears all grabs and the player's grapple.
- `tests/smoke_punch.gd`: **RESULT: PASS** — starts in grab mode, E
  switches to punch and drops the grab, E toggles back.

### Change 2026-08-03 — obvious-but-subtle switch + held guard

Operator wanted switching modes to be **noticeable but not too loud**,
and the fists to **stay held out** in punch mode (not just jab briefly).

- [x] Switching to punch mode gives the fists a **warm orange glow**
      (subtle emission); grab mode returns them to plain metal
      (`_update_fist_look` in `mechanical_arms.gd`).
- [x] In punch mode the fists are **held out** in a ready guard in
      front of the player (`_guard_point` + a soft pull in
      `_simulate_arm`), instead of dangling; a punch jabs from that
      guard and returns to it.
- `tests/smoke_punch.gd` still **RESULT: PASS** (guard/look don't break
  the punch).

## Out of scope

- A HUD showing the current mode (nice-to-have later).
