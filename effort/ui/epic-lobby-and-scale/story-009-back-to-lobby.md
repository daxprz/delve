---
xid: STO-UI-009
parent: ./epic.md
kind: story
effort: ui
size: M
status: draft
date: 2026-08-15
depends-on: []
bd-id: delve-74cp
---

# Drop back to the lobby without leaving the game

## Summary

> "drop back to the lobby while in-game" — operator, 2026-08-15

A **Lobby** button in the pause menu. It takes you back to the
gathering screen — where you can see who else is here and change
character — without leaving the game or disconnecting.

## Why it is not the same as "Main Menu"

Main Menu already exists, and it **tears the session down**. That is
the right thing when you are finished, and the wrong thing when you
just want to regroup: leaving means the host loses you, and if you ARE
the host, everyone loses everything.

The lobby is the middle step delve does not have: still connected,
still together, not playing yet.

## The question this raises

If the host drops to the lobby, what happens to everyone else? Two
honest answers:

- **Everyone goes with them.** The lobby is a shared place; the host
  saying "back to the lobby" ends the round for the group.
- **Only that player goes.** They sit in the lobby while others play
  on, and rejoin when ready.

The second is more useful and much harder, because the game has to run
with a player who is present but not in it. **Decide before building**,
and write down which and why.

## Definition of Done

- [ ] A Lobby button in the pause menu, distinct from Main Menu.
- [ ] It returns you to the lobby WITHOUT disconnecting.
- [ ] You can change character there and start again.
- [ ] Main Menu still fully disconnects, as it does now.
- [ ] What happens to everyone else when the HOST does it is decided
      and written down.
- [ ] Proven by a headless test that checks the connection survives.

## Out of scope

- Redesigning the lobby.
- Spectating the game from the lobby.
