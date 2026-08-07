extends SceneTree
## Headless smoke test for STO-TOOLS-003 (F3 overlay panel + gizmos).
##   godot --headless -s res://tests/smoke_debug_panel.gd
## Verifies:
##   - the DebugPanel autoload exists, hidden by default
##   - F3 (injected key event) toggles it open and closed
##   - the panel has a row per registered aspect
##   - toggling a row's checkboxes updates the human observer
##   - draw_line3/draw_point3 queue gizmos only when the aspect is
##     visually enabled AND the master gate is on; the gizmo mesh
##     gains line surfaces on the next frame
## Exits 0 on PASS, 1 on FAIL.

var _failures := 0
var _phase := "setup"
var _ticks := 0
var _panel: CanvasLayer
var _dbg: Node


func _physics_process(_delta: float) -> bool:
	_ticks += 1
	match _phase:
		"setup":
			_panel = root.get_node("/root/DebugPanel")
			_dbg = root.get_node("/root/DebugOverlay")
			_check(_panel != null, "DebugPanel autoload exists")
			_check(not _panel.visible, "panel hidden by default")
			_press_f3()
			_phase = "opened"
		"opened":
			_check(_panel.visible, "F3 opens the panel")
			var rows: Dictionary = _panel.get("_rows")
			_check(rows.size() == _dbg.get_aspect_paths().size(),
					"one row per aspect (%d)" % rows.size())
			# Toggle enemy/hits: vis + log via the actual checkboxes.
			var row: Array = rows["enemy/hits"]
			(row[0] as CheckBox).button_pressed = true
			(row[1] as CheckBox).button_pressed = true
			var state: Array = _dbg.get_observer_state("enemy/hits", "human")
			_check(state[0] == true and state[1] == _dbg.TextMode.LOG,
					"checkboxes drive the human observer")
			_press_f3()
			_phase = "closed"
		"closed":
			_check(not _panel.visible, "F3 closes the panel")
			# Gizmo gating: aspect on, master gate OFF -> nothing draws.
			_dbg.global_enabled = false
			_dbg.draw_line3("enemy/hits", null,
					Vector3.ZERO, Vector3.ONE, Color.RED, 1.0)
			_check((_dbg.get("_draw_items") as Array).is_empty(),
					"gizmos rejected while master gate is off")
			_dbg.global_enabled = true
			_dbg.draw_line3("enemy/hits", null,
					Vector3.ZERO, Vector3.ONE, Color.RED, 1.0)
			_dbg.draw_point3("enemy/hits", null, Vector3.ONE, 0.2, Color.RED, 1.0)
			_check((_dbg.get("_draw_items") as Array).size() == 4,
					"line + point queue 4 gizmo segments")
			_dbg.draw_line3("player/tail", null,
					Vector3.ZERO, Vector3.ONE, Color.RED, 1.0)
			_check((_dbg.get("_draw_items") as Array).size() == 4,
					"disabled aspect draws nothing")
			_phase = "rendered"
		"rendered":
			if _ticks < 20:
				return false  # give _process a frame to rebuild the mesh
			var mesh: ImmediateMesh = _dbg.get("_draw_mesh")
			_check(mesh.get_surface_count() == 1,
					"gizmo mesh rebuilt with a line surface")
			_dbg.global_enabled = false
			_dbg.set_observer("enemy/hits", "human", false, _dbg.TextMode.NONE)
			print("RESULT: %s" % ("PASS" if _failures == 0 else "FAIL (%d)" % _failures))
			quit(1 if _failures > 0 else 0)
			return true
	return false


func _press_f3() -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = KEY_F3
	ev.pressed = true
	Input.parse_input_event(ev)
	Input.flush_buffered_events()  # deliver now, not at end of frame


func _check(ok: bool, label: String) -> void:
	if ok:
		print("PASS: %s" % label)
	else:
		_failures += 1
		print("FAIL: %s" % label)
