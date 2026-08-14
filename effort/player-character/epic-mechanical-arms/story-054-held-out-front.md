---
xid: STO-CHARACTER-054
parent: ./epic.md
kind: story
effort: character
size: S
status: shipped
date: 2026-08-13
depends-on: []
bd-id: delve-6tk
shipped: 2026-08-13
tasks: 6
complete: 6
---

# A held thing is held out in front, not hugged to the player

## Summary

Grabbing still works the way it does — the change is **where the thing
you are holding sits**. It currently gets pulled in against the
player, low and close. It should be held **out in front**, up where
you can see it, so you can aim and throw it.

The carry point is the whole problem:

```gdscript
var pos := global_position + Vector3.UP * 0.3 + _aim_forward() * THROW_HOLD_DIST
```

`UP * 0.3` is barely above the player's feet, and `THROW_HOLD_DIST` is
1.6 m. So a held object hovers around knee height, tucked in — it
reads as being *pulled to you*, it blocks your view of where you are
aiming, and it gives you no sense of the line the throw will take.

The Grabber's arms carry a grabbed enemy at the same 1.6 m and have
the same problem.

## Definition of Done

- [x] A held object floats **out in front** — 2.40 m from the eye.
- [x] It is held at eye level (0.02 m off the eye line, against
      1.28 m below it before).
- [x] It follows where you look: looking up 35 degrees lifts it above
      the eye line.
- [x] Throwing still sends it where you are aiming.
- [x] A grabbed **enemy** is carried out in front the same way.
- [x] Proven by a headless test that measures where the object
      actually is, not what the constants say (9 checks).

## Verification notes (2026-08-13)

`tests/smoke_hold_out_front.gd`, 9 checks. Teeth-checked by restoring
the old carry point: **4 checks fail**, including "1.28 m below eye",
which is the operator's complaint stated as a number.

## Out of scope

- Throw force or range.
- What the arms do with a **loose crate** — STO-CHARACTER-053 settled
  that (it stays where it is), and this story does not touch it.

## Notes

The operator asked for this after playing. My first attempt at
STO-CHARACTER-053 guessed "held floating in front", was corrected to
"stays where it is", and that correction was right for the *arms*
grabbing a crate. This is a different mechanism — the carry point for
something you have picked **up** — and there, held-out-front is what
was wanted after all. Worth recording so the two do not look
contradictory later.
