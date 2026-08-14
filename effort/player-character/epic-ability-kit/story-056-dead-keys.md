---
xid: STO-CHARACTER-056
parent: ./epic.md
kind: story
effort: character
size: S
status: shipped
date: 2026-08-13
depends-on: []
bd-id: delve-ksq
shipped: 2026-08-13
tasks: 6
complete: 6
---

# C and G do nothing

## Summary

Pressing **C** or **G** has no effect. Both keys are dead.

**G** was the throw: press once to pick something up, again to hurl
it. RMB does that now, and better (STO-CHARACTER-055), so G was doing
a worse version of a job already taken.

**C** was three things at once — the Grabber's **block**, its
**parry**, and the Runner's **dodge roll**.

## What this costs, on purpose

The operator was told what removing C means and chose it anyway. It is
written down here because it is a real trade, not an oversight:

| enemy hits you | before | after |
|---|---|---|
| standing there | 12 damage | 12 damage |
| guarding (C held) | 3 damage | **no longer possible** |
| mid dodge-roll (C) | 0 damage | **no longer possible** |

Since STO-ENEMIES-011 enemies actually attack, so this removes **every
defence in the game**. The only way to avoid a hit now is to not be
standing there — walk out of range during the wind-up, which is what
the 0.55 s telegraph is for.

That may well turn out to be the more interesting game: it makes
positioning the whole defence rather than a button. But if fights feel
unfair, this story is the first thing to look at.

## Definition of Done

- [x] Pressing C does nothing at all.
- [x] Pressing G does nothing at all.
- [x] Nothing else on the keyboard changes behaviour (W still walks).
- [x] Tests that asserted blocking, parrying or dodge-rolling are
      updated to the new truth rather than left lying.
- [x] STO-ENEMIES-011 is annotated: its "blocking and dodge-rolling
      work against it" claim is no longer reachable by a player.
- [x] Proven by a headless test that presses the real keys (7 checks).

## Out of scope

- Deleting the block/parry/dodge code. It is only unhooked from the
  keyboard, so putting it back on a different key later is a one-line
  change rather than a rewrite. Recorded deliberately: the operator
  asked for the *keys* to do nothing, not for the abilities to be
  destroyed.

## Verification notes (2026-08-13)

`tests/smoke_dead_keys.gd`, 7 checks — pressing the **real keys**,
because "the code path is gone" and "the key does nothing" are
different claims and only the second was asked for. It checks both
characters that had something on C: the Grabber (block/parry) and the
Runner (dodge roll).

Two bugs in that test, both mine, both caught by running it:

- Damage was measured against an assumed 100 health, but `set_health`
  clamps to each character's maximum and the Runner's is lower — so a
  12-damage hit "lost 32". It reads the actual health now.
- The walk check reassigned its starting position every tick, so the
  distance was always 0.00 and "W still moves you" failed on a
  perfectly working keyboard.

`smoke_enemy_attack.gd`'s guard and dodge phases were replaced with
one that asserts a blow costs full damage even with C held.

## Notes

Asked for after the Grabber's pick-up moved to RMB, which made G
redundant. C went with it.
