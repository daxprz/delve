extends SceneTree
## Smoke test for STO-CHARACTER-032 (Runner pounce). Non-hosted so it
## runs while a game is open. Verifies:
##   - only the Runner has pounce
##   - a TAP of Space is still an ordinary jump (no forward launch)
##   - HOLDING Space crouches (camera dips) and holds you still
##   - releasing a full charge launches you forward much farther than
##     a plain jump, and higher
##   godot --headless -s res://tests/smoke_pounce.gd

const CHARGE_TICKS := 60   # 1 s hold = full charge (max 0.9 s)

var _failures := 0
var _phase := "setup"
var _ticks := 0
var _player: CharacterBody3D
var _cam: Camera3D
var _cam_rest := 0.0
var _start_z := 0.0
var _tap_dist := 0.0


func _physics_process(_delta: float) -> bool:
	_ticks += 1
	match _phase:
		"setup":
			var ground := StaticBody3D.new()
			var cs := CollisionShape3D.new()
			var bs := BoxShape3D.new()
			bs.size = Vector3(200, 1, 200)
			cs.shape = bs
			ground.add_child(cs)
			ground.position = Vector3(0, -0.5, 0)
			root.add_child(ground)

			var db: GDScript = load("res://scripts/characters.gd")
			_check(db.get_def(1).get("pounce", false) == true,
					"Runner has pounce")
			_check(db.get_def(0).get("pounce", false) == false,
					"Grabber does not have pounce")
			db.selected_index = 1  # Runner

			_player = load("res://scenes/player.tscn").instantiate()
			_player.name = "1"
			root.add_child(_player)
			_cam = _player.get_node("Camera3D")
			_next("land")
		"land":
			if _ticks < 40:
				return false
			_cam_rest = _cam.position.y
			_start_z = _player.global_position.z
			# TAP: press and release within one tick.
			Input.action_press("jump")
			Input.action_release("jump")
			_next("tap_flight")
		"tap_flight":
			if _player.is_on_floor() and _ticks > 5:
				_tap_dist = absf(_player.global_position.z - _start_z)
				_check(_tap_dist < 1.0,
						"a TAP is a plain jump, no launch (%.2f m)" % _tap_dist)
				_start_z = _player.global_position.z
				Input.action_press("jump")   # now HOLD
				_next("charging")
			elif _ticks > 300:
				_fail("player never landed after the tap")
				return _finish()
		"charging":
			if _ticks == 30:
				_check(_cam.position.y < _cam_rest - 0.05,
						"holding Space crouches (cam %.2f -> %.2f)"
						% [_cam_rest, _cam.position.y])
				_check(absf(_player.velocity.z) < 0.5,
						"charging holds you still (vz=%.2f)" % _player.velocity.z)
			if _ticks >= CHARGE_TICKS:
				Input.action_release("jump")  # LAUNCH
				_next("pouncing")
		"pouncing":
			if _ticks == 2:
				_check(_player.velocity.length() > 5.0,
						"release launches at speed (%.1f m/s)"
						% _player.velocity.length())
				_check(_cam.position.y > _cam_rest - 0.05,
						"crouch released on launch")
			if _player.is_on_floor() and _ticks > 10:
				var dist := absf(_player.global_position.z - _start_z)
				_check(dist > _tap_dist + 3.0,
						"pounce travels much farther than a jump (%.1f m vs %.1f m)"
						% [dist, _tap_dist])
				return _finish()
			elif _ticks > 400:
				_fail("player never landed after the pounce")
				return _finish()
	return false


func _next(phase: String) -> void:
	_phase = phase
	_ticks = 0


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


func _fail(msg: String) -> void:
	_failures += 1
	print("FAIL: %s" % msg)
