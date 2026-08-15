---
xid: STO-UI-010
parent: ./epic.md
kind: story
effort: ui
size: L
status: draft
date: 2026-08-15
depends-on: []
bd-id: delve-p6k9
---

# Rejoin a running server without disturbing the host

## Summary

> "reconnect to a running server instance without affecting the host"
> — operator, 2026-08-15

Someone crashes, closes the game, or loses their connection — and can
**come back into the running game**, with the host never noticing
anything more than a player leaving and returning.

## Why this is the hardest of the three, and the most valuable

The other two are buttons. This one is about what the SERVER believes.

Delve spawns players by peer id and spreads them round a spawn ring
(STO-CORE-004, STO-CORE-007). A returning player is a **new peer id**
as far as the network is concerned, so without care they arrive as a
stranger: new slot, new character, no history. Meanwhile whatever the
old peer left behind — a player node, a spike victim, an arm holding a
crate — may still be sitting in the world.

"Without affecting the host" is the whole specification. The host must
not stutter, must not need restarting, and must not end up with ghosts.

## What has to be true

| | |
|---|---|
| **The host survives** | a peer leaving and returning changes nothing for anyone else |
| **No ghosts** | whatever the lost peer left is cleaned up |
| **They come back as themselves** | same name, same character — not a stranger in slot 4 |
| **It works mid-round** | not only between games |

## The hard part, named

Godot's multiplayer gives a returning player a **new peer id**, so
"same person" has to be decided by something else. The obvious key is
the player NAME, which delve already has and already remembers across
restarts (STO-UI-006). That is probably the answer, and it has an
obvious flaw worth stating now: two people called "dax" would collide.

## Definition of Done

- [ ] A client that disconnects can rejoin the same running server.
- [ ] The host is unaffected — no restart, no stutter, other players
      keep playing.
- [ ] Nothing is left behind by the peer that vanished.
- [ ] The returning player keeps their name and character.
- [ ] It works while a round is in progress.
- [ ] How "the same person" is recognised is decided and written down,
      including what happens when two players share a name.
- [ ] Proven by a headless test that connects, drops, rejoins, and
      checks the host and the other players never noticed.

## Out of scope

- Saving the round so you rejoin exactly where you were standing.
- Reconnecting automatically. A button is enough.
- Handling the HOST disconnecting. That is a different, larger
  problem.
