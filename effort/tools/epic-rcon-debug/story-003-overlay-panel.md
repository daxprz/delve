---
xid: STO-TOOLS-003
parent: ./epic.md
kind: story
effort: tools
size: L
status: shipped
date: 2026-08-06
depends-on: []
bd-id: delve-5pt
shipped: 2026-08-06
tasks: 5
complete: 5
---

# In-game debug overlay: F3 panel + 3D gizmo drawing

## Summary

The in-game half of the debug overlay (STO-TOOLS-003). `DebugPanel`
autoload: **F3** toggles a right-side panel with the master VISUAL
gate, per-aspect vis/log checkboxes (human observer, persisted to the
debug profile on close) and a live tail of recent DBG lines
(`DebugOverlay.log_history` ring buffer). Opening frees the mouse;
closing saves and re-captures if a local player is in play.
`DebugOverlay` gains the 3D gizmo channel: `draw_line3`/`draw_point3`
queue TTL'd colored lines (gated by `should_draw`), rendered through
one unshaded, depth-test-free ImmediateMesh rebuilt per frame. First
gizmos wired: tail weapon-speed segments + swipe velocity
(orange=damage, red=trip) and enemy hit-reaction arrows
(yellow=shove, orange=stumble, red=ragdoll) + downed pelvis marker.

## Definition of Done

- [x] F3 opens/closes the panel in-game; mouse freed while open,
      re-captured on close; settings persist via the debug profile.
- [x] Panel shows every registered aspect with working vis/log
      checkboxes and a live DBG-line tail.
- [x] Gizmo channel: draws only when the aspect is visually enabled
      AND the master gate is on; TTL'd items expire.
- [x] First gizmos: player/tail and enemy/hits.
- [x] `tests/smoke_debug_panel.gd` passes headless (10 checks,
      including injected F3 key events).

## Out of scope

- Entity type/id filtering UI (registry supports observers; filter UI
  when the enemy roster grows).
- Gizmo text labels / 2D overlay text (line primitives only for now).

## Verification notes (2026-08-06)

- smoke_debug_panel 10/10. Gotcha: `Input.parse_input_event` buffers
  until end-of-frame — tests must call `Input.flush_buffered_events()`
  for same-tick delivery.
- Non-hosted regressions PASS (overlay, reactions, body, world).
- Rendered boot clean; RCON port fallback observed live (operator's
  session on 9999, test instance took 10000).
