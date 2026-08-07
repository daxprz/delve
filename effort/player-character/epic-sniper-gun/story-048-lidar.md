---
xid: STO-CHARACTER-048
parent: ./epic.md
kind: story
effort: character
size: M
status: shipped
date: 2026-08-07
depends-on: []
bd-id: delve-5tn
shipped: 2026-08-07
tasks: 7
complete: 7
---

# RMB lidar scan: paints the room ahead, then fades

## Summary

**RMB is a lidar.** It sweeps a cone of ~150 rays in the direction
you're looking, painting every surface it strikes — and unlike a
footstep's ripple, those points **hold for about 3 seconds before
fading**, so a scan gives the Sniper a steady picture of what's ahead
instead of a glimpse.

It completes the Sniper's toolkit as a set of trade-offs:

| | sees | costs |
|---|---|---|
| footsteps | whatever moves, briefly | nothing, but you can't choose it |
| **lidar (RMB)** | **only ahead, but it stays** | 2.2 s cooldown |
| rifle (LMB) | the whole room at once | tells everything where you are |

The lidar is the quiet option: narrow and directional, but it doesn't
shout your position across the map the way the gunshot does.

## Definition of Done

- [x] RMB sweeps a lidar cone in the aim direction.
- [x] The sweep travels outward rather than appearing instantly.
- [x] Painted points HOLD for a few seconds, then fade away.
- [x] It is directional: it shows what's ahead, nothing behind.
- [x] Cooldown so it can't be held down as a torch.
- [x] Spent scans are discarded once fully faded.
- [x] `tests/smoke_lidar.gd` passes headless (11 checks, non-hosted).

## Out of scope

- Making the scan itself audible to enemies (currently free/quiet).
- Adjustable cone width or range.

## Verification notes (2026-08-07)

- Sweep is progressive: 0 points lit immediately after firing, 58 once
  it had crossed the room.
- Directional: **91 marks on the wall ahead, 0 behind**.
- Holds: still 116 points lit two seconds after the sweep passed, then
  faded to 0 and the pulse was discarded.
- Implementation note: normal echo pulses light a surface only as the
  wavefront passes; the lidar needed a separate brightness curve
  (dark → arrival → HOLD → fade), which is what makes it read as a
  scan rather than a ripple.
