---
name: godot-headless-testing
description: Hard-won gotchas for headless Godot 4.6 testing on this Wayland machine (physics-tick timing, mouse capture, exit codes)
metadata:
  type: project
---

Godot 4.6 headless-testing gotchas on this machine (Wayland, RTX 4080, `/usr/local/bin/godot`).

**Why:** Each of these cost a debugging round during STO-CORE-002 bring-up; they are environment behaviors, not derivable from project code.

**How to apply:** when writing/debugging any `godot --headless -s` SceneTree test or interpreting rendered-run logs.

1. **Time test phases on physics ticks, not `_process` frames.** Headless `_process` runs much faster than the fixed 60 Hz physics tick — 60 process frames ≠ 1 simulated second. Use `_physics_process(delta)` on the SceneTree script for phase timing (symptom: movement distances/jump arcs come out short).
2. **Never capture the mouse in `_ready()`.** Wayland errors with `Parameter "pointed_win" is null` until the pointer is over the window. Capture lazily on the first mouse event; Esc releases, click recaptures (pattern in `scripts/player.gd`).
3. **`cmd | tail` eats the exit code.** SceneTree `quit(1)` works, but check `$?` on the godot command itself (redirect to a log file, then read it), not after a pipe.
4. **Ignorable exit noise:** `ObjectDB instances leaked` for `DisplayServer`/`NativeMenu` is engine-internal Wayland teardown, not scene leaks. X11 → Wayland fallback warnings are normal (no X11 here).
5. **`Input.action_press()/action_release()` injection works headless** and drives `is_action_just_pressed` in player physics code — the basis of `tests/smoke_player.gd`.
6. **Under `godot -s`, autoloads join the tree only AFTER `_initialize()` returns** (and `_ready` of nodes added there hasn't fired yet). The main-loop script can't even reference autoload globals at compile time. Do ALL test setup on the first `_physics_process` tick, never in `_initialize` (symptoms: `multiplayer` is null in the autoload; @onready vars null).
7. **`get_tree().current_scene` is null under `godot -s`** — the test adds the scene as a plain root child. Runtime code that needs "the scene" must fall back (see `Rcon._scene_root()`: last child of root, since autoloads come first).
8. **Multi-line lambdas inside array/dict literals fail to parse** in GDScript 4.6 ("Expected closing ]"). Use data-driven check specs (dicts of needles) or named methods instead.
9. **RCON is live** (`scripts/autoload/rcon.gd`, port 9999, falls back to 10000+ for second instances): `scripts/rcon.sh [-p port] <cmd>` or `echo "cmd" | nc -w2 localhost 9999`. Debug aspect lines are grep-able as `DBG <group/sub>:` in the game log.
10. **Two-process multiplayer tests: the HOST must outlive the client.** If the server quits first, its teardown despawns all replicated nodes on the client mid-assertion (`previously freed` spam). Pattern: client finishes and quits; host treats `get_peers().is_empty()` as end-of-test. Guard cross-peer node refs with `is_instance_valid()`. See `scripts/run_mp_test.sh`.
