---
xid: STO-CHARACTER-066
parent: ./epic.md
kind: story
effort: character
size: M
status: draft
date: 2026-08-14
depends-on: []
bd-id: delve-8nqr
---

# Claw scratches that get faster and harder the more you click

## Summary

The Runner scratches with its claws: **LMB** for one side, **RMB** for
the other. A single press is a light flick — **0.25 damage**. But the
faster you click, the faster it swings AND the harder each scratch
lands.

**Damage comes entirely from MOMENTUM** — how fast the Runner is
moving when the claw lands:

| moving | damage |
|---|---|
| standing still | **0.10** |
| walking (5.0) | **0.25** |
| sprinting (8.0) | **0.50** |
| dashing (21.0) | **1.00** |

Interpolated between those, not stepped, so every speed in between
gets its own honest value and there is no threshold to sit just above.

Clicking faster never makes a hit bigger — **moving** faster does. And
there is barely any shove, so a target stays where it is while you
shred it.

That is the whole shape of the weapon: your damage per second is
however fast you can press, but no single hit ever gets big. Very
different from the Grabber's heavy momentum punches or the Sniper's
one slow deliberate shot.

## Definition of Done

- [ ] LMB scratches with one claw, RMB with the other.
- [ ] One press on its own does **0.25** damage.
- [ ] Clicking faster makes it swing faster.
- [ ] Each scratch still does exactly **0.25** however fast you click
      — the damage never stacks or multiplies.
- [ ] Clicking faster changes the **effects** (how it looks and
      feels), not the damage.
- [ ] There is no minimum gap between clicks other than how fast you
      can press.
- [ ] Only the Runner has it.
- [ ] Proven by a headless test comparing slow clicking with fast
      clicking.

## Settled: what "the damage doesn't stack" means

Asked, and answered: **the damage per scratch is always 0.25.** It
never multiplies, never builds up, and there is no combo bonus.

Spamming gives you more damage *per second* purely because you land
more scratches — and it changes the **effects**, not the numbers.

Worth having asked. The earlier wording ("the more the player spams it
the more damage it does") reads as a damage multiplier, and building
that would have produced a completely different weapon: one where the
skill is maintaining a combo rather than simply clicking fast.

## Out of scope

- A separate claw model. The existing arms swing.
