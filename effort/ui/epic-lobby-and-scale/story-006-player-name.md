---
xid: STO-UI-006
parent: ./epic.md
kind: story
effort: ui
size: S
status: shipped
date: 2026-08-07
depends-on: []
bd-id: delve-boj
shipped: 2026-08-07
tasks: 9
complete: 9
---

# Player name, set once and remembered

## Summary

Each player can type a name for themselves, and the game remembers it
forever — you type it once, and every game after that already knows
who you are.

Right now the lobby calls everyone "Host" or "Player 1477304918",
which tells you nothing about who is actually there. With names, the
lobby reads "Dax — Runner" and "Sam — Sniper", so you can see your
friends before the game starts.

The name is a **setting**, not a lobby field: it lives in the same
`Settings` autoload that already keeps the UI scale in
`user://settings.json`, so it survives a restart the same way the UI
scale does. The name box appears in the main menu and in the lobby, so
you can fix a typo without leaving the game.

Names have to travel over the network, exactly the way character
choices already do: the host keeps a peer-id → name map beside
`_lobby_chars` and broadcasts it, so *everyone* sees the same names,
not just themselves.

## Definition of Done

- [x] There is a name box in the main menu you can type into.
- [x] The same name box is in the lobby, so you can change it there.
- [x] The name is saved to `user://settings.json` and is still there
      after the game is closed and reopened.
- [x] The lobby list shows each player's name instead of "Player
      1477304918" — for **all** peers, not just yourself.
- [x] Changing your name in the lobby updates it on the other player's
      screen too.
- [x] A player who never sets a name still gets something readable
      ("Host", "Player 2"), never a blank row.
- [x] Silly input is handled instead of breaking the UI: empty names,
      very long names, and leading/trailing spaces are cleaned up or
      clamped.
- [x] `tests/smoke_player_name.gd` passes (19 checks) — including the
      honest persistence check used by STO-UI-003: set a name, wipe
      the in-memory value, reload from disk.
- [x] A two-instance run (`scripts/run_mp_test.sh name`) proves host
      and client each see the *other's* name.

## Out of scope

- Names floating above players' heads in the 3D world.
- Names being unique, reserved, or checked against anyone else's.
- A chat box, or any other use of the name beyond the lobby list.
- Filtering rude names.

## Verification notes (2026-08-07)

- Persistence proven the honest way, as in STO-UI-003: write it, wipe
  the in-memory value, reload from disk — the same path a fresh launch
  takes. Confirmed the test has teeth by removing `player_name` from
  the save file: 4 checks failed, including the lobby ones.
- The multiplayer half needed a second test pair
  (`tests/smoke_name_{host,client}.gd`, run with
  `scripts/run_mp_test.sh name`). A single instance cannot tell a
  working name box from one that only updates your own screen — the
  solo test passes either way. Host is "HostHilda", client is
  "ClientClara", and each side asserts it can see the *other*.
- The client also checks its **own** name comes back inside the host's
  broadcast, which is what proves the host is distributing one shared
  list rather than each machine knowing only itself.
- A rename mid-lobby is checked live: the host renames itself and the
  client must observe the change without reconnecting.

### Two things this turned up

- **An RPC was being fired before the connection existed.** `join_game`
  announced the character immediately, which printed *"Trying to call
  an RPC via a multiplayer peer which is not connected"* and threw the
  message away. It happened to work because the value was re-sent
  later. Announcing from `connected_to_server` instead is both correct
  and quieter.
- **The existing two-instance test was measuring from the wrong
  place** — it read its starting position the instant the player node
  appeared, before any position had arrived, so it measured from
  (0,0,0). This story's connect-time traffic shifted the timing enough
  to expose it. Fixing the test then revealed a genuine pre-existing
  bug, written up separately as **STO-CORE-007**; it is not caused by
  this story (untouched `main` reproduces it at the same rate).
