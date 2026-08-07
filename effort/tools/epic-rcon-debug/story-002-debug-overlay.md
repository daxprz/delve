---
xid: STO-TOOLS-002
parent: ./epic.md
kind: story
effort: tools
size: M
status: shipped
date: 2026-08-06
depends-on: []
bd-id: delve-y2f
shipped: 2026-08-06
tasks: 4
complete: 4
---

# Debug overlay: aspect registry + RCON debug commands

## Summary

`scripts/autoload/debug_overlay.gd` (aspect registry, observer-based
filtering, `log`/`should_draw`/`vis` API, profile persistence) +
`scripts/autoload/debug_aspects.gd` (registers delve's aspect tree in
one place), wired into RCON: `debug list|on|off|log|vis|none|clear`.
First aspects emitted from live systems: `network/peers`,
`network/spawn`, `player/combat`, `player/abilities`, `enemy/ai`,
`enemy/combat`, `perf/fps`.

## Definition of Done

- [x] `debug list` over RCON shows the registered tree with per-aspect
      state and observers.
- [x] `debug log network/peers` then a client join prints gated
      lines to stdout; `debug none …` silences them.
- [x] Observer model works: test observers and the human observer are
      independent; `debug clear` removes transient observers only.
- [x] `tests/smoke_debug_overlay.gd` passes headless (register /
      observe / log-gating / union semantics).

## Verification notes (2026-08-06)

- `tests/smoke_debug_overlay.gd`: 11/11 PASS (registration, gating,
  observer union, transient clear, auto-register, visual global gate).
- Live end-to-end: `rcon.sh debug log enemy/ai` + `spawn enemy` →
  game log printed `DBG enemy/ai: RconEnemy4: target (none) -> 1`;
  `eval …deal_damage(…)` → `DBG enemy/combat: Enemy0: -10 hp -> 50`.
- First aspects wired: network/peers (network.gd), network/spawn
  (main.gd), player/combat + player/abilities (player.gd:
  take_damage/deal_damage/zip/grab/dodge), enemy/ai on target change
  + enemy/combat (enemy.gd), perf/fps (rcon.gd, 1 line/s).
- Regressions: smoke_player/enemy/combo/health + MP test all PASS.

## Out of scope

- In-game console output target (delve has no console yet).
- Visual (3D gizmo) drawing helpers — aspects gate them, but gizmo
  primitives arrive with the features that need them.
