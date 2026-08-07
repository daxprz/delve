---
xid: STO-CHARACTER-049
parent: ./epic.md
kind: story
effort: character
size: S
status: shipped
date: 2026-08-07
depends-on: []
bd-id: delve-j4y
shipped: 2026-08-07
tasks: 5
complete: 5
---

# Enemies show up red on the lidar

## Summary

Creatures come back **red** on a lidar scan, while the room stays cold
blue. Red contacts are also drawn much larger, because only a couple
of rays land on a distant body — a normal-sized mark would be an
almost invisible speck.

This refines, rather than breaks, the operator's original rule.
**Passive hearing still never reveals a creature**: a footstep echo
outlines only the room, exactly as before. The lidar is different
because it is *aimed* — a deliberate, cooldown-limited sweep of one
direction. So the Sniper now has a reason to scan before shooting:
hearing tells you something is out there, the lidar tells you where it
actually is.

## Definition of Done

- [x] Lidar scans paint creatures red; the room stays blue.
- [x] Red marks land on the creature, not near it.
- [x] Red contacts are drawn large enough to spot at a distance.
- [x] Passive footstep echoes still never reveal a creature.
- [x] `tests/smoke_lidar.gd` covers all of the above (13 checks).

## Out of scope

- Telling enemies apart from each other, or from another player.
- Contacts persisting after the scan fades (a scan is a snapshot).

## Verification notes (2026-08-07)

- A scan with an enemy 12 m ahead: 2 red marks, both ON the target,
  alongside 127 blue room marks. Red marks render at 4x size so two
  hits still read clearly.
- Confirmed in the same test that `emit_pulse` (a footstep) still
  produces **zero** creature marks — the passive rule is intact.
- Test lesson: a body added to the tree is not in the physics space
  until the next tick, so a same-tick raycast sails straight through
  it. The first version of this check spawned and scanned together and
  reported no contacts.
