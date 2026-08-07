---
xid: STO-CHARACTER-050
parent: ./epic.md
kind: story
effort: character
size: L
status: shipped
date: 2026-08-07
depends-on: []
bd-id: delve-3ri
shipped: 2026-08-07
tasks: 7
complete: 7
---

# Echo memory: long-lived lidar, sound colours, gaussian spread

## Summary

A rework of what the Sniper actually sees, to the operator's spec.

**Two kinds of mark, told apart by colour.** LIDAR readings are
**white**, fading white → grey → black. SOUND is **red**, fading
red → grey-red → black-red. So the remembered map and live movement
never look alike.

**Lidar is memory now, not a glimpse.** Marks last **5 minutes**, and
the sweep fires **4x the rays** (600). A fresh hit **replaces** older
lidar marks within 35 cm of it, so re-scanning a room refreshes the
picture instead of stacking thousands of dots. Rays are spread
**gaussian** about the aim, so the middle of your attention is drawn
in far more detail than the edge of the cone.

**Other players' actions are audible.** A new `Sounds` autoload is a
broadcast bus: gunshots, punches, pounces and bodies hitting the floor
report to it, and it RPCs to every peer — so a Sniper hears what its
friends are doing on another machine. Movement already replicated via
position sync, but an action is an event; without this the Sniper was
deaf to everything anyone did.

The expanding wave is kept: a mark stays dark until the wavefront
reaches it, then fades with age.

## Definition of Done

- [x] Lidar marks last 5 minutes; sound marks fade far sooner.
- [x] Lidar fades white → grey → black; sound red → grey-red →
      black-red.
- [x] 4x lidar rays.
- [x] A fresh sweep replaces stale marks near each hit.
- [x] Gaussian spread about the aim, not uniform.
- [x] Actions anywhere — including other players' — are heard.
- [x] `tests/smoke_echo_vision.gd` passes (16 checks).

## Out of scope

- Replicating enemy ragdoll impacts as sounds from remote machines
  (the knockdown is reported, the tumbling is not).

## Verification notes (2026-08-07)

- A sweep now leaves **295 marks** where the old one left a few dozen,
  with **213 of 281** clustered centrally — the gaussian bias is real
  and measured, not assumed.
- Re-scanning went 295 → 426 rather than 590, so replacement is
  working; without it the count would double each sweep.
- Colour ramps asserted at both ends and the middle of each curve.
- An action fired 8 m away produced 44 sound marks without disturbing
  the lidar map.
- **Two mistakes worth recording.** First, this rework initially
  DELETED the expanding-wave sweep the operator had asked for
  earlier; it was restored as an arrival delay per mark. Second, a
  regex edit mangled the old test's phase machine — the two stale
  wave-model tests were replaced with one written for the new model
  rather than patched further.
