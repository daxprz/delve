---
xid: STO-UI-009
parent: ./epic.md
kind: story
effort: ui
size: M
status: done
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

- [x] A **Back to Lobby** button in the pause menu, above Main Menu and
      distinct from it.
- [x] It returns you to the lobby without disconnecting — measured, the
      multiplayer peer is **still there** afterwards.
- [x] The round ends and the mouse comes back.
- [x] Bodies are cleared, so starting again does not spawn a second one
      for everybody. Measured: **0 left**.
- [x] Main Menu still fully disconnects.
- [x] Decided and written down — see below.
- [x] Proven by `tests/smoke_pause_lobby.gd`.

## DECIDED (2026-08-16): who goes back

- A **client** pressing it goes back **alone**. The others play on.
- The **host** pressing it takes **everyone**. The host starts a round,
  so the host can end it.

The alternative — the host sitting in the lobby while the others carry
on — was rejected **for now**, not on principle. It needs the game to
keep running with a player who is present but not in it, which is a far
bigger change than a button, and it is the same problem STO-UI-010 has
to solve anyway. Worth revisiting once that lands.

## Built (2026-08-16)

Placed **above** Main Menu deliberately: it is the gentler of the two
and the one wanted far more often, and a mis-click on the wrong one
costs the entire session.

## Out of scope

- Redesigning the lobby.
- Spectating the game from the lobby.
