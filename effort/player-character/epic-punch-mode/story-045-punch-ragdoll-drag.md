---
xid: STO-CHARACTER-045
parent: ./epic.md
kind: story
effort: character
size: S
status: removed
date: 2026-08-07
depends-on: []
bd-id: delve-0ar
shipped: 2026-08-07
tasks: 5
complete: 5
---

# Punches ragdoll enemies; grabbed enemies are dragged along

## ⛔ REMOVED from the Grabber (2026-08-16)

The Grabber was remastered into a claw-machine claw
(EPI-CHARACTER-GRABBER-CLAW) and every one of its abilities was taken
out at the operator's request — four abilities, four keys and seven
unfinished piston stories traded for one idea a child can describe in
a sentence.

**This story is kept, not deleted**, the way the Guardian and Builder
were. What it measured and the bugs it found outlive the feature.

## Summary

Two things the operator reported as not working, both caused by
numbers that were tuned before enemies had ragdolls at all.

**Punches never knocked anyone down.** The ram applied
`speed * 0.35` as knockback — about **1.75** at a run, while the enemy
ragdoll threshold is ~**7.5** of delivered dv. So a punch could not
even reliably stumble someone, let alone flatten them. Replaced with a
solid base hit plus a momentum bonus (`4.2 + 1.15/m/s`) and a slight
upward lift, so a slow ram staggers and a fast one flattens.

**A grabbed enemy didn't come with you.** Holding one reeled it with
the same 0.5 impulse used for the crate — but a limp enemy is ~60 kg
of jointed ragdoll parts, so it barely twitched. The held part is now
steered toward a carry point in front of the shoulder, hauling the
whole body along.

## Definition of Done

- [x] A landed punch ragdolls an enemy (and still damages it).
- [x] Punch strength scales with momentum: slow rams stagger, fast
      rams flatten.
- [x] A grabbed enemy is dragged along as the player moves.
- [x] The dragged body stays close rather than trailing far behind.
- [x] `tests/smoke_grabber_grapple.gd` covers both (16 checks,
      non-hosted).

## Out of scope

- Punch knockback for the movable crate (it already gets shoved).
- Aiming where a held enemy is carried (fixed point in front).

## Verification notes (2026-08-07)

- Punch: enemy ragdolled and took damage (60 → 47 hp) from a 6 m/s
  ram.
- Drag: the held enemy moved 6.5 m while the player moved 7.2 m,
  staying 2.1 m away throughout.
- Both numbers were originally tuned when enemies just slid on their
  feet; the ragdoll work (STO-ENEMIES-004/006) raised what it takes to
  move an enemy by roughly an order of magnitude and these two call
  sites were never revisited. Worth checking any other tuned impulse
  against the current thresholds.
- Hosting-based arm tests still queued: port 7777 held by the
  operator's play session.
