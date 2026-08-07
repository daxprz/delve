extends SceneTree
## Smoke test for STO-CHARACTER-040 (Sniper echo-sight).
##   godot --headless -s res://tests/smoke_sniper_echo.gd
## Verifies the operator's design:
##   - the Sniper's camera does not render the world (blind)
##   - a still world produces NO echo marks
##   - a moving thing emits pulses that mark the WALLS around it
##   - the mover itself is never marked (only the room)
##   - marks fade out over time
##   - marks are FAINTER further from the Sniper
##   - other characters are unaffected (normal sight, no echo node)

var _failures := 0
var _phase := "setup"
var _ticks := 0
var _sniper: CharacterBody3D
var _echo: Node3D
var _mover: CharacterBody3D
var _still_marks := 0
var _peak_marks := 0
var _fronts_seen: Array = []


func _physics_process(_d: float) -> bool:
	_ticks += 1
	match _phase:
		"setup":
			# A room: floor plus a wall close to where the mover runs.
			_sb(Vector3(0, -0.5, 0), Vector3(60, 1, 60))
			_sb(Vector3(6, 2, 0), Vector3(0.3, 4, 20))     # near wall
			_sb(Vector3(-30, 2, 0), Vector3(0.3, 4, 20))   # far wall
			var db: GDScript = load("res://scripts/characters.gd")
			db.selected_index = _index_of(db, "sniper")
			_sniper = load("res://scenes/player.tscn").instantiate()
			_sniper.name = "1"
			root.add_child(_sniper)
			_sniper.global_position = Vector3(0, 1, 0)
			_phase = "blind_check"
		"blind_check":
			if _ticks < 20:
				return false
			var cam: Camera3D = _sniper.get_node("Camera3D")
			_check(cam.cull_mask == 2,
					"Sniper's camera renders ONLY the echo layer (mask=%d)"
					% cam.cull_mask)
			_echo = _sniper.get_node_or_null("EchoVision")
			_check(_echo != null, "Sniper has echo-sight")
			if _echo == null:
				return _finish()
			_phase = "silence"
		"silence":
			# Nothing moving (the Sniper stands still): no marks.
			if _ticks < 140:
				return false
			_still_marks = int(_echo.call("mark_count"))
			_check(_still_marks == 0,
					"a still world stays dark (%d marks)" % _still_marks)
			# Now add something that moves, near the near wall.
			var es: GDScript = load("res://scripts/enemy.gd")
			_mover = es.new()
			_mover.name = "Mover"
			_mover.position = Vector3(4.5, 1.0, 0.0)
			root.add_child(_mover)
			_ticks = 0   # phases are tick-budgeted; restart the clock
			_phase = "moving"
		"moving":
			# Drive it back and forth so it is definitely moving.
			if is_instance_valid(_mover):
				_mover.velocity.z = 6.0 if (_ticks / 30) % 2 == 0 else -6.0
				_mover.move_and_slide()
			_peak_marks = maxi(_peak_marks, int(_echo.call("mark_count")))
			if _ticks < 90:
				return false
			_check(_peak_marks > 0,
					"movement paints the room with echo marks (%d)" % _peak_marks)
			_check(int(_echo.call("pulse_count")) > 0,
					"pulses were emitted (%d)" % int(_echo.call("pulse_count")))
			# The mover's BODY must never be outlined — only the room.
			# (The floor directly under it SHOULD be marked; that is
			# room geometry, so only count marks up at body height.)
			var on_body := 0
			var on_floor_below := 0
			for m in _echo.call("all_marks"):
				var p: Vector3 = m["pos"]
				var horiz := Vector2(p.x - _mover.global_position.x,
						p.z - _mover.global_position.z).length()
				if horiz > 0.5:
					continue
				if p.y > _mover.global_position.y + 0.35:
					on_body += 1     # up on the creature itself
				else:
					on_floor_below += 1
			_check(on_body == 0,
					"the mover's body is never outlined (%d marks on it)" % on_body)
			_check(on_floor_below > 0,
					"the floor under a mover IS outlined (%d marks)" % on_floor_below)
			# Distance fade: near wall marks brighter than far wall.
			var near_a: float = _echo.call("alpha_at", Vector3(6, 1, 0))
			var far_a: float = _echo.call("alpha_at", Vector3(-30, 1, 0))
			var gone_a: float = _echo.call("alpha_at", Vector3(-45, 1, 0))
			_check(near_a > far_a,
					"echoes are fainter further away (near %.2f vs far %.2f)"
					% [near_a, far_a])
			_check(gone_a <= 0.001,
					"echoes beyond hearing range are invisible (%.2f)" % gone_a)

			# --- The echo travels as a WAVE (STO-CHARACTER-041) ---
			# A surface is dark before the front arrives, brightest as
			# it passes, and dimmer behind it.
			var before: float = _echo.call("brightness_for", 8.0, 2.0)
			var at_front: float = _echo.call("brightness_for", 8.0, 8.0)
			var behind: float = _echo.call("brightness_for", 8.0, 12.0)
			_check(before <= 0.01,
					"a surface is dark before the wave reaches it (%.2f)" % before)
			_check(at_front > behind and behind >= 0.0,
					"brightest at the wavefront, dimmer behind (%.2f -> %.2f)"
					% [at_front, behind])
			# The wave weakens as it spreads out.
			var near_front: float = _echo.call("brightness_for", 2.0, 2.0, 10.0)
			var far_front: float = _echo.call("brightness_for", 9.0, 9.0, 10.0)
			_check(near_front > far_front,
					"the wave gets dimmer as it expands (%.2f -> %.2f)"
					% [near_front, far_front])
			# Fronts actually advance over time.
			_fronts_seen = _echo.call("wave_fronts")
			if is_instance_valid(_mover):
				_mover.queue_free()
			_ticks = 0
			_phase = "fade"
		"fade":
			# With the mover gone, the sketch must fade back to black.
			if _ticks < 150:
				return false
			_check(int(_echo.call("mark_count")) == 0,
					"waves fade away when everything goes quiet (%d left)"
					% int(_echo.call("mark_count")))
			_check(int(_echo.call("live_wave_count")) == 0,
					"no live wavefronts remain")
			_check(not _fronts_seen.is_empty(),
					"wavefronts were tracked while moving (%d)"
					% _fronts_seen.size())
			_phase = "others"
		"others":
			# A non-blind character sees normally and has no echo node.
			var db: GDScript = load("res://scripts/characters.gd")
			db.selected_index = _index_of(db, "runner")
			var runner: CharacterBody3D = load("res://scenes/player.tscn").instantiate()
			runner.name = "1"
			root.add_child(runner)
			runner.global_position = Vector3(10, 1, 0)
			var rcam: Camera3D = runner.get_node("Camera3D")
			_check(rcam.cull_mask != 2, "other characters still see the world")
			_check(runner.get_node_or_null("EchoVision") == null,
					"other characters have no echo-sight")
			return _finish()
	return false


func _index_of(db: GDScript, id: String) -> int:
	for i in db.count():
		if db.get_def(i)["id"] == id:
			return i
	return 0


func _sb(pos: Vector3, size: Vector3) -> void:
	var b := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	b.add_child(cs)
	b.position = pos
	root.add_child(b)


func _finish() -> bool:
	print("RESULT: %s" % ("PASS" if _failures == 0 else "FAIL (%d)" % _failures))
	quit(1 if _failures > 0 else 0)
	return true


func _check(ok: bool, label: String) -> void:
	if ok:
		print("PASS: %s" % label)
	else:
		_failures += 1
		print("FAIL: %s" % label)
