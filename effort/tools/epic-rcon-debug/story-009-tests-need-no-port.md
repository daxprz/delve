---
xid: STO-TOOLS-009
parent: ./epic.md
kind: story
effort: tools
size: S
status: draft
date: 2026-08-07
depends-on: []
bd-id: delve-xb3
---

# Tests can run while the game is open

## Summary

**25 of delve's 62 smoke tests cannot run while the operator has the
game open.** They call `main.host_game()`, which binds UDP 7777, and a
running game already holds it. They do not fail — they cannot start.

This bit for real during the v0.1.9 release: the operator was playing,
so `smoke_ragdoll`, `smoke_tail`, `smoke_punch`, `smoke_arms` and
`smoke_grab` were all skipped — and every one of them covers code that
release changed. The build shipped with a quarter of its tests
unverified.

Almost none of those tests actually need a network. They host purely
to make `main` spawn a player, and a player can be added directly:

```gdscript
var p := load("res://scenes/player.tscn").instantiate()
p.name = "1"
main.get_node("Players").add_child(p)
```

Three tests already do this (`smoke_enemy_attack`,
`smoke_enemy_corpse`, `smoke_grab_box`) and run happily alongside a
live game.

## Definition of Done

- [ ] Tests that do not need a network no longer host one.
- [ ] The full suite runs to completion with the game open, with zero
      skips.
- [ ] Tests that genuinely need two peers (`smoke_mp_*`,
      `smoke_name_*`) are clearly separated as the ones that need the
      port to themselves.
- [ ] The suite runner reports skips loudly rather than counting them
      as passes.

## Out of scope

- Making `Network.host()` itself fall back to another port. Tempting,
  but it would break real play: a friend joining 7777 would find
  nothing if the host quietly moved to 7778. The fallback belongs in
  the tests, not in the game.

## Notes

The current runner already distinguishes "skipped (port in use)" from
"failed", which is what made the gap visible instead of silently
reporting 33/33 and sounding complete. Worth keeping: a test that did
not run is not a test that passed.
