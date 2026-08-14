---
xid: STO-CHARACTER-054
parent: ./epic.md
kind: story
effort: character
size: S
status: draft
date: 2026-08-13
depends-on: []
bd-id: delve-6tk
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

- [ ] A held object floats **out in front** of the player, clearly
      away from the body.
- [ ] It is held at around eye level, not knee level.
- [ ] It follows where you look, including up and down.
- [ ] Throwing still sends it where you are aiming.
- [ ] A grabbed **enemy** is carried out in front the same way.
- [ ] Proven by a headless test that measures the distance and height
      rather than trusting the constants.

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
