---
xid: STO-CHARACTER-053
parent: ./epic.md
kind: story
effort: character
size: S
status: shipped
date: 2026-08-07
depends-on: []
bd-id: delve-lsc
shipped: 2026-08-13
tasks: 8
complete: 7
---

# A grabbed crate stays where it is instead of being reeled in

> **SUPERSEDED by STO-CHARACTER-055 (2026-08-13).** The operator
> played this and asked for the crate to be picked **up** and held
> **out in front** instead of staying put. What shipped here was
> correct for what was asked at the time, and the reasoning below is
> still why a grabbed crate must never be *reeled into the player* —
> which remains true in 055. Only the "stays put" outcome is replaced.

## Summary

When the Grabber's arm latches onto a loose object — a crate — the
object should **stay exactly where it is**. The arm stretches out to
reach it, and the crate launches from there when you throw. It should
not come to you at all.

Right now it does the opposite. Every tick, a grabbed crate gets an
impulse fired at it aimed at the shoulder:

```gdscript
var to_hand := shoulder - bpos
if to_hand.length() > 0.6:
        body.apply_central_impulse(to_hand.normalized() * REEL_IMPULSE)
```

So the crate accelerates at you, overshoots, bounces off you and gets
yanked back — it never settles. Whatever speed it happens to carry
when you let go is added to the throw, so the same throw lands
somewhere different every time. That is what makes aiming hard.

```
NOW:                     AFTER:

  P  <~~[X]                P ~~~~~~~~ [X]
  crate flies at you       crate stays put,
                           arm stretches to it

                              throw --> [X] ---->
```

## Definition of Done

- [x] A grabbed crate does not move toward the player at all — no
      force is applied to it whatsoever.
- [x] It stays where it was grabbed (moved 0.16 m over 2 s of holding,
      which is just it settling on the floor).
- [x] The arm reaches out to it rather than dragging it in.
- [x] It does not shove the player around while held.
- [x] Carrying a **limp enemy** is unchanged — a separate path, left
      alone.
- [x] Grabbing a **wall** still pulls the player toward it
      (STO-CHARACTER-044) — untouched.
- [x] Proven by a headless test.
- [ ] The operator plays it and agrees throwing is easier.

## Out of scope

- Changing throw force or range.
- Holding more than one object per arm.

## Verification notes (2026-08-07)

`tests/smoke_grab_box.gd` — **inverted**, not newly written. It used to
assert the opposite ("grabbing the box reeled it toward the hand"),
because that was the requirement until the operator changed it. That
is a spec change, not a test bent to hide a defect, so the old
assertion is gone and the file says why.

Teeth checked by putting the reel impulse back: the crate was dragged
from 2.65 m to 1.23 m and drifted 2.96 m from where it was grabbed —
both checks caught it.

The fix is a **deletion**. No holding force replaced the reeling one;
applying nothing at all is exactly what makes a throw repeatable.
`REEL_IMPULSE` is gone with it.

The last box is left unticked on purpose — "easier to throw" is
something only playing can confirm.

## Notes

Reported by the operator from playing. My first write-up of this story
guessed "held floating in front of you" and was **wrong** — the
operator corrected it to "stays where it is". Recorded because it is
exactly why the read-back step exists: the wrong version would have
been built and it would have looked reasonable.

## Status notes

- 2026-08-13: Closed with --force; 1/8 DoD boxes unchecked. Reason: Superseded by STO-CHARACTER-055; shipped and then replaced after play-testing
