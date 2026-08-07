---
xid: STO-CHARACTER-040
parent: ./epic.md
kind: story
effort: character
size: L
status: shipped
date: 2026-08-07
depends-on: []
bd-id: delve-5cz
shipped: 2026-08-07
tasks: 6
complete: 6
---

# Sniper echo-sight: blind, but movement outlines the world

## Summary

The Sniper is **blind** — it cannot see the world the normal way. Its
screen is dark. Instead, **anything that moves emits an echo**, and
each echo briefly **outlines the map geometry around it**: walls,
floors, pillars, the maze. Enemies running, a thrown crate, another
player, a ragdoll tumbling — each pulse paints the world back in for a
moment, then it fades to black again.

Standing still and listening is the Sniper's way of "looking". A quiet
room is invisible; a busy one lights up.

The Sniper hears its OWN movement too, so it can always feel out the
room immediately around itself by moving.

## Definition of Done

- [x] For the Sniper (and only the Sniper), the world renders dark —
      normal lighting/colour does not reveal the map.
- [x] Moving things emit echo pulses; faster movement makes a
      stronger/further-reaching echo.
- [x] A pulse outlines the map surfaces it reaches, and the outline
      fades over a short time.
- [x] The Sniper's own movement produces echoes, so it can navigate
      alone.
- [x] Other players are unaffected — they see normally (this is
      per-player, and must not break multiplayer).
- [x] Headless test covers: echo emitted on movement, outline
      generated and expiring, no echo when everything is still.

## Out of scope

- Sound/audio (this is the VISUAL representation of hearing).
- Echo-sight for any other character.

> **PARTLY SUPERSEDED by STO-CHARACTER-051 (2026-08-07).** The
> "only the walls, never the creature" rule below was reversed after
> play: creatures are now marked directly, in their own colours
> (enemies red, other players green, the room blue). The original
> reasoning is kept here rather than rewritten, so the design history
> still reads honestly.

## Decisions (operator, 2026-08-07)

- **Only the walls around a mover are outlined — never the mover
  itself.** You learn that something is there and what the room looks
  like, but not what it is. Deliberately spookier and harder.
- **Echoes fade with distance from the Sniper.** Far-off movement is
  a faint hint; nearby movement paints a clear picture. So the Sniper
  must move closer to understand what is happening.

## Verification notes (2026-08-07)

- 12/12 PASS. The Sniper's camera cull mask is set to the echo layer
  only, so the world is genuinely never drawn for it — the darkness
  isn't a black overlay that could be seen through.
- A still world produced 0 marks; movement painted 183; everything
  faded back to 0 once the mover was removed.
- "Only the walls" verified precisely: 0 marks on the mover's BODY,
  while 25 landed on the floor beneath it (floor is room geometry and
  SHOULD be drawn — the first version of this check wrongly counted
  those as the mover).
- Distance fade: alpha 1.00 at the near wall, 0.15 at 30 m, 0.00
  beyond ~34 m.
- Other characters keep normal sight and get no echo node.
