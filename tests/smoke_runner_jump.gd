extends SceneTree
## Regression test for STO-CHARACTER-036: the Runner must ALWAYS be
## able to jump. Before the fix, the 15 s pounce cooldown left it
## unable to jump at all — the charge branch was skipped and the
## ordinary ground jump was suppressed for pounce characters.
##   godot --headless -s res://tests/smoke_runner_jump.gd
## Verifies:
##   - tapping Space with the pounce READY still jumps
##   - with the pounce ON COOLDOWN, Space jumps INSTANTLY (same tick)
##   - that jump does not start a pounce or a crouch
##   - the cooldown keeps ticking (jumping doesn't reset it)

const SETTLE := 40

var _failures := 0
var _phase := "setup"
var _ticks := 0
var _player: CharacterBody3D
var _cam: Camera3D
var _cam_rest := 0.0
var _cd_before := 0.0
var _ground_y := 0.0
var _peak_y := 0.0


func _physics_process(_delta: float) -> bool:
	_ticks += 1
	match _phase:
		"setup":
			var ground := StaticBody3D.new()
			var cs := CollisionShape3D.new()
			var bs := BoxShape3D.new()
			bs.size = Vector3(80, 1, 80)
			cs.shape = bs
			ground.add_child(cs)
			ground.position = Vector3(0, -0.5, 0)
			root.add_child(ground)
			var db: GDScript = load("res://scripts/characters.gd")
			db.selected_index = 1  # Runner
			_player = load("res://scenes/player.tscn").instantiate()
			_player.name = "1"
			root.add_child(_player)
			_cam = _player.get_node("Camera3D")
			_next("ready_tap")
		"ready_tap":
			if _ticks < SETTLE:
				return false
			_cam_rest = _cam.position.y
			_ground_y = _player.global_position.y
			_check(_player.pounce_cooldown() == 0.0, "pounce is ready")
			# A realistic tap: held a few ticks (~80 ms), well under the
			# 0.18 s minimum charge, then released.
			Input.action_press("jump")
			_next("ready_tap_hold")
		"ready_tap_hold":
			if _ticks < 5:
				return false
			Input.action_release("jump")
			_peak_y = _player.global_position.y
			_next("ready_tap_check")
		"ready_tap_check":
			_peak_y = maxf(_peak_y, _player.global_position.y)
			if _ticks < 25:
				return false
			_check(_peak_y > _ground_y + 0.3,
					"tapping Space with pounce READY still jumps (rose %.2f m)"
					% (_peak_y - _ground_y))
			_next("land_then_cooldown")
		"land_then_cooldown":
			if not _player.is_on_floor():
				if _ticks > 300:
					_fail("never landed")
					return _finish()
				return false
			if _ticks < 10:
				return false
			# Put the pounce on cooldown WITHOUT pouncing, then jump.
			_player.set("_pounce_cd", 12.0)
			_cd_before = _player.pounce_cooldown()
			_ground_y = _player.global_position.y
			_peak_y = _ground_y
			Input.action_press("jump")   # HELD — must not wait for release
			_next("cooldown_jump")
		"cooldown_jump":
			_peak_y = maxf(_peak_y, _player.global_position.y)
			if _ticks == 4:
				# Within a few ticks of the PRESS (still held), the
				# Runner must already be leaving the ground.
				_check(_peak_y > _ground_y + 0.05,
						"Space jumps while HELD on cooldown, without waiting for release (rose %.3f m)"
						% (_peak_y - _ground_y))
				_check(is_equal_approx(_cam.position.y, _cam_rest),
						"no crouch while on cooldown (cam %.2f)" % _cam.position.y)
				_check(not _player.is_pouncing(),
						"cooldown jump is not a pounce")
			if _ticks >= 20:
				_check(_peak_y > _ground_y + 0.3,
						"cooldown jump reaches normal jump height (%.2f m)"
						% (_peak_y - _ground_y))
				Input.action_release("jump")
				_check(_player.pounce_cooldown() < _cd_before,
						"cooldown keeps ticking down (%.1f -> %.1f s)"
						% [_cd_before, _player.pounce_cooldown()])
				_check(_player.pounce_cooldown() > 5.0,
						"jumping did not clear the cooldown (%.1f s)"
						% _player.pounce_cooldown())
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
