---
xid: STO-CHARACTER-036
parent: ./epic.md
kind: story
effort: character
size: S
status: shipped
date: 2026-08-07
depends-on: []
bd-id: delve-p7k
shipped: 2026-08-07
tasks: 4
complete: 4
---

# Fix: Runner could not jump at all during the pounce cooldown

## Summary

**Bug:** for the 15 seconds after a missed pounce, the Runner could
not jump **at all**.

**Cause:** the pounce block owns Space for pounce characters. Its
charge branch is gated on `_pounce_cd <= 0.0`, so during the cooldown
it was skipped; `_pounce_charge` was therefore 0, so the release
branch was skipped too; and the ordinary ground jump below was
suppressed for any character with `pounce` (`if not _can_pounce`).
Result: Space did nothing on the ground for 15 s. Introduced by
STO-CHARACTER-033 and not caught because the cooldown test only
asserted that CHARGING was blocked — it never checked that jumping
still worked.

**Fix:** the ordinary ground jump now also applies to pounce
characters whose pounce is recharging (`not _can_pounce or
_pounce_cd > 0.0`). With nothing to charge there is no reason to wait
for release, so the jump fires instantly on press.

Behaviour now:
- pounce READY → hold to charge, tap to jump (jump on release)
- pounce RECHARGING → Space is an ordinary, instant jump
- air jumps (wall-jump) unaffected in both cases

## Definition of Done

- [x] Tapping Space with the pounce ready still jumps.
- [x] With the pounce on cooldown, Space jumps instantly on press —
      no waiting for release, no crouch, not a pounce.
- [x] The cooldown keeps ticking; jumping neither clears nor extends
      it.
- [x] `tests/smoke_runner_jump.gd` passes; pounce tests still pass.

## Out of scope

- Rebinding the pounce to its own key so a tap-jump is instant even
  when the pounce is ready (worth considering if the ~0.1 s
  tap-to-release delay feels sluggish in play).

## Verification notes (2026-08-07)

- 8/8 PASS: ready-tap rises 1.48 m; cooldown press leaves the ground
  within 4 ticks while STILL HELD and reaches 1.28 m; cooldown ticks
  12.0 → 11.7 s across the jump.
- Test lesson: the first version asserted `velocity.y > 0` from the
  SceneTree tick and read 0.00 even when the jump worked — the main
  loop's tick runs before the node's, and a 1-tick tap is not a
  realistic press. Rewritten to measure actual height gained, which
  is what the player experiences.
- smoke_walljump / smoke_dodge unrun: port 7777 held by the
  operator's play session.
